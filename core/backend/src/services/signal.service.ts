import type { PrismaClient } from "@prisma/client";
import { db } from "../lib/db.js";

export interface SignalRow {
  id: string;
  signalDate: string;
  action: string;
  season: string;
  suggestedLimit: string | null;
  rationale: string;
  engineVersion: string;
  stock: { id: string; symbol: string; name: string };
}

class SignalService {
  constructor(private readonly prisma: PrismaClient = db) {}

  /**
   * Today's signals for a user, where "today" is the date the engine evaluated
   * against. Returns at most one row per (user, stock).
   */
  async getToday(userId: string, signalDate: Date): Promise<SignalRow[]> {
    const start = atUtcMidnight(signalDate);
    const end = new Date(start.getTime() + 86_400_000 - 1);
    const rows = await this.prisma.dailySignal.findMany({
      where: { userId, signalDate: { gte: start, lte: end } },
      orderBy: [{ action: "asc" }, { stock: { symbol: "asc" } }],
      include: { stock: { select: { id: true, symbol: true, name: true } } },
    });
    return rows.map(toRow);
  }

  /**
   * Recent signal history for a (user, stock) pair, newest first.
   */
  async getHistory(userId: string, stockId: string, limit: number): Promise<SignalRow[]> {
    const rows = await this.prisma.dailySignal.findMany({
      where: { userId, stockId },
      orderBy: { signalDate: "desc" },
      take: limit,
      include: { stock: { select: { id: true, symbol: true, name: true } } },
    });
    return rows.map(toRow);
  }
}

function toRow(r: {
  id: string;
  signalDate: Date;
  action: string;
  season: string;
  suggestedLimit: { toString: () => string } | null;
  rationale: string;
  engineVersion: string;
  stock: { id: string; symbol: string; name: string };
}): SignalRow {
  return {
    id: r.id,
    signalDate: r.signalDate.toISOString().slice(0, 10),
    action: r.action,
    season: r.season,
    suggestedLimit: r.suggestedLimit?.toString() ?? null,
    rationale: r.rationale,
    engineVersion: r.engineVersion,
    stock: r.stock,
  };
}

function atUtcMidnight(d: Date): Date {
  const out = new Date(d);
  out.setUTCHours(0, 0, 0, 0);
  return out;
}

export const signalService = new SignalService();
