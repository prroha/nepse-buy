import type { CorporateActionType, PrismaClient } from "@prisma/client";
import { db } from "../lib/db.js";
import { ApiError } from "../middleware/error.middleware.js";
import { ErrorCodes } from "../utils/response.js";

export interface CorporateActionRow {
  id: string;
  stockId: string;
  symbol: string;
  type: CorporateActionType;
  pct: string | null;
  rightRatio: string | null;
  fiscalYear: string | null;
  recordDate: string | null;
  announcedAt: string;
  source: string;
}

export interface LogCorporateActionInput {
  /** Either `stockId` or `symbol` must be provided. */
  stockId?: string;
  symbol?: string;
  type: CorporateActionType;
  /** For CASH_DIVIDEND / BONUS_SHARE: percent as decimal (e.g., 12.5). */
  pct?: number;
  /** For RIGHT_SHARE: ratio expressed as "X:Y". */
  rightRatio?: string;
  fiscalYear?: string;
  recordDate?: Date;
  announcedAt?: Date;
}

class CorporateActionService {
  constructor(private readonly prisma: PrismaClient = db) {}

  async list(stockId: string): Promise<CorporateActionRow[]> {
    const rows = await this.prisma.corporateAction.findMany({
      where: { stockId },
      orderBy: [{ recordDate: "desc" }, { announcedAt: "desc" }],
      include: { stock: { select: { symbol: true } } },
    });
    return rows.map(toRow);
  }

  async listBySymbol(symbol: string): Promise<CorporateActionRow[]> {
    const stock = await this.prisma.stock.findUnique({ where: { symbol: symbol.toUpperCase() } });
    if (!stock) throw ApiError.notFound(`Stock not found: ${symbol}`, ErrorCodes.NOT_FOUND);
    return this.list(stock.id);
  }

  async create(input: LogCorporateActionInput): Promise<CorporateActionRow> {
    let stockId = input.stockId;
    if (!stockId) {
      if (!input.symbol) throw ApiError.badRequest("symbol or stockId required", ErrorCodes.VALIDATION_ERROR);
      const stock = await this.prisma.stock.findUnique({ where: { symbol: input.symbol.toUpperCase() } });
      if (!stock) throw ApiError.notFound(`Stock not found: ${input.symbol}`, ErrorCodes.NOT_FOUND);
      stockId = stock.id;
    }

    // Validate per-type required fields
    if (input.type === "CASH_DIVIDEND" || input.type === "BONUS_SHARE") {
      if (input.pct === undefined || input.pct <= 0) {
        throw ApiError.badRequest(`${input.type} requires positive pct`, ErrorCodes.VALIDATION_ERROR);
      }
    } else if (input.type === "RIGHT_SHARE") {
      if (!input.rightRatio || !/^\d+:\d+$/.test(input.rightRatio)) {
        throw ApiError.badRequest("RIGHT_SHARE requires rightRatio like '1:5'", ErrorCodes.VALIDATION_ERROR);
      }
    }

    const row = await this.prisma.corporateAction.create({
      data: {
        stockId,
        type: input.type,
        pct: input.pct?.toFixed(4),
        rightRatio: input.rightRatio,
        fiscalYear: input.fiscalYear,
        recordDate: input.recordDate,
        announcedAt: input.announcedAt ?? new Date(),
        source: "MANUAL",
      },
      include: { stock: { select: { symbol: true } } },
    });
    return toRow(row);
  }

  async remove(id: string): Promise<void> {
    const row = await this.prisma.corporateAction.findUnique({ where: { id } });
    if (!row) throw ApiError.notFound("Corporate action not found", ErrorCodes.NOT_FOUND);
    await this.prisma.corporateAction.delete({ where: { id } });
  }

  /** Engine helper — bonus actions for a stock with recordDate set, oldest first. */
  async listBonusesForStock(stockId: string): Promise<Array<{ id: string; pct: number; recordDate: Date }>> {
    const rows = await this.prisma.corporateAction.findMany({
      where: { stockId, type: "BONUS_SHARE", recordDate: { not: null } },
      orderBy: { recordDate: "asc" },
      select: { id: true, pct: true, recordDate: true },
    });
    return rows.map((r) => ({
      id: r.id,
      pct: Number(r.pct ?? 0),
      recordDate: r.recordDate!,
    }));
  }

  /**
   * Persist a ShareSansar dividend history scrape. One CASH_DIVIDEND row + one
   * BONUS_SHARE row per non-zero fiscal year. Idempotent via the schema's
   * `@@unique([stockId, type, fiscalYear])` — re-running upserts existing rows.
   */
  async ingestShareSansarHistory(
    symbol: string,
    rows: Array<{
      bonusShare: string;
      cashDividend: string;
      announcementDate: string;
      bookCloseDate: string;
      fiscalYear: string;
    }>,
  ): Promise<{ cashInserted: number; bonusInserted: number; skipped: number }> {
    const stock = await this.prisma.stock.findUnique({ where: { symbol: symbol.toUpperCase() } });
    if (!stock) {
      throw ApiError.notFound(`Stock not found: ${symbol}`, ErrorCodes.NOT_FOUND);
    }
    let cashInserted = 0;
    let bonusInserted = 0;
    let skipped = 0;
    for (const r of rows) {
      const announcedAt = parseDateSafe(r.announcementDate) ?? new Date();
      const recordDate = parseDateSafe(r.bookCloseDate.replace(/\s*\[.*?\]\s*/g, "")) ?? null;
      const fiscalYear = normalizeFiscalYear(r.fiscalYear);
      if (!fiscalYear) {
        skipped++;
        continue;
      }
      const cashPct = parseFloat(r.cashDividend);
      const bonusPct = parseFloat(r.bonusShare);

      if (isFinite(cashPct) && cashPct > 0) {
        await this.prisma.corporateAction.upsert({
          where: { stockId_type_fiscalYear: { stockId: stock.id, type: "CASH_DIVIDEND", fiscalYear } },
          create: {
            stockId: stock.id,
            type: "CASH_DIVIDEND",
            pct: cashPct.toFixed(4),
            fiscalYear,
            recordDate,
            announcedAt,
            source: "SHARESANSAR",
          },
          update: { pct: cashPct.toFixed(4), recordDate, announcedAt },
        });
        cashInserted++;
      }
      if (isFinite(bonusPct) && bonusPct > 0) {
        await this.prisma.corporateAction.upsert({
          where: { stockId_type_fiscalYear: { stockId: stock.id, type: "BONUS_SHARE", fiscalYear } },
          create: {
            stockId: stock.id,
            type: "BONUS_SHARE",
            pct: bonusPct.toFixed(4),
            fiscalYear,
            recordDate,
            announcedAt,
            source: "SHARESANSAR",
          },
          update: { pct: bonusPct.toFixed(4), recordDate, announcedAt },
        });
        bonusInserted++;
      }
      if ((!isFinite(cashPct) || cashPct === 0) && (!isFinite(bonusPct) || bonusPct === 0)) {
        skipped++;
      }
    }
    return { cashInserted, bonusInserted, skipped };
  }

  /**
   * Sum of `cash + bonus` percent over the last `years` distinct fiscal years.
   * Powers the v0.8 Discover "Top dividend" 3-year ranking.
   */
  async totalDividendOverLastYears(stockId: string, years: number): Promise<number> {
    const rows = await this.prisma.corporateAction.findMany({
      where: { stockId, type: { in: ["CASH_DIVIDEND", "BONUS_SHARE"] } },
      orderBy: { fiscalYear: "desc" },
    });
    const byYear = new Map<string, number>();
    for (const r of rows) {
      if (!r.fiscalYear) continue;
      byYear.set(r.fiscalYear, (byYear.get(r.fiscalYear) ?? 0) + Number(r.pct ?? 0));
    }
    const sortedYears = [...byYear.keys()].sort().reverse().slice(0, years);
    return sortedYears.reduce((acc, fy) => acc + (byYear.get(fy) ?? 0), 0);
  }
}

function parseDateSafe(s: string | null | undefined): Date | null {
  if (!s) return null;
  const m = s.match(/(\d{4}-\d{2}-\d{2})/);
  if (!m) return null;
  const d = new Date(`${m[1]}T00:00:00Z`);
  return isNaN(d.getTime()) ? null : d;
}

function normalizeFiscalYear(raw: string): string | null {
  if (!raw) return null;
  // ShareSansar uses BS fiscal years like "2081/2082". Map to our schema's "081-082" format.
  const m = raw.match(/^(\d{4})\/(\d{4})$/);
  if (m) return `${m[1].slice(1)}-${m[2].slice(1)}`;
  return raw;
}

function toRow(r: {
  id: string;
  stockId: string;
  type: CorporateActionType;
  pct: { toString: () => string } | null;
  rightRatio: string | null;
  fiscalYear: string | null;
  recordDate: Date | null;
  announcedAt: Date;
  source: string;
  stock: { symbol: string };
}): CorporateActionRow {
  return {
    id: r.id,
    stockId: r.stockId,
    symbol: r.stock.symbol,
    type: r.type,
    pct: r.pct?.toString() ?? null,
    rightRatio: r.rightRatio,
    fiscalYear: r.fiscalYear,
    recordDate: r.recordDate?.toISOString() ?? null,
    announcedAt: r.announcedAt.toISOString(),
    source: r.source,
  };
}

export const corporateActionService = new CorporateActionService();
