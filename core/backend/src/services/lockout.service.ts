/**
 * Account Lockout Service
 *
 * Provides brute force protection by locking accounts after repeated failed login attempts.
 * This is a CORE security feature available to all tiers.
 */

import { PrismaClient } from "@prisma/client";
import { User } from "@prisma/client";
import { db } from "../lib/db.js";
import { logger } from "../lib/logger.js";

// Lockout configuration
const MAX_FAILED_ATTEMPTS = 5;
const LOCKOUT_DURATION_MINUTES = 15;

export interface LockoutStatus {
  isLocked: boolean;
  lockedUntil: Date | null;
  remainingAttempts: number;
  minutesUntilUnlock: number | null;
}

export class LockoutService {
  constructor(private db: PrismaClient) {}
  /**
   * Check if a user account is currently locked out
   */
  isLockedOut(user: Pick<User, "lockedUntil">): boolean {
    if (!user.lockedUntil) {
      return false;
    }
    return user.lockedUntil > new Date();
  }

  /**
   * Get the lockout status for a user
   */
  getLockoutStatus(
    user: Pick<User, "failedLoginAttempts" | "lockedUntil">
  ): LockoutStatus {
    const isLocked = this.isLockedOut(user);
    const remainingAttempts = Math.max(
      0,
      MAX_FAILED_ATTEMPTS - user.failedLoginAttempts
    );

    let minutesUntilUnlock: number | null = null;
    if (isLocked && user.lockedUntil) {
      const msUntilUnlock = user.lockedUntil.getTime() - Date.now();
      minutesUntilUnlock = Math.ceil(msUntilUnlock / (1000 * 60));
    }

    return {
      isLocked,
      lockedUntil: user.lockedUntil,
      remainingAttempts,
      minutesUntilUnlock,
    };
  }

  /**
   * Check lockout status for a user by ID
   * Throws if user is locked out
   */
  async checkLockout(userId: string): Promise<LockoutStatus> {
    const user = await this.db.user.findUnique({
      where: { id: userId },
      select: {
        failedLoginAttempts: true,
        lockedUntil: true,
      },
    });

    if (!user) {
      // Return default status for non-existent users (don't reveal user existence)
      return {
        isLocked: false,
        lockedUntil: null,
        remainingAttempts: MAX_FAILED_ATTEMPTS,
        minutesUntilUnlock: null,
      };
    }

    return this.getLockoutStatus(user);
  }

  /**
   * Record a failed login attempt
   * Locks the account if threshold is reached
   */
  async recordFailedAttempt(userId: string, email: string): Promise<LockoutStatus> {
    // Use atomic increment to avoid race condition with concurrent login attempts
    const updatedUser = await this.db.user.update({
      where: { id: userId },
      data: {
        failedLoginAttempts: { increment: 1 },
        lastFailedLogin: new Date(),
      },
      select: {
        failedLoginAttempts: true,
        lockedUntil: true,
      },
    }).catch(() => null);

    if (!updatedUser) {
      return {
        isLocked: false,
        lockedUntil: null,
        remainingAttempts: MAX_FAILED_ATTEMPTS,
        minutesUntilUnlock: null,
      };
    }

    const newFailedAttempts = updatedUser.failedLoginAttempts;
    const shouldLock = newFailedAttempts >= MAX_FAILED_ATTEMPTS;

    if (shouldLock) {
      const lockedUntil = new Date(
        Date.now() + LOCKOUT_DURATION_MINUTES * 60 * 1000
      );

      await this.db.user.update({
        where: { id: userId },
        data: { lockedUntil },
      });

      updatedUser.lockedUntil = lockedUntil;

      // Security log: Account locked
      logger.security("Account locked due to repeated failed login attempts", {
        userId,
        email,
        failedAttempts: newFailedAttempts,
        lockedUntil: lockedUntil.toISOString(),
        lockoutDurationMinutes: LOCKOUT_DURATION_MINUTES,
      });
    } else {
      // Security log: Failed login attempt
      logger.security("Failed login attempt", {
        userId,
        email,
        failedAttempts: newFailedAttempts,
        remainingAttempts: MAX_FAILED_ATTEMPTS - newFailedAttempts,
      });
    }

    return this.getLockoutStatus(updatedUser);
  }

  /**
   * Reset failed login attempts on successful login
   */
  async resetFailedAttempts(userId: string): Promise<void> {
    const user = await this.db.user.findUnique({
      where: { id: userId },
      select: {
        failedLoginAttempts: true,
        lockedUntil: true,
      },
    });

    // Only update if there were previous failed attempts
    if (user && (user.failedLoginAttempts > 0 || user.lockedUntil)) {
      await this.db.user.update({
        where: { id: userId },
        data: {
          failedLoginAttempts: 0,
          lockedUntil: null,
          lastFailedLogin: null,
        },
      });

      logger.security("Failed login attempts reset after successful login", {
        userId,
        previousFailedAttempts: user.failedLoginAttempts,
      });
    }
  }

  /**
   * Clear lockout on password reset
   * Should be called when user resets their password
   */
  async clearLockoutOnPasswordReset(userId: string): Promise<void> {
    const user = await this.db.user.findUnique({
      where: { id: userId },
      select: {
        failedLoginAttempts: true,
        lockedUntil: true,
        email: true,
      },
    });

    if (user && (user.failedLoginAttempts > 0 || user.lockedUntil)) {
      await this.db.user.update({
        where: { id: userId },
        data: {
          failedLoginAttempts: 0,
          lockedUntil: null,
          lastFailedLogin: null,
        },
      });

      logger.security("Account lockout cleared due to password reset", {
        userId,
        email: user.email,
        wasLocked: !!user.lockedUntil,
        previousFailedAttempts: user.failedLoginAttempts,
      });
    }
  }

  /**
   * Get lockout configuration (for documentation/API responses)
   */
  getConfig() {
    return {
      maxFailedAttempts: MAX_FAILED_ATTEMPTS,
      lockoutDurationMinutes: LOCKOUT_DURATION_MINUTES,
    };
  }
}

export const lockoutService = new LockoutService(db);

export function createLockoutService(injectedDb: PrismaClient) {
  return new LockoutService(injectedDb);
}
