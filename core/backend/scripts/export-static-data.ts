/**
 * Export the contents of our Postgres DB to a tree of static JSON files
 * that the mobile app fetches directly (GitHub Pages / CDN — no backend
 * runtime required).
 *
 * Layout written to --out (default: ./data):
 *   data/
 *     manifest.json            — top-level index + timestamps + counts
 *     stocks.json              — full universe + tier + curated flag
 *     prices/<SYM>.json        — last N OHLC days per stock
 *     fundamentals/<SYM>.json  — latest snapshot + 5y medians
 *     dividends/<SYM>.json     — full dividend + bonus history
 *     signals-engine.json      — engine config + version for Dart consumer
 *
 * Stocks without data are skipped — the manifest lists exactly what's there.
 *
 * Usage:
 *   npx tsx scripts/export-static-data.ts                  # default: curated + watchlisted
 *   npx tsx scripts/export-static-data.ts --all            # every active stock
 *   npx tsx scripts/export-static-data.ts --out ../data    # custom output dir
 *   npx tsx scripts/export-static-data.ts --price-days 60  # OHLC window (default 30)
 */
import { mkdir, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { db } from "../src/lib/db.js";
import { DEFAULT_ENGINE_CONFIG, ENGINE_VERSION } from "../src/signals/types.js";

interface Args {
  out: string;
  scope: "curated-watchlisted" | "all";
  priceDays: number;
}

function parseArgs(argv: string[]): Args {
  let out = "./data";
  let scope: Args["scope"] = "curated-watchlisted";
  let priceDays = 30;
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--out") out = argv[++i] ?? out;
    else if (a === "--all") scope = "all";
    else if (a === "--price-days") priceDays = parseInt(argv[++i] ?? "30", 10);
  }
  return { out, scope, priceDays };
}

async function ensureDir(path: string): Promise<void> {
  await mkdir(path, { recursive: true });
}

async function writeJson(path: string, data: unknown): Promise<void> {
  await ensureDir(dirname(path));
  await writeFile(path, JSON.stringify(data, null, 2) + "\n", "utf-8");
}

async function pickStocks(scope: Args["scope"]): Promise<Array<{ id: string; symbol: string }>> {
  if (scope === "all") {
    return db.stock.findMany({ where: { status: "ACTIVE" }, select: { id: true, symbol: true }, orderBy: { symbol: "asc" } });
  }
  return db.stock.findMany({
    where: {
      status: "ACTIVE",
      OR: [{ isCurated: true }, { watchlistItems: { some: {} } }],
    },
    select: { id: true, symbol: true },
    orderBy: { symbol: "asc" },
  });
}

async function exportStocks(outDir: string): Promise<number> {
  const rows = await db.stock.findMany({
    where: { status: "ACTIVE" },
    orderBy: { symbol: "asc" },
    select: { symbol: true, name: true, sector: true, status: true, tier: true, isCurated: true },
  });
  await writeJson(resolve(outDir, "stocks.json"), rows);
  return rows.length;
}

async function exportPrices(outDir: string, stockId: string, symbol: string, priceDays: number): Promise<number> {
  const cutoff = new Date(Date.now() - priceDays * 86_400_000);
  const rows = await db.priceObservation.findMany({
    where: { stockId, tradeDate: { gte: cutoff } },
    orderBy: [{ tradeDate: "desc" }, { fetchedAt: "desc" }],
    select: { tradeDate: true, open: true, high: true, low: true, close: true, volume: true, source: true },
  });
  // Group: most-recent observation per tradeDate (newest fetch wins).
  const byDate = new Map<string, typeof rows[number]>();
  for (const r of rows) {
    const k = r.tradeDate.toISOString().slice(0, 10);
    if (!byDate.has(k)) byDate.set(k, r);
  }
  const compact = [...byDate.values()].map((r) => ({
    tradeDate: r.tradeDate.toISOString().slice(0, 10),
    open: r.open.toString(),
    high: r.high.toString(),
    low: r.low.toString(),
    close: r.close.toString(),
    volume: r.volume.toString(),
  }));
  if (compact.length === 0) return 0;
  await writeJson(resolve(outDir, "prices", `${symbol}.json`), compact);
  return compact.length;
}

async function exportFundamentals(outDir: string, stockId: string, symbol: string): Promise<boolean> {
  const [latest, withMedian] = await Promise.all([
    db.fundamentalsObservation.findFirst({
      where: { stockId },
      orderBy: [{ observedAt: "desc" }, { fetchedAt: "desc" }],
    }),
    db.fundamentalsObservation.findFirst({
      where: { stockId, peMedian5y: { not: null } },
      orderBy: [{ observedAt: "desc" }, { fetchedAt: "desc" }],
      select: { peMedian5y: true, pbMedian5y: true },
    }),
  ]);
  if (!latest) return false;
  await writeJson(resolve(outDir, "fundamentals", `${symbol}.json`), {
    observedAt: latest.observedAt.toISOString(),
    pe: latest.pe?.toString() ?? null,
    pb: latest.pb?.toString() ?? null,
    eps: latest.eps?.toString() ?? null,
    bookValue: latest.bookValue?.toString() ?? null,
    marketCap: latest.marketCap?.toString() ?? null,
    peMedian5y: withMedian?.peMedian5y?.toString() ?? latest.peMedian5y?.toString() ?? null,
    pbMedian5y: withMedian?.pbMedian5y?.toString() ?? latest.pbMedian5y?.toString() ?? null,
    dividendYieldPct: latest.dividendYieldPct?.toString() ?? null,
    roeTtm: latest.roeTtm?.toString() ?? null,
    roaTtm: latest.roaTtm?.toString() ?? null,
    netMarginTtm: latest.netMarginTtm?.toString() ?? null,
    epsTtmYoyPct: latest.epsTtmYoyPct?.toString() ?? null,
    source: latest.source,
  });
  return true;
}

async function exportDividends(outDir: string, stockId: string, symbol: string): Promise<number> {
  const rows = await db.corporateAction.findMany({
    where: { stockId, type: { in: ["CASH_DIVIDEND", "BONUS_SHARE", "RIGHT_SHARE"] } },
    orderBy: [{ fiscalYear: "desc" }, { type: "asc" }],
    select: {
      type: true,
      pct: true,
      rightRatio: true,
      fiscalYear: true,
      recordDate: true,
      announcedAt: true,
    },
  });
  if (rows.length === 0) return 0;
  const flat = rows.map((r) => ({
    type: r.type,
    pct: r.pct?.toString() ?? null,
    rightRatio: r.rightRatio,
    fiscalYear: r.fiscalYear,
    recordDate: r.recordDate?.toISOString() ?? null,
    announcedAt: r.announcedAt.toISOString(),
  }));
  await writeJson(resolve(outDir, "dividends", `${symbol}.json`), flat);
  return flat.length;
}

async function exportEngineConfig(outDir: string): Promise<void> {
  await writeJson(resolve(outDir, "signals-engine.json"), {
    version: ENGINE_VERSION,
    config: DEFAULT_ENGINE_CONFIG,
    notes:
      "Default engine config — Dart consumer mirrors these values. " +
      "Per-user overrides (FeeSchedule, DebtAccount, etc.) live in the device's local DB.",
  });
}

async function main(): Promise<void> {
  const args = parseArgs(process.argv.slice(2));
  const outDir = resolve(args.out);
  await ensureDir(outDir);

  console.log(`Exporting static data → ${outDir}`);
  console.log(`  scope: ${args.scope}, price window: ${args.priceDays} days`);

  const stocks = await pickStocks(args.scope);
  const stockCount = await exportStocks(outDir);

  let pricesWritten = 0;
  let fundamentalsWritten = 0;
  let dividendsWritten = 0;

  for (const s of stocks) {
    const priceCount = await exportPrices(outDir, s.id, s.symbol, args.priceDays);
    const hasFund = await exportFundamentals(outDir, s.id, s.symbol);
    const divCount = await exportDividends(outDir, s.id, s.symbol);
    if (priceCount > 0) pricesWritten += 1;
    if (hasFund) fundamentalsWritten += 1;
    if (divCount > 0) dividendsWritten += 1;
  }

  await exportEngineConfig(outDir);

  const manifest = {
    exportedAt: new Date().toISOString(),
    schemaVersion: "1.0.0",
    engineVersion: ENGINE_VERSION,
    counts: {
      stocks: stockCount,
      stocksInScope: stocks.length,
      priceFiles: pricesWritten,
      fundamentalsFiles: fundamentalsWritten,
      dividendFiles: dividendsWritten,
    },
    files: {
      stocks: "stocks.json",
      engineConfig: "signals-engine.json",
      pricesDir: "prices/",
      fundamentalsDir: "fundamentals/",
      dividendsDir: "dividends/",
    },
  };
  await writeJson(resolve(outDir, "manifest.json"), manifest);

  console.log(`\nDone:`);
  console.log(`  ${stockCount} stocks in stocks.json (${stocks.length} in scope)`);
  console.log(`  ${pricesWritten} price files`);
  console.log(`  ${fundamentalsWritten} fundamentals files`);
  console.log(`  ${dividendsWritten} dividend-history files`);
  console.log(`  manifest.json written`);

  await db.$disconnect();
}

main().catch(async (err) => {
  console.error(err);
  await db.$disconnect();
  process.exit(1);
});
