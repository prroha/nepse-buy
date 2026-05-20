import crypto from "crypto";
import { db } from "../lib/db.js";
import { ApiError } from "../middleware/error.middleware.js";
import { ErrorCodes } from "../utils/response.js";
import { emailService } from "./email.service.js";
import { logger } from "../lib/logger.js";

// Email verification token expiry in milliseconds (24 hours)
const VERIFICATION_TOKEN_EXPIRY_MS = 24 * 60 * 60 * 1000;

interface SendVerificationEmailInput {
  userId: string;
  email: string;
  name?: string | null;
}

interface VerifyEmailResult {
  success: boolean;
  userId: string;
  email: string;
}

class EmailVerificationService {
  /**
   * Generate a secure verification token
   * Returns a URL-safe random token (64 hex characters)
   */
  private generateSecureToken(): string {
    return crypto.randomBytes(32).toString("hex");
  }

  /**
   * Create and send a verification email
   * This should be called after user registration
   */
  async sendVerificationEmail(input: SendVerificationEmailInput): Promise<void> {
    const { userId, email, name } = input;

    // Invalidate any existing unused verification tokens for this user
    await db.emailVerificationToken.deleteMany({
      where: { userId },
    });

    // Generate new token
    const token = this.generateSecureToken();
    const expiresAt = new Date(Date.now() + VERIFICATION_TOKEN_EXPIRY_MS);

    // Save token to database
    await db.emailVerificationToken.create({
      data: {
        userId,
        token,
        expiresAt,
      },
    });

    // Send verification email
    await this.sendEmail(email, token, name ?? null, userId);

    logger.info("Email verification token generated", { userId, email });
  }

  /**
   * Send verification email using the email service
   */
  private async sendEmail(email: string, token: string, name: string | null, userId: string): Promise<void> {
    const expiresInHours = VERIFICATION_TOKEN_EXPIRY_MS / (60 * 60 * 1000);

    await emailService.sendEmailVerificationEmail(
      { id: userId, email, name },
      token,
      expiresInHours
    );
  }

  /**
   * Verify email with token
   * Returns user info if successful
   */
  async verifyEmail(token: string): Promise<VerifyEmailResult> {
    // Find the verification token
    const verificationToken = await db.emailVerificationToken.findUnique({
      where: { token },
      include: { user: true },
    });

    if (!verificationToken) {
      throw ApiError.badRequest("Invalid verification token", ErrorCodes.INVALID_TOKEN);
    }

    // Check if token is expired
    if (new Date() > verificationToken.expiresAt) {
      // Clean up expired token
      await db.emailVerificationToken.delete({
        where: { id: verificationToken.id },
      });
      throw ApiError.badRequest("Verification link has expired. Please request a new one.", ErrorCodes.TOKEN_EXPIRED);
    }

    // Check if user is already verified
    if (verificationToken.user.emailVerified) {
      // Clean up token
      await db.emailVerificationToken.delete({
        where: { id: verificationToken.id },
      });
      throw ApiError.badRequest("Email is already verified", ErrorCodes.ALREADY_EXISTS);
    }

    // Update user and delete token in a transaction
    await db.$transaction([
      db.user.update({
        where: { id: verificationToken.userId },
        data: { emailVerified: true },
      }),
      db.emailVerificationToken.delete({
        where: { id: verificationToken.id },
      }),
    ]);

    logger.info("Email verified successfully", {
      userId: verificationToken.userId,
      email: verificationToken.user.email,
    });

    return {
      success: true,
      userId: verificationToken.userId,
      email: verificationToken.user.email,
    };
  }

  /**
   * Resend verification email
   * For users who didn't receive the original email
   */
  async resendVerificationEmail(userId: string): Promise<void> {
    // Find user
    const user = await db.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw ApiError.notFound("User not found", ErrorCodes.USER_NOT_FOUND);
    }

    // Check if already verified
    if (user.emailVerified) {
      throw ApiError.badRequest("Email is already verified", ErrorCodes.ALREADY_EXISTS);
    }

    // Check if user is active
    if (!user.isActive) {
      throw ApiError.forbidden("Account is deactivated", ErrorCodes.FORBIDDEN);
    }

    // Send new verification email
    await this.sendVerificationEmail({
      userId: user.id,
      email: user.email,
      name: user.name,
    });
  }

  /**
   * Check verification token validity without consuming it
   */
  async checkTokenValidity(token: string): Promise<{ valid: boolean; email?: string }> {
    const verificationToken = await db.emailVerificationToken.findUnique({
      where: { token },
      include: { user: true },
    });

    if (!verificationToken) {
      return { valid: false };
    }

    // Check if token is expired
    if (new Date() > verificationToken.expiresAt) {
      return { valid: false };
    }

    // Check if user is already verified
    if (verificationToken.user.emailVerified) {
      return { valid: false };
    }

    return {
      valid: true,
      email: verificationToken.user.email,
    };
  }
}

export const emailVerificationService = new EmailVerificationService();
