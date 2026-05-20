/**
 * Live-fetch smoke test for the Mero Lagani fundamentals adapter.
 *
 * Run: npx tsx scripts/check-merolagani.ts                       # all 10 curated
 *      npx tsx scripts/check-merolagani.ts NABIL,SCB              # specific symbols
 */
import { createMeroLaganiAdapter } from "../src/market-data/merolagani/adapter.js";

const CURATED = ["CHDC", "CBBL", "HDL", "SARBTM", "NLIC", "SAHAS", "NTC", "MEN", "GVL", "SCB"];

async function main(): Promise<void> {
  const arg = process.argv[2];
  const symbols = arg ? arg.split(",").map((s) => s.trim().toUpperCase()) : CURATED;

  const adapter = createMeroLaganiAdapter({
    userAgent: "nepse-buy/0.1-dev (fundamentals-smoke)",
    insecureTls: process.env.SMOKE_INSECURE === "1",
  });

  console.log(`Fetching fundamentals for ${symbols.length} stocks...\n`);
  console.log(
    "Symbol".padEnd(10) +
      "P/E".padStart(8) +
      "P/B".padStart(8) +
      "EPS".padStart(10) +
      "BookVal".padStart(10) +
      "MarketCap".padStart(18) +
      "  Conf"
  );
  console.log("-".repeat(76));
  for (const sym of symbols) {
    try {
      const q = await adapter.fetchFundamentals(sym);
      if (!q) {
        console.log(`${sym.padEnd(10)}— page returned no info rows —`);
        continue;
      }
      console.log(
        sym.padEnd(10) +
          (q.pe ?? "-").padStart(8) +
          (q.pb ?? "-").padStart(8) +
          (q.eps ?? "-").padStart(10) +
          (q.bookValue ?? "-").padStart(10) +
          (q.marketCap ?? "-").padStart(18) +
          `  ${q.parseConfidence}`
      );
    } catch (err) {
      console.log(`${sym.padEnd(10)}FAIL: ${err instanceof Error ? err.message : err}`);
    }
  }
}

main().catch((err) => {
  console.error("Smoke failed:", err);
  process.exit(1);
});
