/**
 * Database seed.
 *
 * Seeds the curated default watchlist — the 11 stocks new users see by default.
 * Users can add their own via WatchlistItem.
 *
 * v0.3 — sets `tier` so the engine ranks cash-printer names higher in WEAK months.
 *
 * Run: npm run db:seed (from core/backend)
 * Idempotent: upserts by symbol.
 */
import { PrismaClient, StockTier } from "@prisma/client";

const prisma = new PrismaClient();

interface SeedStock {
  symbol: string;
  name: string;
  sector: string | null;
  tier: StockTier;
}

/**
 * Curated stocks — verified against live NEPSE security list on 2026-05-19.
 * "Cash-printer tier" = low-float, high-ROE names the user wants the engine to
 * prefer for weekly DCA deploys (HDL, CBBL, NMFBS, SAHAS, MEN per strategy doc).
 */
const CURATED_STOCKS: SeedStock[] = [
  { symbol: "CHDC", name: "CEDB Holdings Limited", sector: null, tier: "STANDARD" },
  { symbol: "CBBL", name: "Chhimek Laghubitta Bittiya Sanstha Limited", sector: "Microfinance", tier: "LOW_FLOAT_CASH_PRINTER" },
  { symbol: "HDL", name: "Himalayan Distillery Limited", sector: "Manufacturing", tier: "LOW_FLOAT_CASH_PRINTER" },
  { symbol: "SARBTM", name: "Sarbottam Cement Limited", sector: "Manufacturing", tier: "STANDARD" },
  { symbol: "NLIC", name: "Nepal Life Insurance Co. Ltd.", sector: "Life Insurance", tier: "STANDARD" },
  { symbol: "SAHAS", name: "Sahas Urja Limited", sector: "Hydropower", tier: "LOW_FLOAT_CASH_PRINTER" },
  { symbol: "NTC", name: "Nepal Doorsanchar Company Limited", sector: "Others", tier: "STANDARD" },
  { symbol: "MEN", name: "Mountain Energy Nepal Limited", sector: "Hydropower", tier: "LOW_FLOAT_CASH_PRINTER" },
  { symbol: "GVL", name: "Green Ventures Limited", sector: null, tier: "STANDARD" },
  { symbol: "SCB", name: "Standard Chartered Bank Limited", sector: "Commercial Banks", tier: "STANDARD" },
  { symbol: "NMFBS", name: "National Laghubitta Bittiya Sanstha Limited", sector: "Microfinance", tier: "LOW_FLOAT_CASH_PRINTER" },
];

async function main(): Promise<void> {
  let inserted = 0;
  let updated = 0;
  for (const s of CURATED_STOCKS) {
    const existing = await prisma.stock.findUnique({ where: { symbol: s.symbol } });
    await prisma.stock.upsert({
      where: { symbol: s.symbol },
      create: { ...s, status: "ACTIVE", isCurated: true },
      update: { name: s.name, sector: s.sector, tier: s.tier, isCurated: true },
    });
    if (existing) updated++;
    else inserted++;
  }
  console.log(`Seed complete — curated stocks: ${inserted} inserted, ${updated} updated.`);
}

main()
  .catch((err) => {
    console.error("Seed failed:", err);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
