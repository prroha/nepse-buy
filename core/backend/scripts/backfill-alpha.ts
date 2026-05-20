/**
 * Weekly NEPSE Alpha refresh — scrapes 3-5yr median P/E and P/B for every
 * symbol on at least one user's watchlist (or `--symbols` override).
 *
 * Slow: each stock takes ~4-6s through the Cloudflare bypass.
 * Run: SMOKE_INSECURE=1 npx tsx scripts/backfill-alpha.ts
 *      npx tsx scripts/backfill-alpha.ts --symbols NABIL,SCB --dry
 */
import { createNepseAlphaAdapter } from "../src/market-data/nepse-alpha/adapter.js";
import { MarketDataIngestion } from "../src/market-data/ingestion.js";
import { db } from "../src/lib/db.js";

interface Args {
  symbols: string[] | null;
  dry: boolean;
}

function parseArgs(argv: string[]): Args {
  const a: Args = { symbols: null, dry: false };
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === "--symbols") a.symbols = (argv[++i] ?? "").split(",").map((s) => s.trim().toUpperCase()).filter(Boolean);
    else if (argv[i] === "--dry") a.dry = true;
  }
  return a;
}

async function main(): Promise<void> {
  const args = parseArgs(process.argv.slice(2));

  let symbols = args.symbols;
  if (!symbols) {
    const rows = await db.stock.findMany({
      where: { OR: [{ isCurated: true }, { watchlistItems: { some: {} } }] },
      select: { symbol: true },
      orderBy: { symbol: "asc" },
    });
    symbols = rows.map((r) => r.symbol);
  }
  console.log(`Backfill NEPSE Alpha for ${symbols.length} symbols: ${symbols.join(", ")}`);
  if (args.dry) console.log("(dry-run — no DB writes)");

  const adapter = createNepseAlphaAdapter();
  const ingestion = args.dry ? null : new MarketDataIngestion();
  let ok = 0;
  let failed = 0;
  try {
    for (const sym of symbols) {
      process.stdout.write(`  ${sym} ... `);
      try {
        const q = await adapter.fetchFundamentals(sym);
        if (!q) {
          console.log("no data");
          failed++;
          continue;
        }
        console.log(`P/E ${q.pe ?? "-"} (5y ${q.peMedian5y ?? "-"}) · P/B ${q.pb ?? "-"} (5y ${q.pbMedian5y ?? "-"})`);
        if (ingestion) {
          await ingestion.appendFundamentalsObservation(q, adapter.source);
        }
        ok++;
      } catch (err) {
        console.log(`FAIL: ${err instanceof Error ? err.message : err}`);
        failed++;
      }
    }
  } finally {
    await adapter.close();
    await db.$disconnect();
  }
  console.log(`\nBackfill complete — ${ok} ok, ${failed} failed.`);
}

main().catch(async (err) => {
  console.error(err);
  await db.$disconnect();
  process.exit(1);
});
