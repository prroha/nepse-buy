import type { PrismaClient } from "@prisma/client";
import { db } from "../lib/db.js";
import type { Prisma } from "@prisma/client";
import { ApiError } from "../middleware/error.middleware.js";
import { ErrorCodes } from "../utils/response.js";
import { DEFAULT_FEE_SCHEDULE, type BrokerageSlab, type FeeSchedule as FeeScheduleShape } from "../trades/types.js";

export interface FeeScheduleRow extends FeeScheduleShape {
  id: string;
  updatedAt: string;
}

class FeeScheduleService {
  constructor(private readonly prisma: PrismaClient = db) {}

  /**
   * Returns the user's schedule, materializing the DEFAULT on first access.
   * All trade-fee calculations call this — never query the table directly.
   */
  async getOrSeed(userId: string): Promise<FeeScheduleShape> {
    const row = await this.prisma.feeSchedule.upsert({
      where: { userId },
      create: {
        userId,
        brokerageSlabs: DEFAULT_FEE_SCHEDULE.brokerageSlabs as unknown as Prisma.InputJsonValue,
      },
      update: {},
    });
    return toShape(row);
  }

  async get(userId: string): Promise<FeeScheduleRow> {
    const shape = await this.getOrSeed(userId);
    const row = await this.prisma.feeSchedule.findUniqueOrThrow({ where: { userId } });
    return { ...shape, id: row.id, updatedAt: row.updatedAt.toISOString() };
  }

  async update(
    userId: string,
    patch: Partial<{
      brokerageSlabs: BrokerageSlab[];
      sebonRatePct: number;
      dpFlatFee: number;
      cgtShortTermPct: number;
      cgtLongTermPct: number;
      longTermDaysThreshold: number;
    }>,
  ): Promise<FeeScheduleRow> {
    await this.getOrSeed(userId);
    if (patch.brokerageSlabs && !validSlabs(patch.brokerageSlabs)) {
      throw ApiError.badRequest(
        "Brokerage slabs must be a non-empty ascending list ending with upTo:null",
        ErrorCodes.VALIDATION_ERROR,
      );
    }
    const updated = await this.prisma.feeSchedule.update({
      where: { userId },
      data: {
        ...(patch.brokerageSlabs ? { brokerageSlabs: patch.brokerageSlabs as unknown as Prisma.InputJsonValue } : {}),
        ...(patch.sebonRatePct !== undefined ? { sebonRatePct: patch.sebonRatePct } : {}),
        ...(patch.dpFlatFee !== undefined ? { dpFlatFee: patch.dpFlatFee } : {}),
        ...(patch.cgtShortTermPct !== undefined ? { cgtShortTermPct: patch.cgtShortTermPct } : {}),
        ...(patch.cgtLongTermPct !== undefined ? { cgtLongTermPct: patch.cgtLongTermPct } : {}),
        ...(patch.longTermDaysThreshold !== undefined ? { longTermDaysThreshold: patch.longTermDaysThreshold } : {}),
      },
    });
    return {
      ...toShape(updated),
      id: updated.id,
      updatedAt: updated.updatedAt.toISOString(),
    };
  }
}

function toShape(row: {
  brokerageSlabs: Prisma.JsonValue;
  sebonRatePct: Prisma.Decimal;
  dpFlatFee: Prisma.Decimal;
  cgtShortTermPct: Prisma.Decimal;
  cgtLongTermPct: Prisma.Decimal;
  longTermDaysThreshold: number;
}): FeeScheduleShape {
  return {
    brokerageSlabs: row.brokerageSlabs as unknown as BrokerageSlab[],
    sebonRatePct: Number(row.sebonRatePct),
    dpFlatFee: Number(row.dpFlatFee),
    cgtShortTermPct: Number(row.cgtShortTermPct),
    cgtLongTermPct: Number(row.cgtLongTermPct),
    longTermDaysThreshold: row.longTermDaysThreshold,
  };
}

function validSlabs(slabs: BrokerageSlab[]): boolean {
  if (slabs.length === 0) return false;
  if (slabs[slabs.length - 1].upTo !== null) return false;
  // Must be ascending (excluding the final open-ended slab)
  for (let i = 1; i < slabs.length - 1; i++) {
    const prev = slabs[i - 1].upTo;
    const curr = slabs[i].upTo;
    if (prev === null || curr === null) return false;
    if (curr <= prev) return false;
  }
  return true;
}

export const feeScheduleService = new FeeScheduleService();
