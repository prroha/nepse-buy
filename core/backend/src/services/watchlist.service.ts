import type { PrismaClient } from "@prisma/client";
import { db } from "../lib/db.js";
import { ApiError } from "../middleware/error.middleware.js";
import { ErrorCodes } from "../utils/response.js";

export interface WatchlistItemRow {
  id: string;
  rank: number;
  alertsEnabled: boolean;
  stock: {
    id: string;
    symbol: string;
    name: string;
    sector: string | null;
    latestClose: string | null;
    latestPriceDate: string | null;
    latestPe: string | null;
    latestPb: string | null;
  };
  latestSignal: {
    action: string;
    season: string;
    signalDate: string;
    suggestedLimit: string | null;
  } | null;
}

class WatchlistService {
  constructor(private readonly prisma: PrismaClient = db) {}

  async listForUser(userId: string): Promise<WatchlistItemRow[]> {
    const items = await this.prisma.watchlistItem.findMany({
      where: { userId },
      orderBy: [{ rank: "asc" }, { createdAt: "asc" }],
      include: {
        stock: {
          select: {
            id: true,
            symbol: true,
            name: true,
            sector: true,
            priceObservations: {
              orderBy: [{ tradeDate: "desc" }, { fetchedAt: "desc" }],
              take: 1,
              select: { close: true, tradeDate: true },
            },
            fundamentalsObservations: {
              orderBy: [{ observedAt: "desc" }, { fetchedAt: "desc" }],
              take: 1,
              select: { pe: true, pb: true },
            },
            dailySignals: {
              where: { userId },
              orderBy: [{ signalDate: "desc" }],
              take: 1,
              select: { action: true, season: true, signalDate: true, suggestedLimit: true },
            },
          },
        },
      },
    });

    return items.map((i) => {
      const latestPrice = i.stock.priceObservations[0];
      const latestFund = i.stock.fundamentalsObservations[0];
      const latestSignal = i.stock.dailySignals[0];
      return {
        id: i.id,
        rank: i.rank,
        alertsEnabled: i.alertsEnabled,
        stock: {
          id: i.stock.id,
          symbol: i.stock.symbol,
          name: i.stock.name,
          sector: i.stock.sector,
          latestClose: latestPrice?.close.toString() ?? null,
          latestPriceDate: latestPrice?.tradeDate.toISOString().slice(0, 10) ?? null,
          latestPe: latestFund?.pe?.toString() ?? null,
          latestPb: latestFund?.pb?.toString() ?? null,
        },
        latestSignal: latestSignal
          ? {
              action: latestSignal.action,
              season: latestSignal.season,
              signalDate: latestSignal.signalDate.toISOString().slice(0, 10),
              suggestedLimit: latestSignal.suggestedLimit?.toString() ?? null,
            }
          : null,
      };
    });
  }

  async addBySymbol(userId: string, symbol: string): Promise<{ id: string }> {
    const stock = await this.prisma.stock.findUnique({ where: { symbol: symbol.toUpperCase() } });
    if (!stock) {
      throw ApiError.notFound(`Stock not found: ${symbol}`, ErrorCodes.NOT_FOUND);
    }
    const existing = await this.prisma.watchlistItem.findUnique({
      where: { userId_stockId: { userId, stockId: stock.id } },
    });
    if (existing) {
      throw ApiError.conflict("Already in watchlist", ErrorCodes.ALREADY_EXISTS);
    }
    const item = await this.prisma.watchlistItem.create({
      data: { userId, stockId: stock.id },
      select: { id: true },
    });
    return item;
  }

  async remove(userId: string, itemId: string): Promise<void> {
    const item = await this.prisma.watchlistItem.findUnique({ where: { id: itemId } });
    if (!item || item.userId !== userId) {
      throw ApiError.notFound("Watchlist item not found", ErrorCodes.NOT_FOUND);
    }
    await this.prisma.watchlistItem.delete({ where: { id: itemId } });
  }

  /**
   * Seed the new user with the curated default watchlist. Idempotent — uses
   * upsert. Called from the auth signup flow so first-login UX shows familiar names.
   */
  async seedCuratedForUser(userId: string): Promise<{ inserted: number }> {
    const curated = await this.prisma.stock.findMany({ where: { isCurated: true }, select: { id: true } });
    let inserted = 0;
    for (let i = 0; i < curated.length; i++) {
      const result = await this.prisma.watchlistItem.upsert({
        where: { userId_stockId: { userId, stockId: curated[i].id } },
        create: { userId, stockId: curated[i].id, rank: i },
        update: {},
        select: { id: true },
      });
      if (result.id) inserted += 1;
    }
    return { inserted };
  }
}

export const watchlistService = new WatchlistService();
