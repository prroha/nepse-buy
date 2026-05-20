import type { DataSource } from "@prisma/client";

/**
 * Normalized daily price observation, source-independent.
 * Money fields are NPR rendered as strings to preserve precision when
 * marshalling to Prisma Decimal (which accepts string).
 */
export interface PriceQuote {
  symbol: string;
  tradeDate: Date;
  open: string;
  high: string;
  low: string;
  close: string;
  volume: bigint;
}

/**
 * Security listing (stock metadata) as seen by a source.
 * `sourceSecurityId` is the source-internal identifier — never persisted
 * in the public Stock model; used only by adapters to fetch per-stock data.
 */
export interface SecurityListing {
  symbol: string;
  name: string;
  sector: string | null;
  sourceSecurityId: number;
}

/**
 * Base interface every market data source implements. Marker for the source enum.
 */
export interface MarketDataSource {
  readonly source: DataSource;
}

/**
 * Capability interface for sources that provide daily price OHLC + volume.
 */
export interface PriceSource extends MarketDataSource {
  fetchSecurityList(): Promise<SecurityListing[]>;
  /**
   * Most recent trading day's OHLC+volume for every active security.
   * Caller decides how to map sourceSecurityId → internal Stock.id.
   */
  fetchTodayPrices(): Promise<PriceQuote[]>;
  /**
   * Historical price series for one security across an inclusive date range.
   * Returns rows ordered most-recent-first by `tradeDate`.
   */
  fetchPriceHistory(input: PriceHistoryRequest): Promise<PriceQuote[]>;
}

export interface PriceHistoryRequest {
  /** Source-internal security id (e.g., NEPSE numeric id from fetchSecurityList). */
  sourceSecurityId: number;
  symbol: string;
  /** Inclusive lower bound. */
  startDate: Date;
  /** Inclusive upper bound. */
  endDate: Date;
}

/**
 * Snapshot fundamentals for a single stock at a moment in time.
 * All numeric fields are Decimal-as-string to preserve precision when
 * marshalling to Prisma Decimal columns. Null means the source did not
 * publish that metric (e.g., not enough quarters yet).
 */
export interface FundamentalsQuote {
  symbol: string;
  observedAt: Date;
  pe: string | null;
  pb: string | null;
  eps: string | null;
  bookValue: string | null;
  marketCap: string | null;
  /** 3-5 year average P/E. Populated by NEPSE Alpha; null elsewhere. */
  peMedian5y?: string | null;
  pbMedian5y?: string | null;
  /** v0.8 — Nepali-context ratios used by the Discover screener. */
  dividendYieldPct?: string | null;
  roeTtm?: string | null;
  roaTtm?: string | null;
  netMarginTtm?: string | null;
  epsTtmYoyPct?: string | null;
  /** Parser confidence 0..1 — values <1 mean some expected fields were missing. */
  parseConfidence: string;
  /** Optional fiscal context for EPS (e.g., "FY:082-083, Q:3"). */
  epsFiscalContext?: string;
  /** Optional raw payload for diagnostics. */
  raw?: unknown;
}

/**
 * Capability interface for sources that publish per-stock fundamentals.
 */
export interface FundamentalsSource extends MarketDataSource {
  fetchFundamentals(symbol: string): Promise<FundamentalsQuote | null>;
}
