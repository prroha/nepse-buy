import type { DataSource, PrismaClient } from "@prisma/client";
import { db } from "./db.js";
import { logger } from "./logger.js";

/**
 * Standard scrape scopes. Used as `ScrapeLog.scope` and as the lookup key
 * for default staleness thresholds.
 */
export type ScrapeScope =
  | "dividend-history"
  | "fundamentals-current"
  | "fundamentals-medians"
  | "prices-incremental"
  | "corporate-actions";

/** Default staleness windows per scope. Override per-call with `maxStaleDays`. */
const DEFAULT_STALE_DAYS: Record<ScrapeScope, number> = {
  "dividend-history": 90,    // re-check quarterly for new declarations
  "fundamentals-current": 1, // Mero Lagani daily snapshot
  "fundamentals-medians": 90, // NEPSE Alpha 3-5y avg moves slowly
  "prices-incremental": 1,
  "corporate-actions": 90,
};

export interface ScrapeOpts {
  /** Bypass the staleness gate. */
  force?: boolean;
  /** Override the per-scope default staleness threshold. */
  maxStaleDays?: number;
  /** Logical scope name for ScrapeLog grouping. */
  scope: ScrapeScope;
  /** Source enum value. */
  source: DataSource;
}

export interface ScrapeOutcome<T> {
  skipped: boolean;
  reason?: string;
  result?: T;
  error?: string;
}

/**
 * Wrap an actual scrape call with a staleness gate + ScrapeLog write-through.
 * The inner function `fn` runs only when:
 *   - `opts.force === true`, OR
 *   - there is no prior `lastSuccess` for this (source, symbol, scope), OR
 *   - the prior `lastSuccess` is older than `maxStaleDays`.
 *
 * Errors thrown by `fn` are caught, recorded on the ScrapeLog row, and
 * re-thrown — caller decides whether to abort the batch.
 */
export async function withStalenessGate<T>(
  symbol: string,
  opts: ScrapeOpts,
  fn: () => Promise<{ value: T; recordCount: number }>,
  prisma: PrismaClient = db,
): Promise<ScrapeOutcome<T>> {
  const sym = symbol.toUpperCase();
  const log = await prisma.scrapeLog.findUnique({
    where: { source_symbol_scope: { source: opts.source, symbol: sym, scope: opts.scope } },
  });

  if (!opts.force && log?.lastSuccess) {
    const ageDays = (Date.now() - log.lastSuccess.getTime()) / 86_400_000;
    const threshold = opts.maxStaleDays ?? DEFAULT_STALE_DAYS[opts.scope];
    if (ageDays < threshold) {
      return { skipped: true, reason: `${ageDays.toFixed(1)}d old (< ${threshold}d threshold)` };
    }
  }

  try {
    const { value, recordCount } = await fn();
    await prisma.scrapeLog.upsert({
      where: { source_symbol_scope: { source: opts.source, symbol: sym, scope: opts.scope } },
      create: {
        source: opts.source,
        symbol: sym,
        scope: opts.scope,
        lastAttempt: new Date(),
        lastSuccess: new Date(),
        recordCount,
        lastError: null,
      },
      update: {
        lastAttempt: new Date(),
        lastSuccess: new Date(),
        recordCount,
        lastError: null,
      },
    });
    return { skipped: false, result: value };
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    await prisma.scrapeLog.upsert({
      where: { source_symbol_scope: { source: opts.source, symbol: sym, scope: opts.scope } },
      create: {
        source: opts.source,
        symbol: sym,
        scope: opts.scope,
        lastAttempt: new Date(),
        recordCount: 0,
        lastError: message,
      },
      update: { lastAttempt: new Date(), lastError: message },
    });
    throw err;
  }
}

/**
 * Politeness delay between requests. Jitter is half the supplied range,
 * which makes the inter-request gap look more human than a fixed cadence.
 */
export async function jitteredSleep(minMs = 500, maxMs = 1500): Promise<void> {
  const ms = minMs + Math.random() * (maxMs - minMs);
  await new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * Detect server-side rate-limit / block signals — caller should abort the
 * current batch when this returns true rather than burning the retry counter.
 */
export class RateLimitError extends Error {
  constructor(public readonly statusCode: number, public readonly bodySnippet: string) {
    super(`Rate-limited / blocked (HTTP ${statusCode}): ${bodySnippet.slice(0, 200)}`);
  }
}

/**
 * Run `fn` with retry-with-backoff on transient errors. Aborts immediately
 * on 429/403 (raises RateLimitError) so the caller can pause the batch.
 */
export async function withBackoff<T>(fn: () => Promise<T>, maxRetries = 2, baseDelayMs = 2000): Promise<T> {
  let lastErr: unknown;
  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (err) {
      lastErr = err;
      if (err instanceof RateLimitError) throw err;
      const message = err instanceof Error ? err.message : String(err);
      // Detect HTTP-level rate-limit signals in undici error strings.
      if (/\b429\b|\b403\b/.test(message)) {
        throw new RateLimitError(429, message);
      }
      if (attempt < maxRetries) {
        const delay = baseDelayMs * Math.pow(2, attempt) + Math.random() * 500;
        logger.warn("Scrape attempt failed, backing off", { attempt: attempt + 1, delayMs: Math.round(delay), error: message });
        await new Promise((r) => setTimeout(r, delay));
      }
    }
  }
  throw lastErr;
}
