import { describe, expect, it } from "vitest";
import { fifoMatch } from "../fifo.js";
import type { BuyLot } from "../types.js";

function lot(tradeId: string, executedAt: string, netPricePerShare: number, remainingShares: number): BuyLot {
  return { tradeId, executedAt: new Date(executedAt), netPricePerShare, remainingShares };
}

describe("fifoMatch", () => {
  it("consumes the oldest lot first when it fully covers", () => {
    const lots: BuyLot[] = [
      lot("b1", "2026-01-01", 1000, 100),
      lot("b2", "2026-03-01", 1100, 100),
    ];
    const matches = fifoMatch(lots, 50, 1300, new Date("2026-05-01"), 365);
    expect(matches).toHaveLength(1);
    expect(matches[0].buyTradeId).toBe("b1");
    expect(matches[0].matchedShares).toBe(50);
    expect(matches[0].realizedProfit).toBe(50 * 300);
    expect(lots[0].remainingShares).toBe(50);
    expect(lots[1].remainingShares).toBe(100);
  });

  it("spills across lots when one isn't enough", () => {
    const lots: BuyLot[] = [
      lot("b1", "2026-01-01", 1000, 30),
      lot("b2", "2026-03-01", 1100, 100),
    ];
    const matches = fifoMatch(lots, 50, 1300, new Date("2026-05-01"), 365);
    expect(matches).toHaveLength(2);
    expect(matches[0]).toMatchObject({ buyTradeId: "b1", matchedShares: 30 });
    expect(matches[1]).toMatchObject({ buyTradeId: "b2", matchedShares: 20 });
    expect(lots[0].remainingShares).toBe(0);
    expect(lots[1].remainingShares).toBe(80);
  });

  it("classifies long-term vs short-term per lot", () => {
    const lots: BuyLot[] = [
      lot("b1", "2024-01-01", 1000, 30), // ~500+ days back
      lot("b2", "2026-04-01", 1200, 100), // ~30 days back
    ];
    const matches = fifoMatch(lots, 50, 1300, new Date("2026-05-01"), 365);
    expect(matches[0].isLongTerm).toBe(true);
    expect(matches[1].isLongTerm).toBe(false);
  });

  it("skips lots already fully consumed", () => {
    const lots: BuyLot[] = [
      lot("b1", "2026-01-01", 1000, 0),
      lot("b2", "2026-03-01", 1100, 100),
    ];
    const matches = fifoMatch(lots, 30, 1300, new Date("2026-05-01"), 365);
    expect(matches).toHaveLength(1);
    expect(matches[0].buyTradeId).toBe("b2");
  });

  it("throws when buy inventory is insufficient", () => {
    const lots: BuyLot[] = [lot("b1", "2026-01-01", 1000, 10)];
    expect(() => fifoMatch(lots, 50, 1300, new Date("2026-05-01"), 365))
      .toThrow(/Insufficient buy inventory.*40/);
  });
});
