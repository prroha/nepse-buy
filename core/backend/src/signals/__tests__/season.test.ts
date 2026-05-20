import { describe, expect, it } from "vitest";
import { classifySeason } from "../season.js";

describe("classifySeason (Asia/Kathmandu, v0.2 strong-season expansion)", () => {
  it.each([
    // WEAK
    ["2026-03-15T00:00:00Z", "WEAK"],
    ["2026-06-15T00:00:00Z", "WEAK"],
    ["2026-11-15T00:00:00Z", "WEAK"],
    // STRONG (Jan/Jul/Aug)
    ["2026-01-15T00:00:00Z", "STRONG"],
    ["2026-07-15T00:00:00Z", "STRONG"],
    ["2026-08-15T00:00:00Z", "STRONG"],
    // NORMAL
    ["2026-05-19T00:00:00Z", "NORMAL"],
    ["2026-04-01T00:00:00Z", "NORMAL"],
    ["2026-10-31T00:00:00Z", "NORMAL"],
    // Dec 31 18:30 UTC = Jan 1 00:15 NPT → STRONG (January is now a strong-season month in v0.2)
    ["2026-12-31T18:30:00Z", "STRONG"],
    ["2026-12-15T00:00:00Z", "NORMAL"],
  ])("classifies %s as %s", (iso, expected) => {
    expect(classifySeason(new Date(iso), "Asia/Kathmandu")).toBe(expected);
  });
});
