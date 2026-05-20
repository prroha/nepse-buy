import { describe, expect, it } from "vitest";
import { decide } from "../decision.js";
import { DEFAULT_ENGINE_CONFIG } from "../types.js";

const cfg = DEFAULT_ENGINE_CONFIG;

describe("decide (engine v0.2.0-hold-funds)", () => {
  it("SKIP when close is zero / unparseable", () => {
    const r = decide({ close: "0", ma20: "100", ma20Window: 20, season: "NORMAL", pe: null, pb: null }, cfg);
    expect(r.action).toBe("SKIP");
    expect(r.suggestedLimit).toBeNull();
  });

  it("WAIT when MA20 is unavailable", () => {
    const r = decide({ close: "500", ma20: null, ma20Window: 5, season: "NORMAL", pe: null, pb: null }, cfg);
    expect(r.action).toBe("WAIT");
    expect(r.rationale).toMatch(/Only 5 day/);
  });

  it("STRONG month → HOLD_FUNDS with generic OD rationale when user has no debt accounts", () => {
    const r = decide({ close: "500", ma20: "490", ma20Window: 20, season: "STRONG", pe: null, pb: null, debt: null }, cfg);
    expect(r.action).toBe("HOLD_FUNDS");
    expect(r.suggestedLimit).toBeNull();
    expect(r.rationale).toMatch(/overdraft-loan principal/);
    expect(r.rationale).toMatch(/Pause weekly DCA/);
  });

  it("STRONG month + debt context → quantified interest-savings in rationale", () => {
    const r = decide(
      {
        close: "500",
        ma20: "490",
        ma20Window: 20,
        season: "STRONG",
        pe: null,
        pb: null,
        debt: {
          totalBalance: 1_500_000, // 15L OD
          weightedAvgRate: 11.0,
          primaryName: "15L OD Loan",
          monthlySurplus: 100_000,
        },
      },
      cfg
    );
    expect(r.action).toBe("HOLD_FUNDS");
    // Saved ≈ (100_000 × 11 / 100 / 365) × 30 = 904.10... → "904"
    expect(r.rationale).toMatch(/15L OD Loan/);
    expect(r.rationale).toMatch(/Saves ≈ Rs 904/);
    expect(r.rationale).toMatch(/11\.00% p\.a\./);
  });

  it("WEAK month, close ≤ MA20 → BUY with patient + aggressive limits in rationale", () => {
    const r = decide({ close: "500", ma20: "510", ma20Window: 20, season: "WEAK", pe: null, pb: null }, cfg);
    expect(r.action).toBe("BUY");
    expect(r.suggestedLimit).toBe("495.00"); // patient = close × 0.99
    expect(r.rationale).toMatch(/Rs 495\.00 \(patient/);
    expect(r.rationale).toMatch(/Rs 490\.00 \(aggressive/);
    expect(r.rationale).toMatch(/dip qualified/);
  });

  it("WEAK month, close > MA20, no median data → WAIT", () => {
    const r = decide({ close: "510", ma20: "500", ma20Window: 20, season: "WEAK", pe: null, pb: null }, cfg);
    expect(r.action).toBe("WAIT");
    expect(r.suggestedLimit).toBeNull();
    expect(r.rationale).toMatch(/above 20-day MA/);
  });

  it("WEAK month, close > MA20 BUT valuation attractive (gate fires) → BUY", () => {
    const r = decide(
      {
        close: "510",
        ma20: "500",
        ma20Window: 20,
        season: "WEAK",
        pe: "16.66",
        pb: "2.16",
        peMedian5y: "27.19",
        pbMedian5y: "3.37",
      },
      cfg,
    );
    expect(r.action).toBe("BUY");
    expect(r.rationale).toMatch(/valuation gate qualifies/);
    expect(r.rationale).toMatch(/P\/E 16\.66 ≤ 5y avg 27\.19/);
  });

  it("WEAK month, close > MA20 AND valuation rich → WAIT with valuation note", () => {
    const r = decide(
      {
        close: "510",
        ma20: "500",
        ma20Window: 20,
        season: "WEAK",
        pe: "30.0",
        pb: "5.0",
        peMedian5y: "27.19",
        pbMedian5y: "3.37",
      },
      cfg,
    );
    expect(r.action).toBe("WAIT");
    expect(r.rationale).toMatch(/Valuation rich vs 5y avg/);
  });

  it("NORMAL month → BUY with both limit tiers", () => {
    const r = decide({ close: "526", ma20: "524", ma20Window: 20, season: "NORMAL", pe: "15.78", pb: "2.16" }, cfg);
    expect(r.action).toBe("BUY");
    expect(r.suggestedLimit).toBe("520.74"); // 526 × 0.99
    expect(r.rationale).toMatch(/520\.74 \(1% off\)/);
    expect(r.rationale).toMatch(/515\.48 \(2% off\)/);
    expect(r.rationale).toMatch(/weekly DCA/);
  });

  it("when peGateEnabled but no median data, rationale notes 'pending NEPSE Alpha'", () => {
    const r = decide({ close: "526", ma20: "524", ma20Window: 20, season: "NORMAL", pe: "15.78", pb: "2.16" }, cfg);
    expect(r.rationale).toMatch(/NEPSE Alpha median data pending/);
  });

  it("HARVEST fires at +30% paper P/L regardless of season", () => {
    const r = decide(
      {
        close: "1300",
        ma20: "1280",
        ma20Window: 20,
        season: "NORMAL",
        pe: null,
        pb: null,
        position: { totalShares: 100, avgCost: 1000 },
      },
      cfg
    );
    expect(r.action).toBe("HARVEST");
    expect(r.rationale).toMatch(/up 30\.0%/);
    expect(r.rationale).toMatch(/Sell 25 shares/);
    expect(r.rationale).toMatch(/≈ Rs 32500/);
  });

  it("HARVEST in STRONG season includes 'optimal timing' note", () => {
    const r = decide(
      {
        close: "1500",
        ma20: "1300",
        ma20Window: 20,
        season: "STRONG",
        pe: null,
        pb: null,
        position: { totalShares: 100, avgCost: 1000 },
      },
      cfg
    );
    expect(r.action).toBe("HARVEST");
    expect(r.rationale).toMatch(/optimal timing/);
  });

  it("paper P/L < 30% → no HARVEST, falls through to season logic", () => {
    const r = decide(
      {
        close: "1290", // +29% over 1000
        ma20: "1280",
        ma20Window: 20,
        season: "NORMAL",
        pe: null,
        pb: null,
        position: { totalShares: 100, avgCost: 1000 },
      },
      cfg
    );
    expect(r.action).toBe("BUY");
  });
});
