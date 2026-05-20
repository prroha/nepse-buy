import { describe, expect, it } from "vitest";
import { movingAverage } from "../moving-average.js";

describe("movingAverage", () => {
  it("returns null when below minSamples", () => {
    const r = movingAverage([100, 101, 102], 20, 20);
    expect(r.value).toBeNull();
    expect(r.samplesUsed).toBe(3);
  });

  it("averages exactly windowSize most-recent entries", () => {
    const closes = Array.from({ length: 25 }, (_, i) => 100 + i); // 100..124
    // recent-first order means the first 20 entries are [100..119]
    const r = movingAverage(closes, 20, 20);
    expect(r.value).toBe("109.5000"); // mean of 100..119
    expect(r.samplesUsed).toBe(20);
  });

  it("handles string close prices (Decimal-serialized)", () => {
    const closes = Array.from({ length: 20 }, () => "500.50");
    const r = movingAverage(closes, 20, 20);
    expect(r.value).toBe("500.5000");
    expect(r.samplesUsed).toBe(20);
  });
});
