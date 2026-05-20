import type { Decision, DecisionInput, EngineConfig } from "./types.js";

/**
 * Pure decision function. No I/O. Given normalized inputs and config,
 * returns {action, rationale, suggestedLimit}.
 *
 * Rules (engine v0.2.0-hold-funds):
 *  1. No close price                 → SKIP
 *  2. Insufficient history           → WAIT
 *  3. STRONG month (Jan/Jul/Aug)     → HOLD_FUNDS (sweep monthly surplus to OD loan)
 *  4. WEAK month + close ≤ MA20      → BUY  (dip qualified; P/E gate disabled)
 *  5. WEAK month + close > MA20      → WAIT (pullback expected)
 *  6. NORMAL month                   → BUY  (standard weekly DCA)
 *
 * BUY rationales include both a "patient" (1% off) and an "aggressive" (2% off)
 * limit price so the user can pick where on the dip ladder to place their order.
 */
export function decide(input: DecisionInput, cfg: EngineConfig): Decision {
  const close = parseFloat(input.close);
  if (!isFinite(close) || close <= 0) {
    return { action: "SKIP", rationale: "No usable close price for the most recent trading day.", suggestedLimit: null };
  }

  if (input.ma20 === null) {
    return {
      action: "WAIT",
      rationale: `Only ${input.ma20Window} day(s) of price history — need ≥${cfg.ma20MinSamples} to compute the 20-day MA. Skipping until more data is collected.`,
      suggestedLimit: null,
    };
  }

  const ma20 = parseFloat(input.ma20);

  // v0.5+ valuation gate. "Attractive" means current P/E AND current P/B
  // both at-or-below their 3-5yr median (NEPSE Alpha pre-computed).
  const pe = input.pe ? parseFloat(input.pe) : null;
  const pb = input.pb ? parseFloat(input.pb) : null;
  const peMed = input.peMedian5y ? parseFloat(input.peMedian5y) : null;
  const pbMed = input.pbMedian5y ? parseFloat(input.pbMedian5y) : null;
  const valuationAttractive =
    cfg.peGateEnabled &&
    pe !== null && peMed !== null && pe <= peMed &&
    pb !== null && pbMed !== null && pb <= pbMed;
  const peNote = !cfg.peGateEnabled
    ? " (Valuation gate disabled.)"
    : peMed === null || pbMed === null
      ? " (Valuation gate not yet active — NEPSE Alpha median data pending.)"
      : valuationAttractive
        ? ` (Valuation attractive: P/E ${pe!.toFixed(2)} ≤ 5y avg ${peMed.toFixed(2)}, P/B ${pb!.toFixed(2)} ≤ ${pbMed.toFixed(2)}.)`
        : ` (Valuation rich vs 5y avg: P/E ${pe?.toFixed(2) ?? "?"} vs ${peMed.toFixed(2)}, P/B ${pb?.toFixed(2) ?? "?"} vs ${pbMed.toFixed(2)}.)`;

  // HARVEST takes precedence — once a position is up ≥ threshold, exit some
  // before any season-based BUY/HOLD logic runs.
  if (input.position && input.position.totalShares > 0 && input.position.avgCost > 0) {
    const paperPL = (close - input.position.avgCost) / input.position.avgCost;
    if (paperPL >= cfg.harvestThreshold) {
      const sellShares = Math.max(1, Math.floor(input.position.totalShares * cfg.harvestSellFraction));
      const sellValue = sellShares * close;
      const seasonNote = input.season === "STRONG"
        ? " (Strong-season month — optimal timing for harvest per strategy doc.)"
        : "";
      return {
        action: "HARVEST",
        rationale:
          `Position up ${(paperPL * 100).toFixed(1)}% — ` +
          `${input.position.totalShares} shares @ avg Rs ${input.position.avgCost.toFixed(2)}, ` +
          `now Rs ${close.toFixed(2)}. ` +
          `Sell ${sellShares} shares (~${(cfg.harvestSellFraction * 100).toFixed(0)}% of position, ≈ Rs ${sellValue.toFixed(0)}) ` +
          `and route proceeds to OD principal.${seasonNote}${peNote}`,
        suggestedLimit: null,
      };
    }
  }

  if (input.season === "STRONG") {
    // Strategy: stop buying entirely; divert monthly surplus to OD loan principal.
    let debtLine = "Deploy this month's surplus to your overdraft-loan principal instead.";
    if (input.debt && input.debt.totalBalance > 0) {
      // Daily interest saved if user diverts `monthlySurplus` for ~30 days
      const dailyInterest = (input.debt.monthlySurplus * input.debt.weightedAvgRate) / 100 / 365;
      const monthSavings = dailyInterest * 30;
      debtLine =
        `Deploy this month's Rs ${input.debt.monthlySurplus.toLocaleString("en-IN")} surplus to your "${input.debt.primaryName}" ` +
        `(outstanding Rs ${input.debt.totalBalance.toLocaleString("en-IN")} @ ${input.debt.weightedAvgRate.toFixed(2)}% p.a.). ` +
        `Saves ≈ Rs ${monthSavings.toFixed(0)} in interest over the next ~30 days.`;
    }
    return {
      action: "HOLD_FUNDS",
      rationale:
        `Strong-season month (Jan/Jul/Aug — retail FOMO + Shrawan-Bhadra liquidity). ` +
        `Pause weekly DCA. ${debtLine}${peNote}`,
      suggestedLimit: null,
    };
  }

  const patientLimit = suggestLimit(close, cfg.limitDiscountPatient);
  const aggressiveLimit = suggestLimit(close, cfg.limitDiscountAggressive);

  if (input.season === "WEAK") {
    // Strategy clause: "Only deploy if … below its 20-day average price,
    // OR P/E & P/B remain attractive." Either is sufficient.
    if (close <= ma20) {
      return {
        action: "BUY",
        rationale:
          `Weak-season month: close Rs ${close.toFixed(2)} ≤ 20-day MA Rs ${ma20.toFixed(2)} — dip qualified. ` +
          `Place a limit order: Rs ${patientLimit} (patient, 1% off) or Rs ${aggressiveLimit} (aggressive, 2% off).${peNote}`,
        suggestedLimit: patientLimit,
      };
    }
    if (valuationAttractive) {
      return {
        action: "BUY",
        rationale:
          `Weak-season month: price above MA20 but valuation gate qualifies — current P/E ${pe!.toFixed(2)} ≤ 5y avg ${peMed!.toFixed(2)} ` +
          `and P/B ${pb!.toFixed(2)} ≤ ${pbMed!.toFixed(2)}. ` +
          `Limit: Rs ${patientLimit} (1% off) or Rs ${aggressiveLimit} (2% off).`,
        suggestedLimit: patientLimit,
      };
    }
    return {
      action: "WAIT",
      rationale:
        `Weak-season month: close Rs ${close.toFixed(2)} above 20-day MA Rs ${ma20.toFixed(2)}. ` +
        `Wait for pullback toward MA before deploying.${peNote}`,
      suggestedLimit: null,
    };
  }

  // NORMAL — standard weekly DCA
  return {
    action: "BUY",
    rationale:
      `Normal-season month — weekly DCA proceeds. ` +
      `Close Rs ${close.toFixed(2)}, 20-day MA Rs ${ma20.toFixed(2)}. ` +
      `Limit: Rs ${patientLimit} (1% off) or Rs ${aggressiveLimit} (2% off).${peNote}`,
    suggestedLimit: patientLimit,
  };
}

function suggestLimit(close: number, discount: number): string {
  return (close * discount).toFixed(2);
}
