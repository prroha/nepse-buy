import type { PrismaClient, Stock, StockStatus } from "@prisma/client";
import { db } from "../lib/db.js";
import { ApiError } from "../middleware/error.middleware.js";
import { ErrorCodes } from "../utils/response.js";

export interface StockListFilter {
  /** Free-text query against symbol or name. Case-insensitive contains. */
  q?: string;
  /** When true, only stocks marked as curated. */
  curatedOnly?: boolean;
  /** Status filter (default ACTIVE). Set to null/undefined for all. */
  status?: StockStatus | null;
  page: number;
  limit: number;
}

export interface StockListItem {
  id: string;
  symbol: string;
  name: string;
  sector: string | null;
  status: StockStatus;
  isCurated: boolean;
  latestClose: string | null;
  latestPriceDate: string | null;
  latestPe: string | null;
  latestPb: string | null;
}

export interface StockDetail extends StockListItem {
  latestObservedAt: string | null;
  /** Most recent N price observations, newest first. */
  recentPrices: Array<{ tradeDate: string; close: string; volume: string; source: string }>;
}

class StockService {
  constructor(private readonly prisma: PrismaClient = db) {}

  async list(filter: StockListFilter): Promise<{ items: StockListItem[]; total: number }> {
    const where: Record<string, unknown> = {};
    if (filter.status !== null) where.status = filter.status ?? "ACTIVE";
    if (filter.curatedOnly) where.isCurated = true;
    if (filter.q && filter.q.trim().length > 0) {
      const q = filter.q.trim();
      where.OR = [
        { symbol: { contains: q, mode: "insensitive" } },
        { name: { contains: q, mode: "insensitive" } },
      ];
    }

    const [total, stocks] = await Promise.all([
      this.prisma.stock.count({ where }),
      this.prisma.stock.findMany({
        where,
        orderBy: [{ isCurated: "desc" }, { symbol: "asc" }],
        skip: (filter.page - 1) * filter.limit,
        take: filter.limit,
      }),
    ]);

    const items = await Promise.all(stocks.map((s) => this.decorate(s)));
    return { items, total };
  }

  async getBySymbol(symbol: string, recentLimit = 30): Promise<StockDetail> {
    const stock = await this.prisma.stock.findUnique({ where: { symbol: symbol.toUpperCase() } });
    if (!stock) {
      throw ApiError.notFound(`Stock not found: ${symbol}`, ErrorCodes.NOT_FOUND);
    }
    const base = await this.decorate(stock);
    const recentPrices = await this.prisma.priceObservation.findMany({
      where: { stockId: stock.id },
      orderBy: [{ tradeDate: "desc" }, { fetchedAt: "desc" }],
      take: recentLimit,
      select: { tradeDate: true, close: true, volume: true, source: true },
    });
    const latestFund = await this.prisma.fundamentalsObservation.findFirst({
      where: { stockId: stock.id },
      orderBy: [{ observedAt: "desc" }, { fetchedAt: "desc" }],
      select: { observedAt: true },
    });
    return {
      ...base,
      latestObservedAt: latestFund?.observedAt.toISOString() ?? null,
      recentPrices: recentPrices.map((p) => ({
        tradeDate: p.tradeDate.toISOString().slice(0, 10),
        close: p.close.toString(),
        volume: p.volume.toString(),
        source: p.source,
      })),
    };
  }

  private async decorate(stock: Stock): Promise<StockListItem> {
    const [latestPrice, latestFund] = await Promise.all([
      this.prisma.priceObservation.findFirst({
        where: { stockId: stock.id },
        orderBy: [{ tradeDate: "desc" }, { fetchedAt: "desc" }],
        select: { close: true, tradeDate: true },
      }),
      this.prisma.fundamentalsObservation.findFirst({
        where: { stockId: stock.id },
        orderBy: [{ observedAt: "desc" }, { fetchedAt: "desc" }],
        select: { pe: true, pb: true },
      }),
    ]);
    return {
      id: stock.id,
      symbol: stock.symbol,
      name: stock.name,
      sector: stock.sector,
      status: stock.status,
      isCurated: stock.isCurated,
      latestClose: latestPrice?.close.toString() ?? null,
      latestPriceDate: latestPrice?.tradeDate.toISOString().slice(0, 10) ?? null,
      latestPe: latestFund?.pe?.toString() ?? null,
      latestPb: latestFund?.pb?.toString() ?? null,
    };
  }
}

export const stockService = new StockService();
