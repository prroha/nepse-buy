import { db } from "../lib/db.js";
import { logger } from "../lib/logger.js";
import { config } from "../config/index.js";
import { createShareSansarAdapter } from "../market-data/sharesansar/adapter.js";
import { corporateActionService } from "./corporate-action.service.js";
import { jitteredSleep, withBackoff, withStalenessGate } from "../lib/scraper-hygiene.js";

export interface ScrapeResult {
  symbol: string;
  ok: boolean;
  /** True when the staleness gate skipped this symbol (no network call). */
  skippedByGate?: boolean;
  cashInserted: number;
  bonusInserted: number;
  skipped: number;
  reason?: string;
  error?: string;
}

export interface DividendScrapeOpts {
  /** Bypass staleness gate — re-scrape even if recently successful. */
  force?: boolean;
  /** Override the 90-day default for dividend history. */
  maxStaleDays?: number;
}

/**
 * Scrape ShareSansar dividend history for one or more symbols and persist
 * to the CorporateAction table. v0.9 — staleness-gated: skips network when
 * `ScrapeLog.lastSuccess` is fresh enough. Use `force: true` to override.
 */
class DividendScrapeService {
  private adapter() {
    return createShareSansarAdapter({ userAgent: config.scraper.userAgent });
  }

  async scrapeOne(symbol: string, opts: DividendScrapeOpts = {}): Promise<ScrapeResult> {
    try {
      const outcome = await withStalenessGate(
        symbol,
        {
          source: "SHARESANSAR",
          scope: "dividend-history",
          force: opts.force,
          maxStaleDays: opts.maxStaleDays,
        },
        async () => {
          const rows = await withBackoff(() => this.adapter().fetchDividendHistory(symbol));
          const r = await corporateActionService.ingestShareSansarHistory(symbol, rows);
          logger.info("ShareSansar dividend history ingested", { symbol, ...r, totalRows: rows.length });
          return { value: r, recordCount: r.cashInserted + r.bonusInserted };
        },
      );
      if (outcome.skipped) {
        return {
          symbol,
          ok: true,
          skippedByGate: true,
          cashInserted: 0,
          bonusInserted: 0,
          skipped: 0,
          reason: outcome.reason,
        };
      }
      const r = outcome.result!;
      return { symbol, ok: true, ...r };
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      logger.error("ShareSansar dividend scrape failed", { symbol, error: message });
      return { symbol, ok: false, cashInserted: 0, bonusInserted: 0, skipped: 0, error: message };
    }
  }

  /**
   * Scrape a list of symbols sequentially with jittered delays between
   * network-hitting requests. Aborts the batch on rate-limit (429/403).
   */
  async scrapeMany(symbols: string[], opts: DividendScrapeOpts = {}): Promise<ScrapeResult[]> {
    const out: ScrapeResult[] = [];
    let needsDelay = false;
    for (const s of symbols) {
      if (needsDelay) await jitteredSleep();
      const r = await this.scrapeOne(s, opts);
      out.push(r);
      // Only sleep between actual network calls — gated skips are free.
      needsDelay = !r.skippedByGate;
      if (r.error && /\b(429|403|RateLimitError|blocked)\b/i.test(r.error)) {
        logger.warn("Aborting dividend batch — upstream rate-limit detected", { atSymbol: s, error: r.error });
        break;
      }
    }
    return out;
  }

  /** Scope helpers used by the admin endpoint. */
  async symbolsForScope(scope: "curated" | "watchlisted" | "all"): Promise<string[]> {
    if (scope === "all") {
      const rows = await db.stock.findMany({ where: { status: "ACTIVE" }, select: { symbol: true } });
      return rows.map((r) => r.symbol);
    }
    if (scope === "curated") {
      const rows = await db.stock.findMany({ where: { isCurated: true }, select: { symbol: true } });
      return rows.map((r) => r.symbol);
    }
    // watchlisted
    const rows = await db.watchlistItem.findMany({
      distinct: ["stockId"],
      select: { stock: { select: { symbol: true } } },
    });
    return rows.map((r) => r.stock.symbol);
  }
}

export const dividendScrapeService = new DividendScrapeService();
