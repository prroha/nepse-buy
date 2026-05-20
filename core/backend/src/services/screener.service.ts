import type { PrismaClient } from "@prisma/client";
import { db } from "../lib/db.js";
import { corporateActionService } from "./corporate-action.service.js";

export type ScreenerType = "dividend" | "growth" | "safety";

export interface ScreenerRow {
  symbol: string;
  name: string;
  sector: string | null;
  latestClose: string | null;
  /** Score the row was ranked by (semantics depend on screener type). */
  score: string;
  /** Inputs the score was built from — surface to the UI for transparency. */
  metrics: {
    dividendYieldPct?: string | null;
    roeTtm?: string | null;
    epsTtmYoyPct?: string | null;
    marketCap?: string | null;
    pe?: string | null;
    pb?: string | null;
  };
}

/**
 * Single read pass against `FundamentalsObservation` per category.
 * Approach: pull the freshest observation per (stockId) that has the
 * required field non-null, then rank in memory. This keeps the SQL simple
 * and works correctly with NEPSE Alpha weekly + Mero Lagani daily writes —
 * whichever source filled a field most recently wins.
 */
class ScreenerService {
  constructor(private readonly prisma: PrismaClient = db) {}

  async rank(type: ScreenerType, limit: number): Promise<ScreenerRow[]> {
    switch (type) {
      case "dividend":
        return this.rankDividend(limit);
      case "growth":
        return this.rankGrowth(limit);
      case "safety":
        return this.rankSafety(limit);
    }
  }

  private async loadLatestByStock(
    fieldFilter: Record<string, { not: null }>,
  ): Promise<Array<{
    stockId: string;
    symbol: string;
    name: string;
    sector: string | null;
    latestClose: string | null;
    pe: string | null;
    pb: string | null;
    marketCap: string | null;
    dividendYieldPct: string | null;
    roeTtm: string | null;
    epsTtmYoyPct: string | null;
  }>> {
    // Pull all observations with the filter; group to most-recent per stockId.
    const rows = await this.prisma.fundamentalsObservation.findMany({
      where: { ...fieldFilter, stock: { status: "ACTIVE" } },
      orderBy: [{ observedAt: "desc" }, { fetchedAt: "desc" }],
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
              select: { close: true },
            },
          },
        },
      },
    });

    const byStock = new Map<string, (typeof rows)[number]>();
    for (const r of rows) {
      if (!byStock.has(r.stockId)) byStock.set(r.stockId, r);
    }

    return [...byStock.values()].map((r) => ({
      stockId: r.stockId,
      symbol: r.stock.symbol,
      name: r.stock.name,
      sector: r.stock.sector,
      latestClose: r.stock.priceObservations[0]?.close.toString() ?? null,
      pe: r.pe?.toString() ?? null,
      pb: r.pb?.toString() ?? null,
      marketCap: r.marketCap?.toString() ?? null,
      dividendYieldPct: r.dividendYieldPct?.toString() ?? null,
      roeTtm: r.roeTtm?.toString() ?? null,
      epsTtmYoyPct: r.epsTtmYoyPct?.toString() ?? null,
    }));
  }

  /**
   * Top dividend — 3-year total of cash + bonus declarations when we have
   * scraped history (ShareSansar), with current 1-year yield as a fallback
   * when CorporateAction rows haven't been populated for a stock yet.
   * Tie-break by market cap.
   */
  private async rankDividend(limit: number): Promise<ScreenerRow[]> {
    // Candidates = stocks with at least one fundamentals observation OR any
    // historical CorporateAction row. We start from the fundamentals-observed
    // set (already filtered to ACTIVE stocks) and enrich with 3yr totals.
    const rows = await this.loadLatestByStock({});
    const enriched = await Promise.all(
      rows.map(async (r) => {
        const stock = await this.prisma.stock.findUnique({ where: { symbol: r.symbol }, select: { id: true } });
        const total3y = stock ? await corporateActionService.totalDividendOverLastYears(stock.id, 3) : 0;
        return { row: r, total3y };
      }),
    );
    enriched.sort((a, b) => {
      // Prefer historical totals; fall back to (currentYield × 3) for stocks
      // with no scraped history yet.
      const aScore = a.total3y > 0 ? a.total3y : parseFloat(a.row.dividendYieldPct ?? "0") * 3;
      const bScore = b.total3y > 0 ? b.total3y : parseFloat(b.row.dividendYieldPct ?? "0") * 3;
      if (Math.abs(aScore - bScore) > 0.01) return bScore - aScore;
      return parseFloat(b.row.marketCap ?? "0") - parseFloat(a.row.marketCap ?? "0");
    });
    return enriched
      .filter((e) => e.total3y > 0 || (e.row.dividendYieldPct && parseFloat(e.row.dividendYieldPct) > 0))
      .slice(0, limit)
      .map(({ row, total3y }) => ({
        symbol: row.symbol,
        name: row.name,
        sector: row.sector,
        latestClose: row.latestClose,
        score: total3y > 0 ? total3y.toFixed(2) : (row.dividendYieldPct ?? "0"),
        metrics: {
          dividendYieldPct: row.dividendYieldPct,
          marketCap: row.marketCap,
          pe: row.pe,
        },
      }));
  }

  /**
   * Composite growth score = 0.6 × epsTtmYoyPct + 0.4 × roeTtm.
   * Picks stocks with strong recent earnings growth + healthy return on equity.
   */
  private async rankGrowth(limit: number): Promise<ScreenerRow[]> {
    const rows = await this.loadLatestByStock({ epsTtmYoyPct: { not: null }, roeTtm: { not: null } });
    const scored = rows.map((r) => {
      const yoy = parseFloat(r.epsTtmYoyPct ?? "0");
      const roe = parseFloat(r.roeTtm ?? "0");
      const score = 0.6 * yoy + 0.4 * roe;
      return { row: r, score };
    });
    scored.sort((a, b) => b.score - a.score);
    return scored.slice(0, limit).map(({ row, score }) => ({
      symbol: row.symbol,
      name: row.name,
      sector: row.sector,
      latestClose: row.latestClose,
      score: score.toFixed(2),
      metrics: {
        epsTtmYoyPct: row.epsTtmYoyPct,
        roeTtm: row.roeTtm,
        marketCap: row.marketCap,
        pe: row.pe,
      },
    }));
  }

  /**
   * Safety score combines size (market cap, log-scaled) with profitability
   * (ROE) and avoids overvalued names by adding a small P/E discount.
   * High market cap + consistent ROE + reasonable valuation = "if I had to
   * hold one stock through any crash."
   */
  private async rankSafety(limit: number): Promise<ScreenerRow[]> {
    const rows = await this.loadLatestByStock({ marketCap: { not: null } });
    const scored = rows.map((r) => {
      const mcap = parseFloat(r.marketCap ?? "0");
      const roe = parseFloat(r.roeTtm ?? "0");
      const pe = parseFloat(r.pe ?? "30");
      // log10 of market cap normalizes the long tail; +ROE rewards profitability;
      // 1/PE penalizes expensive valuations slightly.
      const logCap = mcap > 0 ? Math.log10(mcap) : 0;
      const peDiscount = pe > 0 ? 10 / pe : 0;
      const score = logCap * 2 + roe * 0.3 + peDiscount;
      return { row: r, score };
    });
    scored.sort((a, b) => b.score - a.score);
    return scored.slice(0, limit).map(({ row, score }) => ({
      symbol: row.symbol,
      name: row.name,
      sector: row.sector,
      latestClose: row.latestClose,
      score: score.toFixed(2),
      metrics: {
        marketCap: row.marketCap,
        roeTtm: row.roeTtm,
        pe: row.pe,
        pb: row.pb,
      },
    }));
  }
}

export const screenerService = new ScreenerService();
