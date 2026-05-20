import { DataSource } from "@prisma/client";
import { NepalStockHttpClient, type NepalStockClientOptions } from "./http-client.js";
import { TokenManager } from "./token-manager.js";
import type { PriceHistoryRequest, PriceQuote, PriceSource, SecurityListing } from "../types.js";

// `securityDailyTradeStat/58` (index 58 = NEPSE) returns persistent daily close
// for all listed securities, available outside market hours. `today-price`
// returns full OHLC during/after trading hours but is empty in between.
//
// For v1 we use price-volume (close-only) since our DCA strategy relies on
// close + volume + 20-day MA — open/high/low are nice-to-have. Backfill via
// `/api/nots/market/history/security/{id}` can populate full OHLC later.
const PRICE_VOLUME_PATH = "/api/nots/securityDailyTradeStat/58";
const SECURITY_LIST_PATH = "/api/nots/security?nonDelisted=true";
const HISTORY_PATH = "/api/nots/market/history/security";
const HISTORY_PAGE_SIZE = 500;

interface NepseSecurityRaw {
  id: number;
  symbol: string;
  securityName: string;
  name?: string;
  activeStatus?: string;
}

interface NepsePriceVolumeRaw {
  securityId: string | number;
  securityName: string;
  symbol: string;
  indexId: number;
  totalTradeQuantity: number | string | null;
  lastTradedPrice: number | string | null;
  previousClose: number | string | null;
  closePrice: number | string | null;
  percentageChange?: number;
}

interface NepseHistoryRowRaw {
  businessDate: string;
  totalTrades?: number | null;
  totalTradedQuantity: number | string | null;
  totalTradedValue?: number | null;
  highPrice: number | string | null;
  lowPrice: number | string | null;
  closePrice: number | string | null;
}

interface NepseHistoryEnvelope {
  content: NepseHistoryRowRaw[];
  totalPages: number;
  totalElements: number;
  number: number; // current page (0-based)
  last: boolean;
}

function asDecimalString(v: number | string | null | undefined): string {
  if (v === null || v === undefined || v === "") return "0";
  if (typeof v === "string") return v;
  return v.toString();
}

function asBigInt(v: number | string | null | undefined): bigint {
  if (v === null || v === undefined || v === "") return 0n;
  if (typeof v === "bigint") return v;
  return BigInt(Math.trunc(Number(v)));
}

/**
 * "Today" in Asia/Kathmandu, as a UTC midnight Date suitable for @db.Date.
 * NEPSE timezone is NPT (UTC+5:45). We trust the OS for tz conversion via Intl.
 */
function todayInNPT(): Date {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Kathmandu",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(new Date());
  // en-CA renders as YYYY-MM-DD
  return new Date(`${parts}T00:00:00Z`);
}

export class NepalStockAdapter implements PriceSource {
  readonly source: DataSource = "NEPALSTOCK";

  constructor(private readonly http: NepalStockHttpClient, private readonly now: () => Date = todayInNPT) {}

  async fetchSecurityList(): Promise<SecurityListing[]> {
    const raw = await this.http.fetchAuthed<NepseSecurityRaw[]>(SECURITY_LIST_PATH);
    return raw.map((r) => ({
      symbol: r.symbol.toUpperCase(),
      name: r.securityName,
      // Sector is not in this endpoint; enrich later via /api/nots/company/list or NEPSE Alpha.
      sector: null,
      sourceSecurityId: r.id,
    }));
  }

  async fetchTodayPrices(): Promise<PriceQuote[]> {
    const rows = await this.http.fetchAuthed<NepsePriceVolumeRaw[]>(PRICE_VOLUME_PATH);
    const tradeDate = this.now();

    const quotes: PriceQuote[] = [];
    for (const r of rows) {
      if (!r.symbol) continue;
      const close = r.closePrice ?? r.lastTradedPrice;
      if (close === null || close === undefined) continue;
      const closeStr = asDecimalString(close);
      quotes.push({
        symbol: r.symbol.toUpperCase(),
        tradeDate,
        // Endpoint has no OHL — fill with close. Backfill OHLC via history endpoint when needed.
        open: closeStr,
        high: closeStr,
        low: closeStr,
        close: closeStr,
        volume: asBigInt(r.totalTradeQuantity),
      });
    }
    return quotes;
  }

  async fetchPriceHistory(req: PriceHistoryRequest): Promise<PriceQuote[]> {
    const start = req.startDate.toISOString().slice(0, 10);
    const end = req.endDate.toISOString().slice(0, 10);
    const symbol = req.symbol.toUpperCase();
    const all: PriceQuote[] = [];
    let page = 0;
    // NEPSE pagination is Spring-style; loop until `last: true`.
    // Hard cap to avoid runaway loops if the API misbehaves.
    for (let safety = 0; safety < 20; safety++) {
      const path = `${HISTORY_PATH}/${req.sourceSecurityId}?size=${HISTORY_PAGE_SIZE}&page=${page}&startDate=${start}&endDate=${end}`;
      const env = await this.http.fetchAuthed<NepseHistoryEnvelope>(path);
      for (const r of env.content) {
        if (!r.businessDate) continue;
        const close = r.closePrice;
        if (close === null || close === undefined) continue;
        const closeStr = asDecimalString(close);
        const highStr = asDecimalString(r.highPrice ?? close);
        const lowStr = asDecimalString(r.lowPrice ?? close);
        all.push({
          symbol,
          tradeDate: new Date(`${r.businessDate}T00:00:00Z`),
          open: closeStr, // history endpoint omits open; engine should not rely on it
          high: highStr,
          low: lowStr,
          close: closeStr,
          volume: asBigInt(r.totalTradedQuantity),
        });
      }
      if (env.last || env.content.length === 0) break;
      page += 1;
    }
    return all;
  }
}

export function createNepalStockAdapter(opts: NepalStockClientOptions): NepalStockAdapter {
  const http = new NepalStockHttpClient(opts);
  const tokens = new TokenManager(http);
  http.attachTokenManager(tokens);
  return new NepalStockAdapter(http);
}
