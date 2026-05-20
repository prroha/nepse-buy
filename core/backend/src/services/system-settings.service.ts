import type { PrismaClient } from "@prisma/client";
import { db } from "../lib/db.js";

const SINGLETON_ID = "singleton";

export interface SystemSettingsRow {
  requireRegistration: boolean;
  showClaimBanner: boolean;
  updatedAt: string;
}

class SystemSettingsService {
  constructor(private readonly prisma: PrismaClient = db) {}

  /**
   * Returns the singleton settings row, creating it with defaults on first access.
   */
  async get(): Promise<SystemSettingsRow> {
    const row = await this.prisma.systemSettings.upsert({
      where: { id: SINGLETON_ID },
      create: { id: SINGLETON_ID },
      update: {},
    });
    return toRow(row);
  }

  async update(patch: { requireRegistration?: boolean; showClaimBanner?: boolean }): Promise<SystemSettingsRow> {
    await this.get(); // ensure row exists
    const row = await this.prisma.systemSettings.update({
      where: { id: SINGLETON_ID },
      data: patch,
    });
    return toRow(row);
  }

  /** Convenience — quick boolean check used in /auth/anon. */
  async isRegistrationRequired(): Promise<boolean> {
    const s = await this.get();
    return s.requireRegistration;
  }
}

function toRow(r: { requireRegistration: boolean; showClaimBanner: boolean; updatedAt: Date }): SystemSettingsRow {
  return {
    requireRegistration: r.requireRegistration,
    showClaimBanner: r.showClaimBanner,
    updatedAt: r.updatedAt.toISOString(),
  };
}

export const systemSettingsService = new SystemSettingsService();
