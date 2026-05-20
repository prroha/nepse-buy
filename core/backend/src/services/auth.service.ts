import bcrypt from "bcryptjs";
import crypto from "crypto";
import { PrismaClient } from "@prisma/client";
import { db } from "../lib/db.js";
import { config } from "../config/index.js";
import { generateTokenPair, verifyToken, JwtPayload } from "../utils/jwt.js";

// Dummy hash for timing-oracle prevention on non-existent users
const DUMMY_HASH = "$2a$12$000000000000000000000uGJLEcfNQJxMdOccoZYS.6Mq/pGDMK6";
import { ApiError } from "../middleware/error.middleware.js";
import { ErrorCodes } from "../utils/response.js";
import { createLockoutService, LockoutStatus } from "./lockout.service.js";
import { createSessionService } from "./session.service.js";
import { emailVerificationService } from "./email-verification.service.js";
import { emailService } from "./email.service.js";
import { systemSettingsService } from "./system-settings.service.js";
import { logger } from "../lib/logger.js";

/** Pattern for anonymous user emails. Detected via this exact prefix + suffix. */
const ANON_EMAIL_PREFIX = "anon-";
const ANON_EMAIL_DOMAIN = "@nepse-buy.local";
const ANON_PASSWORD_PLACEHOLDER = "ANON_NO_PASSWORD"; // not a valid bcrypt hash; bcrypt.compare will always reject

export function isAnonymousEmail(email: string): boolean {
  return email.startsWith(ANON_EMAIL_PREFIX) && email.endsWith(ANON_EMAIL_DOMAIN);
}

interface RegisterInput {
  email: string;
  password: string;
  name?: string;
}

interface LoginInput {
  email: string;
  password: string;
  deviceId?: string;
  ipAddress?: string;
  userAgent?: string;
}

interface LoginResult {
  user: {
    id: string;
    email: string;
    name: string | null;
    role: string;
  };
  accessToken: string;
  refreshToken: string;
  sessionId: string;
}

interface RefreshInput {
  refreshToken: string;
  ipAddress?: string;
  userAgent?: string;
}

interface RefreshResult {
  accessToken: string;
  refreshToken: string;
  user: {
    id: string;
    email: string;
    name: string | null;
    role: string;
  };
}

interface LogoutInput {
  refreshToken?: string;
}

interface ChangePasswordInput {
  userId: string;
  currentPassword: string;
  newPassword: string;
}

interface ForgotPasswordInput {
  email: string;
}

interface ResetPasswordInput {
  token: string;
  password: string;
}

interface ResetPasswordResult {
  userId: string;
  email: string;
}

interface VerifyResetTokenResult {
  valid: boolean;
  email?: string;
}

// Password reset token expiry in milliseconds (1 hour)
const RESET_TOKEN_EXPIRY_MS = 60 * 60 * 1000;

/**
 * Custom error class for account lockout
 * Includes lockout details for proper error response
 */
export class AccountLockedError extends Error {
  public lockoutStatus: LockoutStatus;

  constructor(message: string, lockoutStatus: LockoutStatus) {
    super(message);
    this.name = "AccountLockedError";
    this.lockoutStatus = lockoutStatus;
  }
}

export class AuthService {
  constructor(private db: PrismaClient) {}

  private get lockoutSvc() {
    return createLockoutService(this.db);
  }

  private get sessionSvc() {
    return createSessionService(this.db);
  }
  /**
   * Register a new user
   */
  async register(input: RegisterInput) {
    const { email, password, name } = input;

    // Check if user exists
    const existingUser = await this.db.user.findUnique({
      where: { email: email.toLowerCase() },
    });

    if (existingUser) {
      throw ApiError.conflict("Email already registered", ErrorCodes.ALREADY_EXISTS);
    }

    // Hash password
    const passwordHash = await bcrypt.hash(password, config.bcryptSaltRounds);

    // Create user with emailVerified = false
    const user = await this.db.user.create({
      data: {
        email: email.toLowerCase(),
        passwordHash,
        name,
        emailVerified: false,
      },
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        emailVerified: true,
        createdAt: true,
      },
    });

    // Send verification email
    // Email failures are intentionally non-blocking. Registration/password-reset
    // should succeed even if email delivery fails. Errors are logged for monitoring.
    try {
      await emailVerificationService.sendVerificationEmail({
        userId: user.id,
        email: user.email,
        name: user.name,
      });
    } catch (error) {
      logger.error("Failed to send verification email", { userId: user.id, error });
    }

    // Send welcome email (intentionally non-blocking — see comment above)
    try {
      await emailService.sendWelcomeEmail({
        id: user.id,
        email: user.email,
        name: user.name,
      });
    } catch (error) {
      logger.error("Failed to send welcome email", { userId: user.id, error });
    }

    // Seed curated watchlist (non-blocking — first-login UX is nice-to-have).
    try {
      const { watchlistService } = await import("./watchlist.service.js");
      const r = await watchlistService.seedCuratedForUser(user.id);
      logger.info("Seeded curated watchlist for new user", { userId: user.id, ...r });
    } catch (error) {
      logger.error("Failed to seed curated watchlist", { userId: user.id, error });
    }

    return user;
  }

  /**
   * Register an anonymous user. Mobile calls this on first launch when no
   * JWT is stored. Returns a token pair so the device proceeds normally.
   * Subject to SystemSettings.requireRegistration kill-switch.
   */
  async registerAnonymous(deviceId?: string, ipAddress?: string, userAgent?: string): Promise<LoginResult> {
    const required = await systemSettingsService.isRegistrationRequired();
    if (required) {
      throw ApiError.forbidden(
        "Anonymous registration is currently disabled — please sign up with an email.",
        ErrorCodes.FORBIDDEN,
      );
    }

    const anonId = crypto.randomUUID();
    const email = `${ANON_EMAIL_PREFIX}${anonId}${ANON_EMAIL_DOMAIN}`;

    const user = await this.db.user.create({
      data: {
        email,
        passwordHash: ANON_PASSWORD_PLACEHOLDER,
        name: null,
        emailVerified: false,
        ...(deviceId ? { activeDeviceId: deviceId } : {}),
      },
      select: { id: true, email: true, name: true, role: true },
    });

    // Seed curated watchlist so the user sees signals immediately. Best-effort.
    try {
      const { watchlistService } = await import("./watchlist.service.js");
      await watchlistService.seedCuratedForUser(user.id);
    } catch (error) {
      logger.error("Failed to seed curated watchlist for anon user", { userId: user.id, error });
    }

    const tokens = generateTokenPair({ userId: user.id, email: user.email, deviceId });
    const sessionService = createSessionService(this.db);
    const sessionId = await sessionService.createSession({
      userId: user.id,
      refreshToken: tokens.refreshToken,
      ipAddress,
      userAgent,
    });

    logger.info("Anonymous user created", { userId: user.id, deviceId });

    return {
      user: { id: user.id, email: user.email, name: user.name, role: user.role },
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      sessionId,
    };
  }

  /**
   * Attach a real email + password to an anonymous user, "claiming" the account
   * so it survives device loss / supports cross-device sync.
   * Caller must currently be authenticated as that anon user.
   */
  async claimAccount(userId: string, input: { email: string; password: string; name?: string }): Promise<void> {
    const user = await this.db.user.findUnique({ where: { id: userId } });
    if (!user) throw ApiError.notFound("User not found", ErrorCodes.USER_NOT_FOUND);
    if (!isAnonymousEmail(user.email)) {
      throw ApiError.conflict("Account already has credentials — use change-password instead.", ErrorCodes.ALREADY_EXISTS);
    }

    const newEmail = input.email.toLowerCase().trim();
    if (isAnonymousEmail(newEmail)) {
      throw ApiError.badRequest("Cannot use an internal anon email", ErrorCodes.VALIDATION_ERROR);
    }
    const conflict = await this.db.user.findUnique({ where: { email: newEmail } });
    if (conflict) {
      throw ApiError.conflict("Email already registered", ErrorCodes.ALREADY_EXISTS);
    }

    const passwordHash = await bcrypt.hash(input.password, config.bcryptSaltRounds);
    await this.db.user.update({
      where: { id: userId },
      data: {
        email: newEmail,
        passwordHash,
        name: input.name ?? user.name,
        emailVerified: false,
      },
    });

    try {
      await emailVerificationService.sendVerificationEmail({ userId, email: newEmail, name: input.name ?? user.name });
    } catch (error) {
      logger.error("Failed to send verification email on claim", { userId, error });
    }
    logger.info("Anonymous account claimed", { userId, newEmail });
  }

  /**
   * Login user with email and password
   * Includes brute force protection via account lockout
   */
  async login(input: LoginInput): Promise<LoginResult> {
    const { email, password, deviceId, ipAddress, userAgent } = input;

    // Find user with lockout fields
    const user = await this.db.user.findUnique({
      where: { email: email.toLowerCase() },
    });

    if (!user) {
      // Timing oracle prevention: always run bcrypt.compare even for non-existent users
      // so the response time is indistinguishable from a wrong-password attempt
      await bcrypt.compare(password, DUMMY_HASH);
      throw ApiError.unauthorized("Invalid credentials", ErrorCodes.INVALID_CREDENTIALS);
    }

    // Check if account is locked out (before password check to prevent timing attacks)
    const lockoutStatus = this.lockoutSvc.getLockoutStatus(user);
    if (lockoutStatus.isLocked) {
      throw new AccountLockedError(
        `Account is locked. Try again in ${lockoutStatus.minutesUntilUnlock} minutes.`,
        lockoutStatus
      );
    }

    // Check if active
    if (!user.isActive) {
      throw ApiError.forbidden("Account is deactivated", ErrorCodes.FORBIDDEN);
    }

    // Verify password (bcrypt.compare is constant-time to prevent timing attacks)
    const isValidPassword = await bcrypt.compare(password, user.passwordHash);
    if (!isValidPassword) {
      // Record failed attempt and possibly lock the account
      const newLockoutStatus = await this.lockoutSvc.recordFailedAttempt(user.id, user.email);

      if (newLockoutStatus.isLocked) {
        throw new AccountLockedError(
          `Account is now locked due to too many failed attempts. Try again in ${newLockoutStatus.minutesUntilUnlock} minutes.`,
          newLockoutStatus
        );
      }

      throw ApiError.unauthorized("Invalid credentials", ErrorCodes.INVALID_CREDENTIALS);
    }

    // Generate tokens (not a DB operation, stays outside transaction)
    const tokens = generateTokenPair({
      userId: user.id,
      email: user.email,
      deviceId,
    });

    // Wrap DB operations in a transaction to ensure atomicity:
    // lockout reset, device update, and session creation
    const sessionId = await this.db.$transaction(async (tx) => {
      // Reset failed attempts and update active device
      await tx.user.update({
        where: { id: user.id },
        data: {
          failedLoginAttempts: 0,
          lockedUntil: null,
          lastFailedLogin: null,
          ...(deviceId ? { activeDeviceId: deviceId } : {}),
        },
      });

      // Create session within the same transaction
      const sid = await this.sessionSvc.createSession({
        userId: user.id,
        refreshToken: tokens.refreshToken,
        ipAddress,
        userAgent,
      }, tx);

      return sid;
    });

    return {
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
      },
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      sessionId,
    };
  }

  /**
   * Change user password
   * Requires current password verification for security
   */
  async changePassword(input: ChangePasswordInput): Promise<void> {
    const { userId, currentPassword, newPassword } = input;

    // Find user
    const user = await this.db.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw ApiError.notFound("User not found", ErrorCodes.USER_NOT_FOUND);
    }

    // Verify current password
    const isValidPassword = await bcrypt.compare(currentPassword, user.passwordHash);
    if (!isValidPassword) {
      throw ApiError.unauthorized("Current password is incorrect", ErrorCodes.INVALID_CREDENTIALS);
    }

    // Check if new password is same as current
    const isSamePassword = await bcrypt.compare(newPassword, user.passwordHash);
    if (isSamePassword) {
      throw ApiError.badRequest("New password must be different from current password", ErrorCodes.INVALID_INPUT);
    }

    // Hash new password
    const newPasswordHash = await bcrypt.hash(newPassword, config.bcryptSaltRounds);

    // Update password
    await this.db.user.update({
      where: { id: userId },
      data: { passwordHash: newPasswordHash },
    });

    // Send password changed notification email
    // Email failures are intentionally non-blocking. Password change should
    // succeed even if email delivery fails. Errors are logged for monitoring.
    try {
      await emailService.sendPasswordChangedEmail({
        id: user.id,
        email: user.email,
        name: user.name,
      });
    } catch (error) {
      logger.error("Failed to send password changed email", { userId: user.id, error });
    }

    logger.info("Password changed successfully", { userId });
  }

  /**
   * Refresh access token using a valid refresh token
   */
  async refreshToken(input: RefreshInput): Promise<RefreshResult> {
    const { refreshToken } = input;

    // Verify the refresh token — enforce "refresh" type
    let payload: JwtPayload;
    try {
      payload = verifyToken(refreshToken, "refresh");
    } catch (error) {
      const message = error instanceof Error ? error.message : "Invalid token";
      if (message.includes("expired")) {
        throw ApiError.unauthorized("Refresh token expired", ErrorCodes.TOKEN_EXPIRED);
      }
      throw ApiError.unauthorized("Invalid refresh token", ErrorCodes.INVALID_TOKEN);
    }

    // Check if session exists and is valid
    const session = await this.sessionSvc.findSessionByRefreshToken(refreshToken);
    if (!session) {
      // If no session found, the refresh token may have been rotated already
      // (replay attack). Revoke all sessions for this user as a safety measure.
      await this.sessionSvc.deleteAllUserSessions(payload.userId);
      logger.security("Refresh token reuse detected — all sessions revoked", { userId: payload.userId });
      throw ApiError.unauthorized("Session not found or expired", ErrorCodes.INVALID_TOKEN);
    }

    // Find the user
    const user = await this.db.user.findUnique({
      where: { id: payload.userId },
    });

    if (!user) {
      throw ApiError.unauthorized("User not found", ErrorCodes.USER_NOT_FOUND);
    }

    // Check if user is active
    if (!user.isActive) {
      throw ApiError.forbidden("Account is deactivated", ErrorCodes.FORBIDDEN);
    }

    // Generate new token pair
    const tokens = generateTokenPair({
      userId: user.id,
      email: user.email,
      deviceId: payload.deviceId,
    });

    // Rotate: update the session with the new refresh token hash
    await this.sessionSvc.rotateRefreshToken(refreshToken, tokens.refreshToken);

    return {
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
      },
    };
  }

  /**
   * Logout user and invalidate session
   */
  async logout(input: LogoutInput): Promise<void> {
    const { refreshToken } = input;

    if (refreshToken) {
      await this.sessionSvc.deleteSessionByRefreshToken(refreshToken);
    }
  }

  /**
   * Get all active sessions for a user
   */
  async getSessions(userId: string, currentRefreshToken?: string) {
    return this.sessionSvc.getUserSessions(userId, currentRefreshToken);
  }

  /**
   * Revoke a specific session
   */
  async revokeSession(userId: string, sessionId: string): Promise<void> {
    await this.sessionSvc.revokeSession(userId, sessionId);
  }

  /**
   * Revoke all sessions except current
   */
  async revokeAllOtherSessions(userId: string, currentRefreshToken: string): Promise<number> {
    return this.sessionSvc.revokeAllOtherSessions(userId, currentRefreshToken);
  }

  /**
   * Generate a secure password reset token
   * Returns a URL-safe random token
   */
  private generateSecureToken(): string {
    return crypto.randomBytes(32).toString("hex");
  }

  /**
   * Request a password reset
   * Generates a token and sends email (or logs to console in dev)
   */
  async forgotPassword(input: ForgotPasswordInput): Promise<void> {
    const { email } = input;

    // Find user by email
    const user = await this.db.user.findUnique({
      where: { email: email.toLowerCase() },
    });

    // Always return success to prevent email enumeration attacks
    // But only create token and send email if user exists
    if (!user) {
      logger.info("Forgot password requested for non-existent email", { email });
      return;
    }

    // Check if account is active
    if (!user.isActive) {
      logger.info("Forgot password requested for deactivated account", { email });
      return;
    }

    // Invalidate any existing unused reset tokens for this user
    await this.db.passwordResetToken.updateMany({
      where: {
        userId: user.id,
        used: false,
      },
      data: {
        used: true,
      },
    });

    // Generate new token and store its SHA-256 hash (not plaintext)
    const token = this.generateSecureToken();
    const tokenHash = this.hashResetToken(token);
    const expiresAt = new Date(Date.now() + RESET_TOKEN_EXPIRY_MS);

    // Save hashed token to database
    await this.db.passwordResetToken.create({
      data: {
        userId: user.id,
        token: tokenHash,
        expiresAt,
      },
    });

    // Send the raw token to the user via email (only they have the plaintext)
    await this.sendResetEmail(user.email, token, user.name, user.id);

    logger.info("Password reset token generated", { userId: user.id, email: user.email });
  }

  /**
   * Send password reset email using the email service
   */
  private async sendResetEmail(email: string, token: string, name: string | null, userId: string): Promise<void> {
    const expiresInMinutes = RESET_TOKEN_EXPIRY_MS / 60000;

    await emailService.sendPasswordResetEmail(
      { id: userId, email, name },
      token,
      expiresInMinutes
    );
  }

  /**
   * Hash a password reset token for database lookup
   */
  private hashResetToken(token: string): string {
    return crypto.createHash("sha256").update(token).digest("hex");
  }

  /**
   * Verify if a reset token is valid
   */
  async verifyResetToken(token: string): Promise<VerifyResetTokenResult> {
    const tokenHash = this.hashResetToken(token);
    const resetToken = await this.db.passwordResetToken.findUnique({
      where: { token: tokenHash },
      include: { user: true },
    });

    if (!resetToken) {
      return { valid: false };
    }

    // Check if token is already used
    if (resetToken.used) {
      return { valid: false };
    }

    // Check if token is expired
    if (new Date() > resetToken.expiresAt) {
      return { valid: false };
    }

    return {
      valid: true,
      email: resetToken.user.email,
    };
  }

  /**
   * Reset password using a valid token
   */
  async resetPassword(input: ResetPasswordInput): Promise<ResetPasswordResult> {
    const { token, password } = input;

    // Find and validate token (hash before lookup)
    const tokenHash = this.hashResetToken(token);
    const resetToken = await this.db.passwordResetToken.findUnique({
      where: { token: tokenHash },
      include: { user: true },
    });

    if (!resetToken) {
      throw ApiError.badRequest("Invalid or expired reset token", ErrorCodes.INVALID_TOKEN);
    }

    if (resetToken.used) {
      throw ApiError.badRequest("This reset link has already been used", ErrorCodes.INVALID_TOKEN);
    }

    if (new Date() > resetToken.expiresAt) {
      throw ApiError.badRequest("This reset link has expired. Please request a new one.", ErrorCodes.TOKEN_EXPIRED);
    }

    // Check if user is active
    if (!resetToken.user.isActive) {
      throw ApiError.forbidden("Account is deactivated", ErrorCodes.FORBIDDEN);
    }

    // Hash new password
    const passwordHash = await bcrypt.hash(password, config.bcryptSaltRounds);

    // Update password and mark token as used in a transaction
    await this.db.$transaction([
      this.db.user.update({
        where: { id: resetToken.userId },
        data: { passwordHash },
      }),
      this.db.passwordResetToken.update({
        where: { id: resetToken.id },
        data: { used: true },
      }),
    ]);

    // Reset any lockout on the account
    await this.lockoutSvc.resetFailedAttempts(resetToken.userId);

    // Send password changed notification email
    // Email failures are intentionally non-blocking. Password reset should
    // succeed even if email delivery fails. Errors are logged for monitoring.
    try {
      await emailService.sendPasswordChangedEmail({
        id: resetToken.userId,
        email: resetToken.user.email,
        name: resetToken.user.name,
      });
    } catch (error) {
      logger.error("Failed to send password changed email", { userId: resetToken.userId, error });
    }

    logger.info("Password reset successful", { userId: resetToken.userId, email: resetToken.user.email });

    return {
      userId: resetToken.userId,
      email: resetToken.user.email,
    };
  }
}

export const authService = new AuthService(db);

export function createAuthService(injectedDb: PrismaClient) {
  return new AuthService(injectedDb);
}
