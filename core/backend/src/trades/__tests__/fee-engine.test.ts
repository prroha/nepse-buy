import { describe, expect, it } from "vitest";
import { computeBrokerage, computeBuyFees, computeSellFees } from "../fee-engine.js";
import { DEFAULT_FEE_SCHEDULE, type FifoMatch } from "../types.js";

const schedule = DEFAULT_FEE_SCHEDULE;

describe("computeBrokerage (NEPSE 2024+ slabs)", () => {
  it.each([
    [40_000, 0.36, "in slab 1 (≤50k)"],
    [50_000, 0.36, "boundary slab 1"],
    [200_000, 0.33, "in slab 2"],
    [1_000_000, 0.31, "in slab 3"],
    [5_000_000, 0.27, "in slab 4"],
    [25_000_000, 0.24, "above 1 Cr"],
  ])("value Rs %s → %s%%", (value, ratePct, _label) => {
    const expected = Math.round(value * (ratePct / 100) * 100) / 100;
    expect(computeBrokerage(value, schedule)).toBe(expected);
  });
});

describe("computeBuyFees", () => {
  it("inflates net cost above gross by the per-share fee load", () => {
    // 100 shares @ Rs 1,000 = Rs 100,000 transaction (slab 2: 0.33%)
    // brokerage = 100,000 * 0.0033 = Rs 330
    // sebon = 100,000 * 0.00015 = Rs 15
    // dp = Rs 25
    // total fees = Rs 370
    // net per share = (100,000 + 370) / 100 = Rs 1,003.70
    const fees = computeBuyFees(100, 1000, schedule);
    expect(fees.brokerCommission).toBe(330);
    expect(fees.sebonFee).toBe(15);
    expect(fees.dpFee).toBe(25);
    expect(fees.totalFees).toBe(370);
    expect(fees.netPricePerShare).toBe(1003.7);
  });

  it("scales correctly across slab boundaries", () => {
    // 1,000 shares @ Rs 600 = Rs 600,000 (slab 3: 0.31%)
    const fees = computeBuyFees(1000, 600, schedule);
    expect(fees.brokerCommission).toBe(1860); // 600,000 * 0.0031
    expect(fees.sebonFee).toBe(90); // 600,000 * 0.00015
    expect(fees.dpFee).toBe(25);
  });
});

describe("computeSellFees", () => {
  it("applies short-term CGT (7.5%) when held < threshold", () => {
    const matches: FifoMatch[] = [
      {
        buyTradeId: "b1",
        buyExecutedAt: new Date("2026-01-01"),
        buyNetPricePerShare: 1000,
        matchedShares: 50,
        realizedProfit: 50 * (1300 - 1000), // = 15,000
        holdingDays: 100,
        isLongTerm: false,
      },
    ];
    // Sell 50 @ Rs 1,300 = Rs 65,000 transaction (slab 2: 0.33%)
    const fees = computeSellFees(50, 1300, matches, schedule);
    expect(fees.brokerCommission).toBe(214.5); // 65,000 * 0.0033
    expect(fees.cgt).toBe(1125); // 15,000 * 7.5%
    expect(fees.cgtBreakdown).toHaveLength(1);
    expect(fees.cgtBreakdown[0].cgtPct).toBe(7.5);
  });

  it("applies long-term CGT (5%) when held ≥ threshold", () => {
    const matches: FifoMatch[] = [
      {
        buyTradeId: "b1",
        buyExecutedAt: new Date("2024-01-01"),
        buyNetPricePerShare: 1000,
        matchedShares: 50,
        realizedProfit: 15_000,
        holdingDays: 400,
        isLongTerm: true,
      },
    ];
    const fees = computeSellFees(50, 1300, matches, schedule);
    expect(fees.cgt).toBe(750); // 15,000 * 5%
    expect(fees.cgtBreakdown[0].cgtPct).toBe(5);
  });

  it("blends ST + LT CGT across multiple matched lots", () => {
    const matches: FifoMatch[] = [
      {
        buyTradeId: "b1",
        buyExecutedAt: new Date("2024-01-01"),
        buyNetPricePerShare: 1000,
        matchedShares: 30,
        realizedProfit: 30 * 300, // 9000
        holdingDays: 800,
        isLongTerm: true,
      },
      {
        buyTradeId: "b2",
        buyExecutedAt: new Date("2026-04-01"),
        buyNetPricePerShare: 1200,
        matchedShares: 20,
        realizedProfit: 20 * 100, // 2000
        holdingDays: 30,
        isLongTerm: false,
      },
    ];
    const fees = computeSellFees(50, 1300, matches, schedule);
    // CGT = 9000 * 5% + 2000 * 7.5% = 450 + 150 = 600
    expect(fees.cgt).toBe(600);
  });

  it("skips CGT on loss-making matches", () => {
    const matches: FifoMatch[] = [
      {
        buyTradeId: "b1",
        buyExecutedAt: new Date("2026-01-01"),
        buyNetPricePerShare: 1500,
        matchedShares: 50,
        realizedProfit: -10_000, // sold at a loss
        holdingDays: 100,
        isLongTerm: false,
      },
    ];
    const fees = computeSellFees(50, 1300, matches, schedule);
    expect(fees.cgt).toBe(0);
    expect(fees.cgtBreakdown).toHaveLength(0);
  });
});
