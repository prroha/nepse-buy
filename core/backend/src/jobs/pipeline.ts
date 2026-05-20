import { db } from "../lib/db.js";
import { logger } from "../lib/logger.js";
import { config } from "../config/index.js";
import { createNepalStockAdapter } from "../market-data/nepalstock/adapter.js";
import { createMeroLaganiAdapter } from "../market-data/merolagani/adapter.js";
import { MarketDataIngestion } from "../market-data/ingestion.js";
import { SignalEngine } from "../signals/engine.js";
import { NotificationDispatcher } from "../notifications/dispatcher.js";

export interface PipelineResult {
  pricesInserted: number;
  pricesSkipped: number;
  fundamentalsOk: number;
  fundamentalsFailed: number;
  signalsEvaluated: number;
  digestsEmailed: number;
  digestsFailed: number;
}

/**
 * Full daily pipeline. Runs sequentially:
 *   1. Scrape today's prices from nepalstock.com.np (all listed stocks)
 *   2. Scrape fundamentals from merolagani.com (for stocks in any watchlist)
 *   3. Evaluate signals for every user's watchlist
 *
 * Errors in any step are logged but do not abort downstream steps — partial
 * data is better than none for daily DCA signals. Caller (BullMQ) handles retry.
 *
 * Notification delivery is enqueued separately in Task #8.
 */
export async function runDailyPipeline(signalDate: Date = new Date()): Promise<PipelineResult> {
  const ingestion = new MarketDataIngestion();
  const result: PipelineResult = {
    pricesInserted: 0,
    pricesSkipped: 0,
    fundamentalsOk: 0,
    fundamentalsFailed: 0,
    signalsEvaluated: 0,
    digestsEmailed: 0,
    digestsFailed: 0,
  };

  // --- Step 1: prices
  try {
    const adapter = createNepalStockAdapter({
      userAgent: config.scraper.userAgent,
      timeoutMs: config.scraper.timeoutMs,
    });
    const r = await ingestion.runPriceScrape(adapter);
    result.pricesInserted = r.pricesInserted;
    result.pricesSkipped = r.pricesSkipped;
  } catch (err) {
    logger.error("Pipeline step 1 (price scrape) failed", {
      error: err instanceof Error ? err.message : String(err),
    });
  }

  // --- Step 2: fundamentals (only symbols on at least one watchlist, to limit load)
  try {
    const watched = await db.watchlistItem.findMany({
      distinct: ["stockId"],
      select: { stock: { select: { symbol: true } } },
    });
    const symbols = watched.map((w) => w.stock.symbol);
    if (symbols.length === 0) {
      logger.info("Pipeline step 2 skipped — no symbols on any watchlist yet");
    } else {
      const fund = createMeroLaganiAdapter({
        userAgent: config.scraper.userAgent,
        timeoutMs: config.scraper.timeoutMs,
      });
      const r = await ingestion.runFundamentalsScrape(fund, symbols);
      result.fundamentalsOk = r.ok;
      result.fundamentalsFailed = r.failed;
    }
  } catch (err) {
    logger.error("Pipeline step 2 (fundamentals scrape) failed", {
      error: err instanceof Error ? err.message : String(err),
    });
  }

  // --- Step 3: signal evaluation for every user with a watchlist
  try {
    const users = await db.user.findMany({
      where: { isActive: true, watchlistItems: { some: {} } },
      select: { id: true },
    });
    const engine = new SignalEngine();
    for (const u of users) {
      const sigs = await engine.evaluateWatchlist(u.id, signalDate);
      result.signalsEvaluated += sigs.length;
    }
  } catch (err) {
    logger.error("Pipeline step 3 (signal evaluation) failed", {
      error: err instanceof Error ? err.message : String(err),
    });
  }

  // --- Step 4: notification dispatch
  try {
    const dispatcher = new NotificationDispatcher();
    const r = await dispatcher.dispatchDailyDigests(signalDate);
    result.digestsEmailed = r.emailsSent;
    result.digestsFailed = r.emailsFailed;
  } catch (err) {
    logger.error("Pipeline step 4 (notification dispatch) failed", {
      error: err instanceof Error ? err.message : String(err),
    });
  }

  logger.info("Daily pipeline complete", { ...result });
  return result;
}
