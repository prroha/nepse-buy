import type { PrismaClient } from "@prisma/client";
import { db } from "../lib/db.js";
import { logger } from "../lib/logger.js";
import { emailService } from "../services/email.service.js";
import type { DigestSignalRow } from "../email/templates/daily-signal-digest.template.js";

const DIGEST_FREQUENCY_DAILY = "daily";

export interface DispatchResult {
  usersConsidered: number;
  emailsSent: number;
  emailsFailed: number;
  inAppRowsCreated: number;
}

/**
 * Build and dispatch the daily-signal digest for every active user with at
 * least one signal on `signalDate`. Both an email (Resend) and an in-app
 * Notification row are produced per user. Each delivery is audited via
 * NotificationDelivery rows.
 *
 * Respects per-user `emailOptIn` and `emailDigestFrequency`. v1 honors
 * `daily` only; weekly digest is a future enhancement.
 */
export class NotificationDispatcher {
  constructor(private readonly prisma: PrismaClient = db) {}

  async dispatchDailyDigests(signalDate: Date): Promise<DispatchResult> {
    const startOfDay = atUtcMidnight(signalDate);
    const endOfDay = new Date(startOfDay.getTime() + 86_400_000 - 1);

    const signals = await this.prisma.dailySignal.findMany({
      where: { signalDate: { gte: startOfDay, lte: endOfDay } },
      include: {
        user: { select: { id: true, email: true, name: true, emailOptIn: true, emailDigestFrequency: true } },
        stock: { select: { symbol: true, name: true } },
      },
    });

    // Group by user
    const byUser = new Map<string, typeof signals>();
    for (const s of signals) {
      const arr = byUser.get(s.userId) ?? [];
      arr.push(s);
      byUser.set(s.userId, arr);
    }

    const result: DispatchResult = {
      usersConsidered: byUser.size,
      emailsSent: 0,
      emailsFailed: 0,
      inAppRowsCreated: 0,
    };

    for (const [userId, userSignals] of byUser) {
      const user = userSignals[0].user;
      if (!user) continue;

      // In-app notification rows are written regardless of email opt-in
      const summary = summarize(userSignals);
      await this.prisma.notification.create({
        data: {
          userId,
          type: "SIGNAL",
          title: `Today's NEPSE signals — ${summary.buyCount} buy / ${summary.waitCount} wait / ${summary.skipCount} skip`,
          message: summary.shortMessage,
          data: { signalIds: userSignals.map((s) => s.id), summary } as object,
        },
      });
      result.inAppRowsCreated += 1;

      // Email: only if opted in + daily frequency
      if (!user.emailOptIn || user.emailDigestFrequency !== DIGEST_FREQUENCY_DAILY) continue;

      const rows: DigestSignalRow[] = userSignals.map((s) => ({
        symbol: s.stock.symbol,
        name: s.stock.name,
        action: s.action,
        closeNpr: readClose(s.inputsSnapshot) ?? "—",
        suggestedLimitNpr: s.suggestedLimit?.toString() ?? null,
        rationale: s.rationale,
      }));

      const sendResult = await emailService.sendDailySignalDigest(user.email, {
        recipientName: user.name,
        signalDate: signalDate.toISOString().slice(0, 10),
        rows,
      });

      const status = sendResult.success ? "SENT" : "FAILED";
      await this.prisma.notificationDelivery.create({
        data: {
          userId,
          channel: "EMAIL",
          status,
          providerId: sendResult.messageId,
          error: sendResult.error,
          sentAt: sendResult.success ? new Date() : null,
        },
      });
      if (sendResult.success) result.emailsSent += 1;
      else result.emailsFailed += 1;
    }

    logger.info("Daily digest dispatch complete", { ...result });
    return result;
  }
}

function summarize(signals: { action: string; stock: { symbol: string } }[]): {
  buyCount: number;
  waitCount: number;
  skipCount: number;
  shortMessage: string;
} {
  const buyCount = signals.filter((s) => s.action === "BUY").length;
  const waitCount = signals.filter((s) => s.action === "WAIT").length;
  const skipCount = signals.filter((s) => s.action === "SKIP").length;
  const buys = signals.filter((s) => s.action === "BUY").map((s) => s.stock.symbol).slice(0, 5);
  const shortMessage =
    buyCount === 0
      ? "No buy signals today — check back tomorrow."
      : `Buy candidates: ${buys.join(", ")}${buyCount > buys.length ? "…" : ""}`;
  return { buyCount, waitCount, skipCount, shortMessage };
}

function readClose(snapshot: unknown): string | null {
  if (!snapshot || typeof snapshot !== "object") return null;
  const v = (snapshot as Record<string, unknown>).close;
  return typeof v === "string" ? v : null;
}

function atUtcMidnight(d: Date): Date {
  const out = new Date(d);
  out.setUTCHours(0, 0, 0, 0);
  return out;
}
