import type { FeeSchedule, FifoMatch } from "./types.js";

export interface BuyFees {
  brokerCommission: number;
  sebonFee: number;
  dpFee: number;
  totalFees: number;
  /** Net cost per share = (gross × shares + totalFees) / shares. */
  netPricePerShare: number;
}

export interface SellFees extends BuyFees {
  /** Per-match CGT details — sum equals `cgt`. */
  cgtBreakdown: Array<{ buyTradeId: string; matchedShares: number; profit: number; cgtPct: number; cgtAmount: number }>;
  /** Total capital-gains tax. */
  cgt: number;
  /** Net SELL proceeds per share = (gross × shares − totalFees − cgt) / shares. */
  netProceedsPerShare: number;
}

/**
 * Slab-based brokerage commission. Finds the first slab whose `upTo` is ≥
 * transactionValue, or the last slab if it has `upTo === null` (open-ended).
 */
export function computeBrokerage(transactionValue: number, schedule: FeeSchedule): number {
  for (const slab of schedule.brokerageSlabs) {
    if (slab.upTo === null || transactionValue <= slab.upTo) {
      return roundCurrency(transactionValue * (slab.ratePct / 100));
    }
  }
  // Should never hit — last slab must be open-ended — but degrade gracefully.
  const last = schedule.brokerageSlabs[schedule.brokerageSlabs.length - 1];
  return roundCurrency(transactionValue * (last.ratePct / 100));
}

/** Computes fees for a BUY trade. Net price ≥ gross (fees inflate cost basis). */
export function computeBuyFees(shares: number, grossPricePerShare: number, schedule: FeeSchedule): BuyFees {
  const transactionValue = shares * grossPricePerShare;
  const brokerCommission = computeBrokerage(transactionValue, schedule);
  const sebonFee = roundCurrency(transactionValue * (schedule.sebonRatePct / 100));
  const dpFee = schedule.dpFlatFee;
  const totalFees = brokerCommission + sebonFee + dpFee;
  const netPricePerShare = round4((transactionValue + totalFees) / shares);
  return { brokerCommission, sebonFee, dpFee, totalFees, netPricePerShare };
}

/**
 * Computes fees + CGT for a SELL trade given the FIFO matches against
 * outstanding BUY lots. The CGT rate per match depends on holding period
 * (ST vs LT). Realized profit per match is the input to CGT.
 */
export function computeSellFees(
  shares: number,
  grossPricePerShare: number,
  matches: FifoMatch[],
  schedule: FeeSchedule,
): SellFees {
  const transactionValue = shares * grossPricePerShare;
  const brokerCommission = computeBrokerage(transactionValue, schedule);
  const sebonFee = roundCurrency(transactionValue * (schedule.sebonRatePct / 100));
  const dpFee = schedule.dpFlatFee;
  const totalFees = brokerCommission + sebonFee + dpFee;

  const cgtBreakdown: SellFees["cgtBreakdown"] = [];
  let cgt = 0;
  for (const m of matches) {
    if (m.realizedProfit <= 0) continue; // No CGT on losses.
    const ratePct = m.isLongTerm ? schedule.cgtLongTermPct : schedule.cgtShortTermPct;
    const cgtAmount = roundCurrency(m.realizedProfit * (ratePct / 100));
    cgt += cgtAmount;
    cgtBreakdown.push({
      buyTradeId: m.buyTradeId,
      matchedShares: m.matchedShares,
      profit: roundCurrency(m.realizedProfit),
      cgtPct: ratePct,
      cgtAmount,
    });
  }
  cgt = roundCurrency(cgt);

  const netProceedsPerShare = round4((transactionValue - totalFees - cgt) / shares);
  return {
    brokerCommission,
    sebonFee,
    dpFee,
    totalFees,
    netPricePerShare: netProceedsPerShare,
    cgtBreakdown,
    cgt,
    netProceedsPerShare,
  };
}

function roundCurrency(n: number): number {
  return Math.round(n * 100) / 100; // 2 decimal places
}

function round4(n: number): number {
  return Math.round(n * 10_000) / 10_000;
}
