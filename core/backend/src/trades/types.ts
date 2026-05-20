/**
 * Per-user fee + tax schedule. All percentages are stored as percentages
 * (not fractions) — e.g., `sebonRatePct: 0.015` means 0.015% of value.
 */
export interface FeeSchedule {
  brokerageSlabs: BrokerageSlab[];
  sebonRatePct: number;
  dpFlatFee: number;
  cgtShortTermPct: number;
  cgtLongTermPct: number;
  longTermDaysThreshold: number;
}

/**
 * Tiered brokerage slab. `upTo` is the inclusive upper bound on transaction
 * value in NPR. The last slab in the array MUST have `upTo: null` (open-ended).
 */
export interface BrokerageSlab {
  upTo: number | null;
  ratePct: number;
}

/**
 * NEPSE 2024+ defaults — used by `feeScheduleService.getOrSeed`. Editable
 * per-user via PATCH /fee-schedule.
 */
export const DEFAULT_FEE_SCHEDULE: FeeSchedule = {
  brokerageSlabs: [
    { upTo: 50_000, ratePct: 0.36 },
    { upTo: 500_000, ratePct: 0.33 },
    { upTo: 2_000_000, ratePct: 0.31 },
    { upTo: 10_000_000, ratePct: 0.27 },
    { upTo: null, ratePct: 0.24 },
  ],
  sebonRatePct: 0.015,
  dpFlatFee: 25,
  cgtShortTermPct: 7.5,
  cgtLongTermPct: 5,
  longTermDaysThreshold: 365,
};

/**
 * A single buy lot still holding inventory for FIFO matching.
 * `remainingShares` decreases as sells consume the lot in chronological order.
 */
export interface BuyLot {
  tradeId: string;
  executedAt: Date;
  netPricePerShare: number;
  remainingShares: number;
}

/**
 * Result of matching one SELL against one BUY lot.
 * `realizedProfit` is the per-match gross profit before CGT.
 */
export interface FifoMatch {
  buyTradeId: string;
  buyExecutedAt: Date;
  buyNetPricePerShare: number;
  matchedShares: number;
  /** Pre-CGT profit on this match: shares × (sellGross - buyNetCost). */
  realizedProfit: number;
  /** Days held — drives ST vs LT CGT classification. */
  holdingDays: number;
  isLongTerm: boolean;
}
