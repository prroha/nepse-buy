import type { PrismaClient, TradeSide } from "@prisma/client";
import { db } from "../lib/db.js";
import { ApiError } from "../middleware/error.middleware.js";
import { ErrorCodes } from "../utils/response.js";
import { computeBuyFees, computeSellFees } from "../trades/fee-engine.js";
import { fifoMatch } from "../trades/fifo.js";
import type { BuyLot } from "../trades/types.js";
import { feeScheduleService } from "./fee-schedule.service.js";
import { positionService } from "./position.service.js";

export interface LogTradeInput {
  symbol?: string;
  stockId?: string;
  side: TradeSide;
  shares: number;
  grossPricePerShare: string;
  executedAt: Date;
  note?: string;
}

export interface TradeRow {
  id: string;
  side: TradeSide;
  shares: number;
  grossPricePerShare: string;
  executedAt: string;
  brokerCommission: string;
  sebonFee: string;
  dpFee: string;
  cgt: string | null;
  netPricePerShare: string;
  note: string | null;
}

class TradeService {
  constructor(private readonly prisma: PrismaClient = db) {}

  async logTrade(userId: string, input: LogTradeInput): Promise<{ tradeId: string; positionId: string }> {
    if (input.shares <= 0) {
      throw ApiError.badRequest("shares must be > 0", ErrorCodes.VALIDATION_ERROR);
    }

    // Resolve stock
    let stockId = input.stockId;
    if (!stockId) {
      if (!input.symbol) throw ApiError.badRequest("symbol or stockId required", ErrorCodes.VALIDATION_ERROR);
      const stock = await this.prisma.stock.findUnique({ where: { symbol: input.symbol.toUpperCase() } });
      if (!stock) throw ApiError.notFound(`Stock not found: ${input.symbol}`, ErrorCodes.NOT_FOUND);
      stockId = stock.id;
    }

    const schedule = await feeScheduleService.getOrSeed(userId);
    const grossPrice = Number(input.grossPricePerShare);

    // For SELL: pre-validate against outstanding lots so we don't end up with
    // half a transaction. Recompute is the source of truth on read paths.
    let cgt: number | null = null;
    let netPricePerShare: number;
    let brokerCommission: number;
    let sebonFee: number;
    let dpFee: number;

    return await this.prisma.$transaction(async (tx) => {
      const position = await tx.position.upsert({
        where: { userId_stockId: { userId, stockId: stockId! } },
        create: {
          userId,
          stockId: stockId!,
          totalShares: 0,
          avgNetCost: "0",
          realizedPnl: "0",
          isOpen: true,
        },
        update: {},
        select: { id: true },
      });

      if (input.side === "BUY") {
        const fees = computeBuyFees(input.shares, grossPrice, schedule);
        brokerCommission = fees.brokerCommission;
        sebonFee = fees.sebonFee;
        dpFee = fees.dpFee;
        netPricePerShare = fees.netPricePerShare;
      } else {
        // Build lots from existing BUY trades, then run FIFO with virtual decrement.
        const existing = await tx.trade.findMany({
          where: { positionId: position.id },
          orderBy: [{ executedAt: "asc" }, { createdAt: "asc" }],
        });
        const lots: BuyLot[] = [];
        for (const t of existing) {
          if (t.side === "BUY") {
            lots.push({
              tradeId: t.id,
              executedAt: t.executedAt,
              netPricePerShare: Number(t.netPricePerShare),
              remainingShares: t.shares,
            });
          } else {
            // Pre-consume prior sells from oldest lots so this sell sees the right inventory.
            let remaining = t.shares;
            for (const lot of lots) {
              if (remaining <= 0) break;
              const take = Math.min(lot.remainingShares, remaining);
              lot.remainingShares -= take;
              remaining -= take;
            }
            if (remaining > 0) {
              // Shouldn't happen if data is consistent; bail out conservatively.
              throw ApiError.conflict(
                `Position inventory inconsistent — prior sell ${t.id} short by ${remaining}`,
                ErrorCodes.CONFLICT,
              );
            }
          }
        }
        // Validate inventory before recording the new sell.
        const available = lots.reduce((acc, l) => acc + l.remainingShares, 0);
        if (available < input.shares) {
          throw ApiError.badRequest(
            `Insufficient shares to sell: holding ${available}, trying to sell ${input.shares}`,
            ErrorCodes.VALIDATION_ERROR,
          );
        }
        const matches = fifoMatch(lots, input.shares, grossPrice, input.executedAt, schedule.longTermDaysThreshold);
        const sellFees = computeSellFees(input.shares, grossPrice, matches, schedule);
        brokerCommission = sellFees.brokerCommission;
        sebonFee = sellFees.sebonFee;
        dpFee = sellFees.dpFee;
        cgt = sellFees.cgt;
        netPricePerShare = sellFees.netProceedsPerShare;
      }

      const trade = await tx.trade.create({
        data: {
          positionId: position.id,
          side: input.side,
          shares: input.shares,
          grossPricePerShare: input.grossPricePerShare,
          executedAt: input.executedAt,
          brokerCommission: brokerCommission.toFixed(2),
          sebonFee: sebonFee.toFixed(2),
          dpFee: dpFee.toFixed(2),
          cgt: cgt !== null ? cgt.toFixed(2) : null,
          netPricePerShare: netPricePerShare.toFixed(4),
          note: input.note ?? null,
        },
        select: { id: true },
      });

      // Recompute position aggregate to apply the new trade.
      // (Using the singleton positionService; it manages its own queries through `db`.)
      await positionService.recompute(position.id, userId);

      return { tradeId: trade.id, positionId: position.id };
    });
  }

  async list(userId: string, positionId: string): Promise<TradeRow[]> {
    const position = await this.prisma.position.findUnique({ where: { id: positionId } });
    if (!position || position.userId !== userId) {
      throw ApiError.notFound("Position not found", ErrorCodes.NOT_FOUND);
    }
    const trades = await this.prisma.trade.findMany({
      where: { positionId },
      orderBy: { executedAt: "desc" },
    });
    return trades.map(toRow);
  }

  async remove(userId: string, tradeId: string): Promise<void> {
    const trade = await this.prisma.trade.findUnique({
      where: { id: tradeId },
      include: { position: { select: { userId: true, id: true } } },
    });
    if (!trade || trade.position.userId !== userId) {
      throw ApiError.notFound("Trade not found", ErrorCodes.NOT_FOUND);
    }
    await this.prisma.$transaction(async (_tx) => {
      await this.prisma.trade.delete({ where: { id: tradeId } });
      await positionService.recompute(trade.position.id, userId);
    });
  }
}

function toRow(t: {
  id: string;
  side: TradeSide;
  shares: number;
  grossPricePerShare: { toString: () => string };
  executedAt: Date;
  brokerCommission: { toString: () => string };
  sebonFee: { toString: () => string };
  dpFee: { toString: () => string };
  cgt: { toString: () => string } | null;
  netPricePerShare: { toString: () => string };
  note: string | null;
}): TradeRow {
  return {
    id: t.id,
    side: t.side,
    shares: t.shares,
    grossPricePerShare: t.grossPricePerShare.toString(),
    executedAt: t.executedAt.toISOString(),
    brokerCommission: t.brokerCommission.toString(),
    sebonFee: t.sebonFee.toString(),
    dpFee: t.dpFee.toString(),
    cgt: t.cgt?.toString() ?? null,
    netPricePerShare: t.netPricePerShare.toString(),
    note: t.note,
  };
}

export const tradeService = new TradeService();
