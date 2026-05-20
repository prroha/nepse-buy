/**
 * Backfill 3-4 years of daily price history for all curated (or specified) stocks.
 *
 * Usage:
 *   SMOKE_INSECURE=1 npx tsx scripts/backfill-curated.ts                       # all curated, 4 years
 *   SMOKE_INSECURE=1 npx tsx scripts/backfill-curated.ts --years 3             # 3 years instead
 *   SMOKE_INSECURE=1 npx tsx scripts/backfill-curated.ts --symbols NABIL,SCB   # specific symbols
 *   SMOKE_INSECURE=1 npx tsx scripts/backfill-curated.ts --dry                 # no DB writes
 *
 * Requires Postgres reachable via DATABASE_URL unless --dry.
 */
import { createNepalStockAdapter } from "../src/market-data/nepalstock/adapter.js";
import { MarketDataIngestion } from "../src/market-data/ingestion.js";
import { db } from "../src/lib/db.js";

interface Args {
  years: number;
  symbols: string[] | null;
  dry: boolean;
}

function parseArgs(argv: string[]): Args {
  const a: Args = { years: 4, symbols: null, dry: false };
  for (let i = 0; i < argv.length; i++) {
    const v = argv[i];
    if (v === "--years") a.years = parseInt(argv[++i] ?? "4", 10);
    else if (v === "--symbols") a.symbols = (argv[++i] ?? "").split(",").map((s) => s.trim().toUpperCase()).filter(Boolean);
    else if (v === "--dry") a.dry = true;
  }
  return a;
}

async function main(): Promise<void> {
  const args = parseArgs(process.argv.slice(2));
  console.log(`Backfill: years=${args.years}, symbols=${args.symbols?.join(",") ?? "<curated>"}, dry=${args.dry}`);

  const adapter = createNepalStockAdapter({
    userAgent: "nepse-buy/0.1-dev (backfill)",
    insecureTls: process.env.SMOKE_INSECURE === "1",
  });

  // Step 1 — listing gives us symbol → sourceSecurityId
  console.log("Fetching security list...");
  const listings = await adapter.fetchSecurityList();
  console.log(`  ${listings.length} active securities`);
  const idBySymbol = new Map(listings.map((l) => [l.symbol, l.sourceSecurityId]));

  // Step 2 — figure out which symbols to backfill
  let symbols = args.symbols;
  if (!symbols) {
    if (args.dry) {
      console.warn("--dry without --symbols: cannot read curated list (no DB). Pass --symbols.");
      process.exit(1);
    }
    const curated = await db.stock.findMany({ where: { isCurated: true } });
    symbols = curated.map((s) => s.symbol);
    console.log(`  ${symbols.length} curated stocks: ${symbols.join(", ")}`);
  }

  const endDate = new Date();
  const startDate = new Date(endDate);
  startDate.setFullYear(startDate.getFullYear() - args.years);

  const ingestion = args.dry ? null : new MarketDataIngestion();

  let totalInserted = 0;
  for (const sym of symbols) {
    const id = idBySymbol.get(sym);
    if (!id) {
      console.log(`  ${sym}: SKIP (not in NEPSE security list)`);
      continue;
    }
    process.stdout.write(`  ${sym} (id=${id}) ... `);
    const rows = await adapter.fetchPriceHistory({
      sourceSecurityId: id,
      symbol: sym,
      startDate,
      endDate,
    });
    if (args.dry) {
      console.log(`${rows.length} rows (dry, not written)`);
    } else {
      const { inserted, skipped } = await ingestion!.appendPriceObservations(rows, adapter.source);
      console.log(`${rows.length} rows, ${inserted} inserted, ${skipped} skipped`);
      totalInserted += inserted;
    }
  }
  console.log(`\nBackfill complete. Total inserted: ${totalInserted}`);
  await db.$disconnect();
}

main().catch(async (err) => {
  console.error("Backfill failed:", err instanceof Error ? err.message : err);
  await db.$disconnect();
  process.exit(1);
});
