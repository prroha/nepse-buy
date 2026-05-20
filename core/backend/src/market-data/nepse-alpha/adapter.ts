import { chromium, type Browser, type BrowserContext } from "playwright";
import { DataSource } from "@prisma/client";
import { logger } from "../../lib/logger.js";
import type { FundamentalsQuote, FundamentalsSource } from "../types.js";

const DEFAULT_BASE = "https://nepsealpha.com";

export interface NepseAlphaOptions {
  baseUrl?: string;
  userAgent?: string;
  /** Per-page navigation timeout in ms. */
  pageTimeoutMs?: number;
  /** Don't actually launch a browser — caller supplies a context (for tests). */
  reuseContext?: BrowserContext;
}

const DEFAULT_UA =
  "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";

/**
 * Pulls a number from a free-text label/value chunk. Handles "16.66 (3-5 Yrs Avg: 27.19)"
 * — pass `subPattern: /3-5 Yrs Avg:\s*([\d.]+)/` to extract the parenthetical.
 */
function extractNumber(text: string, subPattern?: RegExp): string | null {
  if (subPattern) {
    const m = text.match(subPattern);
    return m ? m[1] : null;
  }
  const m = text.match(/[-+]?\d+(?:\.\d+)?/);
  return m ? m[0] : null;
}

/**
 * NEPSE Alpha fundamentals adapter. Uses Playwright (headless Chromium) to
 * clear Cloudflare's JS challenge, then reads the per-stock /stocks/<SYM>/info
 * page. Returns current P/E, P/B, EPS, BV plus the 3-5 year median values
 * NEPSE Alpha pre-computes.
 *
 * Slow (~3-6s per stock) — meant to run weekly, not per request.
 */
export class NepseAlphaAdapter implements FundamentalsSource {
  readonly source: DataSource = "NEPSE_ALPHA";

  private browser: Browser | null = null;
  private context: BrowserContext | null = null;
  private readonly baseUrl: string;
  private readonly userAgent: string;
  private readonly pageTimeoutMs: number;
  private readonly ownContext: boolean;

  constructor(opts: NepseAlphaOptions = {}) {
    this.baseUrl = opts.baseUrl ?? DEFAULT_BASE;
    this.userAgent = opts.userAgent ?? DEFAULT_UA;
    this.pageTimeoutMs = opts.pageTimeoutMs ?? 60_000;
    if (opts.reuseContext) {
      this.context = opts.reuseContext;
      this.ownContext = false;
    } else {
      this.ownContext = true;
    }
  }

  private async ensureContext(): Promise<BrowserContext> {
    if (this.context) return this.context;
    this.browser = await chromium.launch({ headless: true });
    this.context = await this.browser.newContext({
      userAgent: this.userAgent,
      viewport: { width: 1280, height: 800 },
      locale: "en-US",
    });
    return this.context;
  }

  async close(): Promise<void> {
    if (!this.ownContext) return;
    try {
      await this.context?.close();
    } catch {
      // ignore
    }
    try {
      await this.browser?.close();
    } catch {
      // ignore
    }
    this.context = null;
    this.browser = null;
  }

  async fetchFundamentals(symbol: string): Promise<FundamentalsQuote | null> {
    const ctx = await this.ensureContext();
    const page = await ctx.newPage();
    try {
      const url = `${this.baseUrl}/stocks/${symbol.toUpperCase()}/info`;
      await page.goto(url, { waitUntil: "domcontentloaded", timeout: this.pageTimeoutMs });
      await page.waitForLoadState("networkidle", { timeout: this.pageTimeoutMs }).catch(() => undefined);

      const rows = await page.evaluate(() => {
        return Array.from(document.querySelectorAll("table tr, .info-row, .stat-row, dl > div, .summary-row")).map((r) =>
          (r as HTMLElement).innerText?.trim().replace(/\s+/g, " ") ?? "",
        );
      });

      const quote = this.parseRows(symbol, rows);
      return quote;
    } catch (err) {
      logger.error("NEPSE Alpha fetch failed", {
        symbol,
        error: err instanceof Error ? err.message : String(err),
      });
      return null;
    } finally {
      await page.close();
    }
  }

  /** Exposed for testing — pure parser over the row strings. */
  parseRows(symbol: string, rows: string[]): FundamentalsQuote | null {
    const find = (needle: RegExp): string | null => {
      for (const r of rows) if (needle.test(r)) return r;
      return null;
    };

    const peRow = find(/PERatio(TTM)?\b/i) ?? find(/^PE Ratio\b/i);
    const pbRow = find(/PBRatio\b/i) ?? find(/^PB Ratio\b/i);
    const epsRow = find(/EPS\s*TTM\b/i) ?? find(/^EPS\b/i);
    const bvRow = find(/Book Value\b/i);
    const mcRow = find(/Market Capitalization\b/i);
    // v0.8 — extra ratios used by the Discover screener.
    const yieldRow = find(/^1\s*Year\s*Yield\b/i);
    const roeRow = find(/^ROE\s*TTM\b/i) ?? find(/^ROETTM\b/i);
    const roaRow = find(/^ROA\s*TTM\b/i) ?? find(/^ROATTM\b/i);
    const nmRow = find(/^Net\s*Margin\s*TTM\b/i);
    // The "EPS TTM YOY ..." row has alternating value/percent pairs — last percent is most recent.
    const epsYoyRow = find(/^EPS\s*TTM\s*YOY\b/i);

    const pe = peRow ? extractNumber(peRow) : null;
    const pb = pbRow ? extractNumber(pbRow) : null;
    const peMedian = peRow ? extractNumber(peRow, /3-5\s*Yrs?\s*Avg:?\s*([\d.]+)/i) : null;
    const pbMedian = pbRow ? extractNumber(pbRow, /3-5\s*Yrs?\s*Avg:?\s*([\d.]+)/i) : null;
    const eps = epsRow ? extractNumber(epsRow) : null;
    const bookValue = bvRow ? extractNumber(bvRow.replace(/NPR/i, "")) : null;
    const marketCap = mcRow ? extractNumber(mcRow.replace(/NPR/i, "").replace(/,/g, "")) : null;
    const dividendYieldPct = yieldRow ? extractNumber(yieldRow) : null;
    // "ROE TTM 12.24 % 13.08 % … 13.15 %" — take the last numeric value (most recent quarter).
    const roeTtm = roeRow ? lastNumberIn(roeRow) : null;
    const roaTtm = roaRow ? lastNumberIn(roaRow) : null;
    const netMarginTtm = nmRow ? lastNumberIn(nmRow) : null;
    // EPS YoY row has pairs (value, pct); the last percent is the most recent YoY change.
    const epsTtmYoyPct = epsYoyRow ? lastSignedPercentIn(epsYoyRow) : null;

    const expected = [pe, pb, eps, bookValue, marketCap];
    const present = expected.filter((v) => v !== null).length;
    if (present === 0) return null;
    const parseConfidence = (present / expected.length).toFixed(2);

    return {
      symbol: symbol.toUpperCase(),
      observedAt: new Date(),
      pe,
      pb,
      eps,
      bookValue,
      marketCap,
      peMedian5y: peMedian,
      pbMedian5y: pbMedian,
      dividendYieldPct,
      roeTtm,
      roaTtm,
      netMarginTtm,
      epsTtmYoyPct,
      parseConfidence,
    };
  }
}

/** Returns the last numeric value in a row like "ROE TTM 12.24 % 13.08 % … 13.15 %". */
function lastNumberIn(text: string): string | null {
  const matches = text.match(/-?\d+(?:\.\d+)?/g);
  if (!matches) return null;
  return matches[matches.length - 1];
}

/**
 * Returns the last signed-percent value. EPS-YoY rows have alternating
 * (value, percent) pairs — we want the last percent, which is at index −1 of
 * the percent-only sequence. Handles negative percents like "-6.21 %".
 */
function lastSignedPercentIn(text: string): string | null {
  const pctMatches = text.match(/-?\d+(?:\.\d+)?\s*%/g);
  if (!pctMatches || pctMatches.length === 0) return null;
  const last = pctMatches[pctMatches.length - 1];
  return last.replace(/\s*%/, "").trim();
}

export function createNepseAlphaAdapter(opts: NepseAlphaOptions = {}): NepseAlphaAdapter {
  return new NepseAlphaAdapter(opts);
}
