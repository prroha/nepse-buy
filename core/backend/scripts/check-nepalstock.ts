/**
 * Live-fetch smoke test for the nepalstock.com.np adapter.
 *
 * Run: npx tsx scripts/check-nepalstock.ts
 *
 * Hits real NEPSE endpoints to verify the WASM auth flow end-to-end.
 * Use sparingly — NEPSE rate-limits aggressively.
 */
import { createNepalStockAdapter } from "../src/market-data/nepalstock/adapter.js";

async function main(): Promise<void> {
  // Local Linux cert stores often miss the intermediate; flip insecure for the smoke check only.
  const adapter = createNepalStockAdapter({
    userAgent: "nepse-buy/0.1-dev (smoke-test)",
    insecureTls: process.env.SMOKE_INSECURE === "1",
  });

  console.log("Fetching security list...");
  const securities = await adapter.fetchSecurityList();
  console.log(`  ${securities.length} active securities`);
  for (const sym of ["NABIL", "NLIC", "CHDC"]) {
    const s = securities.find((x) => x.symbol === sym);
    if (s) console.log(`  ${s.symbol}: id=${s.sourceSecurityId} sector=${s.sector ?? "-"} name=${s.name}`);
    else console.log(`  ${sym}: not found`);
  }

  console.log("\nFetching today's prices...");
  const prices = await adapter.fetchTodayPrices();
  console.log(`  ${prices.length} price rows`);
  for (const sym of ["NABIL", "NLIC", "CHDC"]) {
    const p = prices.find((q) => q.symbol === sym);
    if (p) {
      console.log(`  ${sym}: ${p.tradeDate.toISOString().slice(0, 10)} O=${p.open} H=${p.high} L=${p.low} C=${p.close} vol=${p.volume}`);
    } else {
      console.log(`  ${sym}: not in today's prices (no trades today?)`);
    }
  }
}

main().catch((err) => {
  console.error("Live check failed:", err instanceof Error ? err.message : err);
  process.exit(1);
});
