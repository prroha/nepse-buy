import type { PrismaClient } from "@prisma/client";
import { db } from "../lib/db.js";
import { ApiError } from "../middleware/error.middleware.js";
import { ErrorCodes } from "../utils/response.js";
import type { DebtContext } from "../signals/types.js";

/** Strategy default — Rs 1L/month "salary surplus" the user wants to deploy. */
const DEFAULT_MONTHLY_SURPLUS = 100_000;

export interface DebtAccountRow {
  id: string;
  name: string;
  balance: string;
  interestRate: string;
  isActive: boolean;
  createdAt: string;
}

class DebtService {
  constructor(private readonly prisma: PrismaClient = db) {}

  async list(userId: string): Promise<DebtAccountRow[]> {
    const rows = await this.prisma.debtAccount.findMany({
      where: { userId },
      orderBy: [{ isActive: "desc" }, { balance: "desc" }],
    });
    return rows.map((r) => ({
      id: r.id,
      name: r.name,
      balance: r.balance.toString(),
      interestRate: r.interestRate.toString(),
      isActive: r.isActive,
      createdAt: r.createdAt.toISOString(),
    }));
  }

  async create(userId: string, input: { name: string; balance: string; interestRate: string }): Promise<DebtAccountRow> {
    const row = await this.prisma.debtAccount.create({
      data: { userId, name: input.name, balance: input.balance, interestRate: input.interestRate },
    });
    return {
      id: row.id,
      name: row.name,
      balance: row.balance.toString(),
      interestRate: row.interestRate.toString(),
      isActive: row.isActive,
      createdAt: row.createdAt.toISOString(),
    };
  }

  async update(
    userId: string,
    id: string,
    patch: { name?: string; balance?: string; interestRate?: string; isActive?: boolean }
  ): Promise<DebtAccountRow> {
    const existing = await this.prisma.debtAccount.findUnique({ where: { id } });
    if (!existing || existing.userId !== userId) {
      throw ApiError.notFound("Debt account not found", ErrorCodes.NOT_FOUND);
    }
    const row = await this.prisma.debtAccount.update({ where: { id }, data: patch });
    return {
      id: row.id,
      name: row.name,
      balance: row.balance.toString(),
      interestRate: row.interestRate.toString(),
      isActive: row.isActive,
      createdAt: row.createdAt.toISOString(),
    };
  }

  async remove(userId: string, id: string): Promise<void> {
    const existing = await this.prisma.debtAccount.findUnique({ where: { id } });
    if (!existing || existing.userId !== userId) {
      throw ApiError.notFound("Debt account not found", ErrorCodes.NOT_FOUND);
    }
    await this.prisma.debtAccount.delete({ where: { id } });
  }

  /**
   * Aggregate the user's active debt into a context object the signal engine consumes.
   * Returns null when the user has no active debt — engine falls back to the
   * generic "deploy to OD" rationale.
   */
  async getDebtContext(userId: string): Promise<DebtContext | null> {
    const rows = await this.prisma.debtAccount.findMany({
      where: { userId, isActive: true },
      orderBy: { balance: "desc" },
    });
    if (rows.length === 0) return null;
    let totalBalance = 0;
    let weighted = 0;
    for (const r of rows) {
      const b = Number(r.balance);
      const rate = Number(r.interestRate);
      totalBalance += b;
      weighted += b * rate;
    }
    if (totalBalance === 0) return null;
    return {
      totalBalance,
      weightedAvgRate: weighted / totalBalance,
      primaryName: rows[0].name,
      monthlySurplus: DEFAULT_MONTHLY_SURPLUS,
    };
  }
}

export const debtService = new DebtService();
