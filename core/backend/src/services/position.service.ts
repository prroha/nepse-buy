import type { PrismaClient } from "@prisma/client";
import { db } from "../lib/db.js";
import { ApiError } from "../middleware/error.middleware.js";
import { ErrorCodes } from "../utils/response.js";
import { fifoMatch } from "../trades/fifo.js";
import { computeSellFees } from "../trades/fee-engine.js";
import type { BuyLot } from "../trades/types.js";
import { feeScheduleService } from "./fee-schedule.service.js";
import type { PositionContext } from "../signals/types.js";

export interface PositionRow {
  id: string;
  stockId: string;
  symbol: string;
  name: string;
  totalShares: number;
  avgNetCost: string;
  realizedPnl: string;
  isOpen: boolean;
  createdAt: string;
  updatedAt: string;
  latestClose: string | null;
  /** Paper P/L pct vs avgNetCost (decimal, e.g., "0.32"). Null when latestClose missing. */
  paperPlPct: string | null;
}

class PositionService {
  constructor(private readonly prisma: PrismaClient = db) {}

  async list(userId: string): Promise<PositionRow[]> {
    const positions = await this.prisma.position.findMany({
      where: { userId },
      orderBy: [{ isOpen: "desc" }, { updatedAt: "desc" }],
      include: {
        stock: {
          select: {
            symbol: true,
            name: true,
            priceObservations: {
              orderBy: [{ tradeDate: "desc" }, { fetchedAt: "desc" }],
              take: 1,
              select: { close: true },
            },
          },
        },
      },
    });
    return positions.map((p) => {
      const latestClose = p.stock.priceObservations[0]?.close ?? null;
      const avgCostNum = Number(p.avgNetCost);
      let paperPlPct: string | null = null;
      if (latestClose && avgCostNum > 0) {
        const pl = (Number(latestClose) - avgCostNum) / avgCostNum;
        paperPlPct = pl.toFixed(4);
      }
      return {
        id: p.id,
        stockId: p.stockId,
        symbol: p.stock.symbol,
        name: p.stock.name,
        totalShares: p.totalShares,
        avgNetCost: p.avgNetCost.toString(),
        realizedPnl: p.realizedPnl.toString(),
        isOpen: p.isOpen,
        createdAt: p.createdAt.toISOString(),
        updatedAt: p.updatedAt.toISOString(),
        latestClose: latestClose?.toString() ?? null,
        paperPlPct,
      };
    });
  }

  async remove(userId: string, positionId: string): Promise<void> {
    const p = await this.prisma.position.findUnique({ where: { id: positionId } });
    if (!p || p.userId !== userId) {
      throw ApiError.notFound("Position not found", ErrorCodes.NOT_FOUND);
    }
    await this.prisma.position.delete({ where: { id: positionId } });
  }

  /**
   * Engine helper — returns net-of-fees avg cost for HARVEST signal computation.
   */
  async getPositionContext(userId: string, stockId: string): Promise<PositionContext | null> {
    const p = await this.prisma.position.findUnique({
      where: { userId_stockId: { userId, stockId } },
      select: { totalShares: true, avgNetCost: true },
    });
    if (!p || p.totalShares <= 0) return null;
    return { totalShares: p.totalShares, avgCost: Number(p.avgNetCost) };
  }

  /**
   * Recompute totalShares + avgNetCost + realizedPnl from all trades, in
   * chronological order, using FIFO to match each SELL against outstanding
   * BUY lots. Also writes back any updated `cgt` and `netPricePerShare`
   * fields on SELL trades whose matches shifted (e.g., after a BUY edit).
   *
   * Called transactionally from trade.service after every create/delete.
   */
  async recompute(positionId: string, userId: string): Promise<void> {
    const schedule = await feeScheduleService.getOrSeed(userId);

    const position = await this.prisma.position.findUniqueOrThrow({
      where: { id: positionId },
      select: { stockId: true },
    });

    const [trades, bonuses] = await Promise.all([
      this.prisma.trade.findMany({
        where: { positionId },
        orderBy: [{ executedAt: "asc" }, { createdAt: "asc" }],
      }),
      this.prisma.corporateAction.findMany({
        where: { stockId: position.stockId, type: "BONUS_SHARE", recordDate: { not: null } },
        orderBy: { recordDate: "asc" },
      }),
    ]);

    // Build a unified chronological timeline of trade + bonus events so that
    // a bonus declared between two BUYs correctly inflates existing lots
    // before the next sell sees them.
    type Event =
      | { kind: "TRADE"; date: Date; trade: (typeof trades)[number] }
      | { kind: "BONUS"; date: Date; bonus: (typeof bonuses)[number] };
    const events: Event[] = [
      ...trades.map((t) => ({ kind: "TRADE" as const, date: t.executedAt, trade: t })),
      ...bonuses.map((b) => ({ kind: "BONUS" as const, date: b.recordDate!, bonus: b })),
    ].sort((a, b) => a.date.getTime() - b.date.getTime());

    const lots: BuyLot[] = [];
    let realizedPnl = 0;

    for (const event of events) {
      if (event.kind === "BONUS") {
        // Apply pro-rata to every outstanding lot. Floor shares (NEPSE pays
        // fractional balance in cash, which we don't model here). Divide
        // net cost so total cost basis is preserved.
        const factor = 1 + Number(event.bonus.pct ?? 0) / 100;
        if (factor <= 1) continue;
        for (const lot of lots) {
          if (lot.remainingShares <= 0) continue;
          const newShares = Math.floor(lot.remainingShares * factor);
          if (newShares <= 0) continue;
          lot.netPricePerShare = (lot.netPricePerShare * lot.remainingShares) / newShares;
          lot.remainingShares = newShares;
        }
        continue;
      }
      const t = event.trade;
      if (t.side === "BUY") {
        lots.push({
          tradeId: t.id,
          executedAt: t.executedAt,
          netPricePerShare: Number(t.netPricePerShare),
          remainingShares: t.shares,
        });
        continue;
      }
      // SELL — match FIFO, recompute fees, update trade row.
      const matches = fifoMatch(lots, t.shares, Number(t.grossPricePerShare), t.executedAt, schedule.longTermDaysThreshold);
      const sellFees = computeSellFees(t.shares, Number(t.grossPricePerShare), matches, schedule);
      const grossProfit = matches.reduce((acc, m) => acc + m.realizedProfit, 0);
      const sellNet = grossProfit - sellFees.totalFees - sellFees.cgt;
      realizedPnl += sellNet;
      await this.prisma.trade.update({
        where: { id: t.id },
        data: {
          brokerCommission: sellFees.brokerCommission,
          sebonFee: sellFees.sebonFee,
          dpFee: sellFees.dpFee,
          cgt: sellFees.cgt,
          netPricePerShare: sellFees.netProceedsPerShare,
        },
      });
    }

    const totalShares = lots.reduce((acc, l) => acc + l.remainingShares, 0);
    let avgNetCost = 0;
    if (totalShares > 0) {
      const totalCost = lots.reduce((acc, l) => acc + l.remainingShares * l.netPricePerShare, 0);
      avgNetCost = totalCost / totalShares;
    }

    await this.prisma.position.update({
      where: { id: positionId },
      data: {
        totalShares,
        avgNetCost: avgNetCost.toFixed(4),
        realizedPnl: realizedPnl.toFixed(2),
        isOpen: totalShares > 0,
      },
    });
  }
}

export const positionService = new PositionService();
