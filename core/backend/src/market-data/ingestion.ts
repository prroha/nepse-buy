import type { Prisma, PrismaClient } from "@prisma/client";
import { DataSource } from "@prisma/client";
import { db } from "../lib/db.js";
import { logger } from "../lib/logger.js";
import type { PriceQuote, PriceSource, SecurityListing, PriceHistoryRequest, FundamentalsQuote, FundamentalsSource } from "./types.js";

/**
 * Ingestion writes adapter output into append-only observation tables.
 * Never UPDATE/DELETE existing rows; every scrape inserts new ones tagged
 * with `source` + `fetched_at`.
 */
export class MarketDataIngestion {
  constructor(private readonly prisma: PrismaClient = db) {}

  /**
   * Reconcile a source's security list against our Stock table.
   * - Unknown symbols → inserted (status=ACTIVE).
   * - Known symbols with changed name/sector → updated (these are not observations,
   *   they're stable metadata, so update is fine here).
   *
   * Returns a map symbol → internal Stock.id for downstream price ingestion.
   */
  async upsertStocksFromListing(listings: SecurityListing[]): Promise<Map<string, string>> {
    const map = new Map<string, string>();
    for (const l of listings) {
      const stock = await this.prisma.stock.upsert({
        where: { symbol: l.symbol },
        create: {
          symbol: l.symbol,
          name: l.name,
          sector: l.sector,
          status: "ACTIVE",
        },
        update: {
          name: l.name,
          sector: l.sector,
        },
      });
      map.set(l.symbol, stock.id);
    }
    return map;
  }

  /**
   * Append price observations for one scrape pass. Symbols not present in the
   * Stock table are skipped (logged warn) — they should have been onboarded by
   * a prior `upsertStocksFromListing()` call.
   */
  async appendPriceObservations(quotes: PriceQuote[], source: DataSource, raw?: unknown): Promise<{ inserted: number; skipped: number }> {
    const symbols = quotes.map((q) => q.symbol);
    const stocks = await this.prisma.stock.findMany({
      where: { symbol: { in: symbols } },
      select: { id: true, symbol: true },
    });
    const symToId = new Map(stocks.map((s) => [s.symbol, s.id]));

    const rows: Prisma.PriceObservationCreateManyInput[] = [];
    let skipped = 0;
    for (const q of quotes) {
      const stockId = symToId.get(q.symbol);
      if (!stockId) {
        skipped++;
        logger.warn("PriceObservation skipped — unknown symbol", { symbol: q.symbol, source });
        continue;
      }
      rows.push({
        stockId,
        tradeDate: q.tradeDate,
        open: q.open,
        high: q.high,
        low: q.low,
        close: q.close,
        volume: q.volume,
        source,
        raw: raw as Prisma.InputJsonValue,
      });
    }
    if (rows.length === 0) return { inserted: 0, skipped };

    const result = await this.prisma.priceObservation.createMany({
      data: rows,
      skipDuplicates: false,
    });
    return { inserted: result.count, skipped };
  }

  /**
   * Full scrape pass for a price source: list → upsert stocks → today's prices → append observations.
   */
  async runPriceScrape(adapter: PriceSource): Promise<{ stocksUpserted: number; pricesInserted: number; pricesSkipped: number }> {
    const listings = await adapter.fetchSecurityList();
    const symToId = await this.upsertStocksFromListing(listings);
    const quotes = await adapter.fetchTodayPrices();
    const { inserted, skipped } = await this.appendPriceObservations(quotes, adapter.source);
    logger.info("Price scrape complete", {
      source: adapter.source,
      stocks: symToId.size,
      prices: inserted,
      skipped,
    });
    return { stocksUpserted: symToId.size, pricesInserted: inserted, pricesSkipped: skipped };
  }

  /**
   * Backfill historical OHLC for one stock across a date range.
   * Append-only — re-running this will create duplicate rows for the same
   * (stockId, tradeDate, source). De-dup at read time, or use idempotency
   * by deleting prior history-source rows for the range first (caller's choice).
   */
  async backfillStockHistory(adapter: PriceSource, req: PriceHistoryRequest): Promise<{ inserted: number; skipped: number }> {
    const quotes = await adapter.fetchPriceHistory(req);
    const result = await this.appendPriceObservations(quotes, adapter.source);
    logger.info("Backfill complete", {
      source: adapter.source,
      symbol: req.symbol,
      from: req.startDate.toISOString().slice(0, 10),
      to: req.endDate.toISOString().slice(0, 10),
      ...result,
    });
    return result;
  }

  /**
   * Append one fundamentals observation. Symbol must already exist in Stock table.
   */
  async appendFundamentalsObservation(quote: FundamentalsQuote, source: DataSource): Promise<{ inserted: boolean; reason?: string }> {
    const stock = await this.prisma.stock.findUnique({
      where: { symbol: quote.symbol },
      select: { id: true },
    });
    if (!stock) {
      logger.warn("FundamentalsObservation skipped — unknown symbol", { symbol: quote.symbol, source });
      return { inserted: false, reason: "unknown_symbol" };
    }
    await this.prisma.fundamentalsObservation.create({
      data: {
        stockId: stock.id,
        observedAt: quote.observedAt,
        pe: quote.pe,
        pb: quote.pb,
        eps: quote.eps,
        bookValue: quote.bookValue,
        marketCap: quote.marketCap,
        peMedian5y: quote.peMedian5y ?? null,
        pbMedian5y: quote.pbMedian5y ?? null,
        dividendYieldPct: quote.dividendYieldPct ?? null,
        roeTtm: quote.roeTtm ?? null,
        roaTtm: quote.roaTtm ?? null,
        netMarginTtm: quote.netMarginTtm ?? null,
        epsTtmYoyPct: quote.epsTtmYoyPct ?? null,
        source,
        parseConfidence: quote.parseConfidence,
        raw: quote.raw as Prisma.InputJsonValue | undefined,
      },
    });
    return { inserted: true };
  }

  /**
   * Scrape fundamentals for every symbol given, persisting each result.
   * Errors per-symbol are logged but do not abort the batch.
   */
  async runFundamentalsScrape(adapter: FundamentalsSource, symbols: string[]): Promise<{ ok: number; failed: number; skipped: number }> {
    let ok = 0;
    let failed = 0;
    let skipped = 0;
    for (const symbol of symbols) {
      try {
        const quote = await adapter.fetchFundamentals(symbol);
        if (!quote) {
          skipped++;
          logger.warn("Fundamentals scrape returned no data", { symbol, source: adapter.source });
          continue;
        }
        const { inserted } = await this.appendFundamentalsObservation(quote, adapter.source);
        if (inserted) ok++;
        else skipped++;
      } catch (err) {
        failed++;
        logger.error("Fundamentals scrape failed", {
          symbol,
          source: adapter.source,
          error: err instanceof Error ? err.message : String(err),
        });
      }
    }
    logger.info("Fundamentals scrape complete", { source: adapter.source, ok, failed, skipped });
    return { ok, failed, skipped };
  }
}
