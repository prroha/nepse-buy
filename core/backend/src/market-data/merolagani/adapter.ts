import { request, Agent } from "undici";
import { load, type CheerioAPI } from "cheerio";
import { DataSource } from "@prisma/client";
import type { FundamentalsQuote, FundamentalsSource } from "../types.js";

const DEFAULT_BASE = "https://merolagani.com";
const PATH = "/CompanyDetail.aspx";

export interface MeroLaganiClientOptions {
  baseUrl?: string;
  userAgent: string;
  timeoutMs?: number;
  insecureTls?: boolean;
}

/**
 * Labels we look up in the <th>Label</th><td>Value</td> info table on the
 * company detail page. Mero Lagani's labels are remarkably stable; new ones
 * added here are non-breaking. Use the canonical label string verbatim.
 */
const LABELS = {
  pe: "P/E Ratio",
  pb: "PBV",
  eps: "EPS",
  bookValue: "Book Value",
  marketCap: "Market Capitalization",
  marketPrice: "Market Price",
  dividendYield: "1 Year Yield",
} as const;

/**
 * Strip commas, "Rs.", whitespace, and the optional "(FY:... Q:...)" annotation
 * Mero Lagani appends to EPS / dividend values. Returns "" if not a parsable number.
 */
function parseDecimalString(raw: string): string {
  const cleaned = raw
    .replace(/Rs\.?/i, "")
    .replace(/,/g, "")
    .replace(/\(.*?\)/g, "")
    .trim();
  if (!cleaned || cleaned === "-" || cleaned.toLowerCase() === "n/a") return "";
  // Allow leading sign + digits + decimal
  const m = cleaned.match(/^[+-]?\d+(\.\d+)?/);
  return m ? m[0] : "";
}

/**
 * Extract "(FY:082-083, Q:3)" style annotation from an EPS value, if present.
 */
function extractFiscalContext(raw: string): string | undefined {
  const m = raw.match(/\(([^)]+)\)/);
  return m ? m[1].trim() : undefined;
}

/**
 * Build a map of normalized label → cell text by walking every <tr> in the
 * page's info tables. Robust to minor markup wiggle — we don't depend on
 * specific tbody/table IDs that ASP.NET often regenerates.
 */
function extractInfoMap($: CheerioAPI): Map<string, string> {
  const map = new Map<string, string>();
  $("tr").each((_, tr) => {
    const $tr = $(tr);
    const $th = $tr.find("th").first();
    const $td = $tr.find("td").first();
    if (!$th.length || !$td.length) return;
    const label = $th.text().replace(/\s+/g, " ").trim();
    const value = $td.text().replace(/\s+/g, " ").trim();
    if (label && value) map.set(label, value);
  });
  return map;
}

export class MeroLaganiAdapter implements FundamentalsSource {
  readonly source: DataSource = "MEROLAGANI";
  private readonly baseUrl: string;
  private readonly userAgent: string;
  private readonly timeoutMs: number;
  private readonly agent: Agent;

  constructor(opts: MeroLaganiClientOptions) {
    this.baseUrl = opts.baseUrl ?? DEFAULT_BASE;
    this.userAgent = opts.userAgent;
    this.timeoutMs = opts.timeoutMs ?? 30_000;
    this.agent = new Agent({
      connect: {
        timeout: this.timeoutMs,
        rejectUnauthorized: opts.insecureTls ? false : true,
      },
    });
  }

  async fetchFundamentals(symbol: string): Promise<FundamentalsQuote | null> {
    const html = await this.getHtml(symbol);
    return this.parse(symbol, html);
  }

  /** Exposed for fixture-based testing — bypasses HTTP. */
  parse(symbol: string, html: string): FundamentalsQuote | null {
    const $ = load(html);
    const info = extractInfoMap($);

    // If we found zero info rows the page is junk (login, error, throttled, etc.)
    if (info.size === 0) return null;

    const peRaw = info.get(LABELS.pe);
    const pbRaw = info.get(LABELS.pb);
    const epsRaw = info.get(LABELS.eps);
    const bookValueRaw = info.get(LABELS.bookValue);
    const marketCapRaw = info.get(LABELS.marketCap);
    const dividendYieldRaw = info.get(LABELS.dividendYield);

    const pe = peRaw ? parseDecimalString(peRaw) || null : null;
    const pb = pbRaw ? parseDecimalString(pbRaw) || null : null;
    const eps = epsRaw ? parseDecimalString(epsRaw) || null : null;
    const bookValue = bookValueRaw ? parseDecimalString(bookValueRaw) || null : null;
    const marketCap = marketCapRaw ? parseDecimalString(marketCapRaw) || null : null;
    const dividendYieldPct = dividendYieldRaw ? parseDecimalString(dividendYieldRaw) || null : null;

    // Parser confidence = fraction of expected fields that parsed cleanly.
    const expected = [pe, pb, eps, bookValue, marketCap];
    const present = expected.filter((v) => v !== null).length;
    const parseConfidence = (present / expected.length).toFixed(2);

    return {
      symbol: symbol.toUpperCase(),
      observedAt: new Date(),
      pe,
      pb,
      eps,
      bookValue,
      dividendYieldPct,
      marketCap,
      parseConfidence,
      epsFiscalContext: epsRaw ? extractFiscalContext(epsRaw) : undefined,
    };
  }

  private async getHtml(symbol: string): Promise<string> {
    const url = `${this.baseUrl}${PATH}?symbol=${encodeURIComponent(symbol.toUpperCase())}`;
    const res = await request(url, {
      method: "GET",
      headers: {
        "User-Agent": this.userAgent,
        Accept: "text/html,application/xhtml+xml",
        "Accept-Language": "en-US,en;q=0.5",
      },
      dispatcher: this.agent,
      headersTimeout: this.timeoutMs,
      bodyTimeout: this.timeoutMs,
    });
    if (res.statusCode < 200 || res.statusCode >= 300) {
      const body = await res.body.text();
      throw new Error(`Mero Lagani HTTP ${res.statusCode} for ${symbol}: ${body.slice(0, 200)}`);
    }
    return await res.body.text();
  }
}

export function createMeroLaganiAdapter(opts: MeroLaganiClientOptions): MeroLaganiAdapter {
  return new MeroLaganiAdapter(opts);
}
