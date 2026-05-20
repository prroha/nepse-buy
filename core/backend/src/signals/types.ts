import type { Season, SignalAction } from "@prisma/client";

/**
 * Pure-function inputs for the decision rule. No DB access.
 */
export interface DecisionInput {
  /** Most recent close price as a numeric string (preserves Decimal precision). */
  close: string;
  /** 20-day moving average, or null if not enough history. */
  ma20: string | null;
  /** Number of price points used to compute ma20 (≤ 20). */
  ma20Window: number;
  season: Season;
  /** Current P/E if available; null otherwise. */
  pe: string | null;
  /** Current P/B if available; null otherwise. */
  pb: string | null;
  /** v0.5+ — 3-5yr median P/E from NEPSE Alpha. Null until that adapter has scraped. */
  peMedian5y?: string | null;
  /** v0.5+ — 3-5yr median P/B from NEPSE Alpha. */
  pbMedian5y?: string | null;
  /** v0.3+ — user's debt position. When STRONG season fires HOLD_FUNDS, this
   *  feeds quantified interest-savings into the rationale. Null if user has none. */
  debt?: DebtContext | null;
  /** v0.4+ — user's existing position on this stock. When paper P/L ≥ harvestThreshold,
   *  engine emits HARVEST with suggested sell tranche. Null if no position. */
  position?: PositionContext | null;
}

/**
 * Aggregated debt context across a user's active debt accounts.
 * Engine doesn't see individual accounts — just the rolled-up numbers used
 * to quantify the cost-of-not-paying-down during STRONG seasons.
 */
export interface DebtContext {
  /** Total outstanding across all active debt accounts, in NPR. */
  totalBalance: number;
  /** Balance-weighted average annual interest rate, e.g., 11.0. */
  weightedAvgRate: number;
  /** Display name for the largest account (rationale text). */
  primaryName: string;
  /** Monthly surplus the user intends to deploy (default Rs 100,000 from strategy). */
  monthlySurplus: number;
}

/**
 * Position summary for one stock — fed to the engine so HARVEST can be emitted
 * with quantified gain and a suggested sell tranche size.
 */
export interface PositionContext {
  totalShares: number;
  /** Volume-weighted average cost per share in NPR. */
  avgCost: number;
}

export interface Decision {
  action: SignalAction;
  rationale: string;
  /** Suggested limit-order price, when action is BUY. Numeric string. */
  suggestedLimit: string | null;
}

/** Knobs the engine respects. Versioned via ENGINE_VERSION. */
export interface EngineConfig {
  /** Minimum history needed for MA20 to be considered valid. */
  ma20MinSamples: number;
  /** Patient limit — primary suggested buy price (e.g., 0.99 = 1% below close). */
  limitDiscountPatient: number;
  /** Aggressive limit — secondary, shown in rationale (e.g., 0.98 = 2% below close). */
  limitDiscountAggressive: number;
  /** Gate flag — when true, current P/E and P/B vs 3-5yr median can override MA20 in WEAK months. */
  peGateEnabled: boolean;
  /** Time zone used to classify season. */
  timezone: string;
  /** Minimum paper P/L (decimal, e.g., 0.30 = 30%) before HARVEST fires. */
  harvestThreshold: number;
  /** Tranche fraction to sell on HARVEST (e.g., 0.25 = sell 25%). */
  harvestSellFraction: number;
}

export const ENGINE_VERSION = "0.5.0-pe-gate-enabled";

export const DEFAULT_ENGINE_CONFIG: EngineConfig = {
  ma20MinSamples: 20,
  limitDiscountPatient: 0.99,
  limitDiscountAggressive: 0.98,
  peGateEnabled: true,
  timezone: "Asia/Kathmandu",
  harvestThreshold: 0.30,
  harvestSellFraction: 0.25,
};
