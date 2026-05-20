/**
 * One-shot dividend-history scrape from ShareSansar.
 *
 * Usage:
 *   npx tsx scripts/scrape-dividends.ts NABIL                  # one symbol
 *   npx tsx scripts/scrape-dividends.ts NABIL,SCB,CBBL          # list
 *   npx tsx scripts/scrape-dividends.ts --curated               # all curated
 *   npx tsx scripts/scrape-dividends.ts --watchlisted           # all on any watchlist
 *   npx tsx scripts/scrape-dividends.ts --all                   # all active stocks
 *
 * Flags:
 *   --force                Bypass the 90-day staleness gate — re-scrape even
 *                          if we already have fresh data.
 *   --stale-days N         Override the default staleness threshold.
 *
 * Each FY's cash + bonus declarations are upserted into the CorporateAction
 * table (idempotent — safe to re-run). Without --force, stocks scraped in
 * the last 90 days are skipped without hitting the network.
 */
import { dividendScrapeService } from "../src/services/dividend-scrape.service.js";
import { db } from "../src/lib/db.js";

interface Args {
  scopeArg: string;
  force: boolean;
  maxStaleDays?: number;
}

function parseArgs(argv: string[]): Args {
  let scopeArg = "";
  let force = false;
  let maxStaleDays: number | undefined;
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--force") force = true;
    else if (a === "--stale-days") maxStaleDays = parseInt(argv[++i] ?? "0", 10);
    else if (!scopeArg) scopeArg = a;
  }
  return { scopeArg, force, maxStaleDays };
}

async function main(): Promise<void> {
  const args = parseArgs(process.argv.slice(2));
  if (!args.scopeArg) {
    console.error("usage: scrape-dividends.ts <SYMBOL[,…]> | --curated | --watchlisted | --all [--force] [--stale-days N]");
    process.exit(1);
  }
  let symbols: string[] = [];
  if (args.scopeArg === "--curated") {
    symbols = await dividendScrapeService.symbolsForScope("curated");
  } else if (args.scopeArg === "--watchlisted") {
    symbols = await dividendScrapeService.symbolsForScope("watchlisted");
  } else if (args.scopeArg === "--all") {
    symbols = await dividendScrapeService.symbolsForScope("all");
  } else {
    symbols = args.scopeArg.split(",").map((s) => s.trim().toUpperCase()).filter(Boolean);
  }
  console.log(`Scraping dividend history for ${symbols.length} symbols${args.force ? " [FORCE]" : ""}: ${symbols.join(", ")}\n`);
  const results = await dividendScrapeService.scrapeMany(symbols, {
    force: args.force,
    maxStaleDays: args.maxStaleDays,
  });
  for (const r of results) {
    if (r.skippedByGate) {
      console.log(`  · ${r.symbol.padEnd(10)} skipped — ${r.reason}`);
    } else if (r.ok) {
      console.log(`  ✓ ${r.symbol.padEnd(10)} cash=${r.cashInserted}  bonus=${r.bonusInserted}  skipped=${r.skipped}`);
    } else {
      console.log(`  ✗ ${r.symbol.padEnd(10)} FAIL: ${r.error}`);
    }
  }
  const fetched = results.filter((r) => r.ok && !r.skippedByGate).length;
  const gated = results.filter((r) => r.skippedByGate).length;
  const failed = results.filter((r) => !r.ok).length;
  console.log(`\n${fetched} scraped, ${gated} skipped (fresh cache), ${failed} failed.`);
  await db.$disconnect();
}

main().catch(async (err) => {
  console.error(err);
  await db.$disconnect();
  process.exit(1);
});
