/**
 * Periodic cleanup of expired auth tokens.
 *
 * Fixes HIGH-9: PasswordResetToken and EmailVerificationToken rows accumulate
 * indefinitely when they expire — the auth flow creates them but never deletes
 * stale ones. Without cleanup the tables grow unbounded; in addition, used or
 * expired tokens sitting in the database are an unnecessary attack surface
 * (database breach → recoverable historical reset/verification tokens).
 *
 * Implementation: a setInterval that runs every CLEANUP_INTERVAL_MS, deleting
 * tokens whose `expiresAt < now`. The interval handle is tracked so it can be
 * cleared on graceful shutdown (mirrors the rate-limit cleanup pattern in
 * `middleware/rate-limit.middleware.ts`).
 *
 * Habituard note: when BullMQ is added (Phase 0 dep install for spaced
 * repetition / streak reminders), this can be migrated to a repeating BullMQ
 * job for unified observability. The setInterval approach is chosen here to
 * avoid adding a dependency to the starter.
 */

import { db } from "../lib/db.js";
import { logger } from "../lib/logger.js";

// Run cleanup every 6 hours. Token TTLs are 1 hour (password reset) and
// 24 hours (email verification), so 6h gives prompt removal without thrash.
const CLEANUP_INTERVAL_MS = 6 * 60 * 60 * 1000;

let cleanupHandle: NodeJS.Timeout | null = null;

export async function cleanupExpiredAuthTokens(): Promise<{
  passwordResetDeleted: number;
  emailVerificationDeleted: number;
}> {
  const now = new Date();

  const [passwordReset, emailVerification] = await Promise.all([
    db.passwordResetToken.deleteMany({
      where: {
        OR: [{ expiresAt: { lt: now } }, { used: true }],
      },
    }),
    db.emailVerificationToken.deleteMany({
      where: { expiresAt: { lt: now } },
    }),
  ]);

  const result = {
    passwordResetDeleted: passwordReset.count,
    emailVerificationDeleted: emailVerification.count,
  };

  if (result.passwordResetDeleted > 0 || result.emailVerificationDeleted > 0) {
    logger.info("[token-cleanup] Removed expired auth tokens", result);
  }

  return result;
}

export function startTokenCleanup(): void {
  if (cleanupHandle) return; // Idempotent — safe to call twice

  // Run once at boot to catch tokens that expired while the service was down.
  void cleanupExpiredAuthTokens().catch((err) => {
    logger.error("[token-cleanup] Initial cleanup failed", {
      error: err instanceof Error ? err.message : String(err),
    });
  });

  cleanupHandle = setInterval(() => {
    void cleanupExpiredAuthTokens().catch((err) => {
      logger.error("[token-cleanup] Scheduled cleanup failed", {
        error: err instanceof Error ? err.message : String(err),
      });
    });
  }, CLEANUP_INTERVAL_MS);

  // Don't keep the Node event loop alive just for this timer.
  cleanupHandle.unref();

  logger.info("[token-cleanup] Started", { intervalMs: CLEANUP_INTERVAL_MS });
}

export function stopTokenCleanup(): void {
  if (cleanupHandle) {
    clearInterval(cleanupHandle);
    cleanupHandle = null;
    logger.info("[token-cleanup] Stopped");
  }
}
