/**
 * Live-fetch smoke test for the NEPSE Alpha fundamentals adapter.
 * Slow — Cloudflare bypass + DOM parse runs per symbol (~4-6s each).
 *
 * Run: npx tsx scripts/check-nepse-alpha.ts                       # all 11 curated
 *      npx tsx scripts/check-nepse-alpha.ts NABIL,NLIC            # specific
 */
import { createNepseAlphaAdapter } from "../src/market-data/nepse-alpha/adapter.js";

const CURATED = ["CHDC", "CBBL", "HDL", "SARBTM", "NLIC", "SAHAS", "NTC", "MEN", "GVL", "SCB", "NMFBS"];

async function main(): Promise<void> {
  const arg = process.argv[2];
  const symbols = arg ? arg.split(",").map((s) => s.trim().toUpperCase()) : CURATED;

  const adapter = createNepseAlphaAdapter();
  try {
    console.log("Symbol".padEnd(10) + "P/E".padStart(8) + "5y-Avg".padStart(10) + "P/B".padStart(8) + "5y-Avg".padStart(10) + "  Conf");
    console.log("-".repeat(56));
    for (const sym of symbols) {
      const q = await adapter.fetchFundamentals(sym);
      if (!q) {
        console.log(`${sym.padEnd(10)}— failed —`);
        continue;
      }
      console.log(
        sym.padEnd(10) +
          (q.pe ?? "-").padStart(8) +
          (q.peMedian5y ?? "-").padStart(10) +
          (q.pb ?? "-").padStart(8) +
          (q.pbMedian5y ?? "-").padStart(10) +
          `  ${q.parseConfidence}`,
      );
    }
  } finally {
    await adapter.close();
  }
}

main().catch((err) => {
  console.error("Smoke failed:", err);
  process.exit(1);
});
