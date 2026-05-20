import { FastifyRequest, FastifyReply } from "fastify";
import { AuditAction } from "@prisma/client";
import { authService, AccountLockedError } from "../services/auth.service.js";
import { emailVerificationService } from "../services/email-verification.service.js";
import { auditService } from "../services/audit.service.js";
import { successResponse, errorResponse, ErrorCodes } from "../utils/response.js";
import { z } from "zod";
import { AuthenticatedRequest } from "../types/index.js";
import { generateCsrfToken } from "../middleware/csrf.middleware.js";
import {
  setAuthCookies,
  clearAuthCookies,
  extractRefreshToken,
} from "../utils/cookies.js";
import {
  emailSchema,
  passwordSchema,
  strongPasswordSchema,
  nameSchema,
} from "../utils/validation-schemas.js";
import { ensureParam } from "../utils/controller-helpers.js";

// ============================================================================
// Validation Schemas
// ============================================================================

const registerSchema = z.object({
  email: emailSchema,
  password: passwordSchema,
  name: nameSchema.optional(),
});

const loginSchema = z.object({
  email: emailSchema,
  password: z.string().min(1, "Password is required"),
});

const refreshSchema = z.object({
  refreshToken: z.string().min(1, "Refresh token is required").optional(),
});

const changePasswordSchema = z.object({
  currentPassword: z.string().min(1, "Current password is required"),
  newPassword: strongPasswordSchema,
  confirmPassword: z.string().min(1, "Password confirmation is required"),
}).refine((data) => data.newPassword === data.confirmPassword, {
  message: "Passwords do not match",
  path: ["confirmPassword"],
});

const forgotPasswordSchema = z.object({
  email: emailSchema,
});

const resetPasswordSchema = z.object({
  token: z.string().min(1, "Reset token is required"),
  password: strongPasswordSchema,
  confirmPassword: z.string().min(1, "Password confirmation is required"),
}).refine((data) => data.password === data.confirmPassword, {
  message: "Passwords do not match",
  path: ["confirmPassword"],
});

const anonRegisterSchema = z.object({
  deviceId: z.string().max(128).optional(),
});

const claimSchema = z.object({
  email: emailSchema,
  password: strongPasswordSchema,
  name: nameSchema.optional(),
});

class AuthController {
  /**
   * Register a new user
   * POST /api/v1/auth/register
   */
  async register(req: FastifyRequest, reply: FastifyReply) {
    const validated = registerSchema.parse(req.body);
    const user = await authService.register(validated);

    // Audit log: user registration
    await auditService.log({
      action: AuditAction.CREATE,
      entity: "User",
      entityId: user.id,
      userId: user.id,
      req,
      metadata: { email: user.email },
    });

    return reply.code(201).send(successResponse(
      { user },
      "Registration successful"
    ));
  }

  /**
   * Login user
   * POST /api/v1/auth/login
   */
  async login(req: FastifyRequest, reply: FastifyReply) {
    try {
      const validated = loginSchema.parse(req.body);
      const deviceId = req.headers["x-device-id"] as string | undefined;
      const ipAddress = req.ip || req.socket?.remoteAddress;
      const userAgent = req.headers["user-agent"];

      const result = await authService.login({
        ...validated,
        deviceId,
        ipAddress,
        userAgent,
      });

      // Generate CSRF token for the session
      const csrfToken = generateCsrfToken();

      // Set authentication cookies for web clients
      setAuthCookies(reply, {
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        csrfToken,
      });

      // Audit log: successful login
      await auditService.log({
        action: AuditAction.LOGIN,
        entity: "User",
        entityId: result.user.id,
        userId: result.user.id,
        req,
        metadata: { email: result.user.email },
      });

      return reply.send(successResponse({
        user: result.user,
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        csrfToken, // Also return in body for non-browser clients
      }));
    } catch (error) {
      // Handle account lockout errors with detailed response
      if (error instanceof AccountLockedError) {
        const { lockoutStatus } = error;

        // Audit log: account locked
        await auditService.log({
          action: AuditAction.LOGIN_FAILED,
          entity: "User",
          req,
          metadata: {
            reason: "account_locked",
            email: (req.body as Record<string, unknown>)?.email,
            lockedUntil: lockoutStatus.lockedUntil?.toISOString(),
          },
        });

        return reply.code(423).send(errorResponse(
          ErrorCodes.ACCOUNT_LOCKED,
          error.message,
          {
            lockedUntil: lockoutStatus.lockedUntil?.toISOString(),
            minutesUntilUnlock: lockoutStatus.minutesUntilUnlock,
          }
        ));
      }

      // Audit log: failed login (invalid credentials)
      await auditService.log({
        action: AuditAction.LOGIN_FAILED,
        entity: "User",
        req,
        metadata: {
          reason: "invalid_credentials",
          email: (req.body as Record<string, unknown>)?.email,
        },
      });

      throw error;
    }
  }

  /**
   * Refresh access token
   * POST /api/v1/auth/refresh
   */
  async refresh(req: FastifyRequest, reply: FastifyReply) {
    const validated = refreshSchema.parse(req.body);

    // Try to get refresh token from cookie first, then body
    const refreshToken = extractRefreshToken(req) || validated.refreshToken;

    if (!refreshToken) {
      return reply.code(400).send(
        errorResponse(ErrorCodes.INVALID_INPUT, "Refresh token is required")
      );
    }

    const ipAddress = req.ip || req.socket?.remoteAddress;
    const userAgent = req.headers["user-agent"];

    const result = await authService.refreshToken({
      refreshToken,
      ipAddress,
      userAgent,
    });

    // Generate new CSRF token and set all auth cookies
    const csrfToken = generateCsrfToken();
    setAuthCookies(reply, {
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
      csrfToken,
    });

    return reply.send(successResponse({
      user: result.user,
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
      csrfToken,
    }));
  }

  /**
   * Logout user
   * POST /api/v1/auth/logout
   */
  async logout(req: FastifyRequest, reply: FastifyReply) {
    const authReq = req as AuthenticatedRequest;

    // Audit log: logout
    if (authReq.user?.userId) {
      await auditService.log({
        action: AuditAction.LOGOUT,
        entity: "Session",
        entityId: authReq.user.userId,
        userId: authReq.user.userId,
        req,
      });
    }

    // Get refresh token to invalidate session
    const refreshToken = extractRefreshToken(req);

    // Invalidate session in database
    if (refreshToken) {
      await authService.logout({ refreshToken });
    }

    // Clear all auth cookies
    clearAuthCookies(reply);

    return reply.send(successResponse(null, "Logged out successfully"));
  }

  /**
   * Get current user
   * GET /api/v1/auth/me
   */
  async me(req: FastifyRequest, reply: FastifyReply) {
    const authReq = req as AuthenticatedRequest;
    const { id, email, name, role, isActive, emailVerified, createdAt, updatedAt } = authReq.dbUser;

    return reply.send(successResponse({
      user: {
        id,
        email,
        name,
        role,
        isActive,
        emailVerified,
        createdAt,
        updatedAt,
      },
    }));
  }

  /**
   * Change user password
   * POST /api/v1/auth/change-password
   */
  async changePassword(req: FastifyRequest, reply: FastifyReply) {
    const authReq = req as AuthenticatedRequest;
    const validated = changePasswordSchema.parse(req.body);

    await authService.changePassword({
      userId: authReq.dbUser.id,
      currentPassword: validated.currentPassword,
      newPassword: validated.newPassword,
    });

    // Audit log: password change
    await auditService.log({
      action: AuditAction.PASSWORD_CHANGE,
      entity: "User",
      entityId: authReq.dbUser.id,
      userId: authReq.dbUser.id,
      req,
    });

    return reply.send(successResponse(null, "Password changed successfully"));
  }

  /**
   * Request password reset
   * POST /api/v1/auth/forgot-password
   */
  async forgotPassword(req: FastifyRequest, reply: FastifyReply) {
    const validated = forgotPasswordSchema.parse(req.body);

    await authService.forgotPassword({ email: validated.email });

    // Always return success to prevent email enumeration
    return reply.send(successResponse(
      null,
      "If an account with that email exists, we have sent a password reset link."
    ));
  }

  /**
   * Verify reset token validity
   * GET /api/v1/auth/verify-reset-token/:token
   */
  async verifyResetToken(req: FastifyRequest, reply: FastifyReply) {
    const token = (req.params as Record<string, string>).token;

    if (!ensureParam(token, reply, "Reset token")) {
      return;
    }

    const result = await authService.verifyResetToken(token);

    return reply.send(successResponse({
      valid: result.valid,
      email: result.email,
    }));
  }

  /**
   * Reset password with token
   * POST /api/v1/auth/reset-password
   */
  async resetPassword(req: FastifyRequest, reply: FastifyReply) {
    const validated = resetPasswordSchema.parse(req.body);

    const result = await authService.resetPassword({
      token: validated.token,
      password: validated.password,
    });

    // Audit log: password reset
    if (result?.userId) {
      await auditService.log({
        action: AuditAction.PASSWORD_RESET,
        entity: "User",
        entityId: result.userId,
        userId: result.userId,
        req,
      });
    }

    return reply.send(successResponse(
      null,
      "Password has been reset successfully. You can now log in with your new password."
    ));
  }

  /**
   * Verify email with token
   * GET /api/v1/auth/verify-email/:token
   */
  async verifyEmail(req: FastifyRequest, reply: FastifyReply) {
    const token = (req.params as Record<string, string>).token;

    if (!ensureParam(token, reply, "Verification token")) {
      return;
    }

    const result = await emailVerificationService.verifyEmail(token);

    return reply.send(successResponse({
      verified: result.success,
      email: result.email,
    }, "Email verified successfully"));
  }

  /**
   * Resend verification email
   * POST /api/v1/auth/send-verification
   */
  async sendVerification(req: FastifyRequest, reply: FastifyReply) {
    const authReq = req as AuthenticatedRequest;

    await emailVerificationService.resendVerificationEmail(authReq.dbUser.id);

    return reply.send(successResponse(
      null,
      "Verification email sent. Please check your inbox."
    ));
  }

  /**
   * Get all active sessions for the current user
   * GET /api/v1/auth/sessions
   */
  async getSessions(req: FastifyRequest, reply: FastifyReply) {
    const authReq = req as AuthenticatedRequest;
    const refreshToken = extractRefreshToken(req);

    const sessions = await authService.getSessions(authReq.dbUser.id, refreshToken);

    return reply.send(successResponse({ sessions }));
  }

  /**
   * Revoke a specific session
   * DELETE /api/v1/auth/sessions/:id
   */
  async revokeSession(req: FastifyRequest, reply: FastifyReply) {
    const authReq = req as AuthenticatedRequest;
    const sessionId = (req.params as Record<string, string>).id;

    if (!ensureParam(sessionId, reply, "Session ID")) {
      return;
    }

    await authService.revokeSession(authReq.dbUser.id, sessionId);

    return reply.send(successResponse(null, "Session revoked successfully"));
  }

  /**
   * Revoke all other sessions (except current)
   * DELETE /api/v1/auth/sessions
   */
  async revokeAllOtherSessions(req: FastifyRequest, reply: FastifyReply) {
    const authReq = req as AuthenticatedRequest;
    const refreshToken = extractRefreshToken(req);

    if (!ensureParam(refreshToken, reply, "Refresh token")) {
      return;
    }

    const count = await authService.revokeAllOtherSessions(authReq.dbUser.id, refreshToken);

    return reply.send(successResponse(
      { revokedCount: count },
      `${count} session${count === 1 ? "" : "s"} revoked successfully`
    ));
  }

  /**
   * Create an anonymous user — used by mobile clients on first launch so the
   * user can use the app without seeing a login wall.
   * POST /api/v1/auth/anon
   */
  async anonymousRegister(req: FastifyRequest, reply: FastifyReply) {
    const parsed = anonRegisterSchema.safeParse(req.body ?? {});
    if (!parsed.success) {
      return reply.code(400).send(errorResponse(ErrorCodes.VALIDATION_ERROR, "Invalid body", parsed.error.issues));
    }
    const result = await authService.registerAnonymous(
      parsed.data.deviceId,
      req.ip,
      req.headers["user-agent"] as string | undefined,
    );

    await auditService.log({
      action: AuditAction.CREATE,
      entity: "User",
      entityId: result.user.id,
      userId: result.user.id,
      req,
      metadata: { anon: true, deviceId: parsed.data.deviceId },
    });

    setAuthCookies(reply, { accessToken: result.accessToken, refreshToken: result.refreshToken });
    const csrfToken = generateCsrfToken();

    return reply.code(201).send(successResponse(
      {
        user: result.user,
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        csrfToken,
        sessionId: result.sessionId,
        anonymous: true,
      },
      "Anonymous account created",
    ));
  }

  /**
   * Attach email + password to the current anonymous account.
   * POST /api/v1/auth/claim  (authed)
   */
  async claimAccount(req: FastifyRequest, reply: FastifyReply) {
    const authReq = req as AuthenticatedRequest;
    if (!authReq.user?.userId) {
      return reply.code(401).send(errorResponse(ErrorCodes.AUTH_REQUIRED, "Authentication required"));
    }
    const parsed = claimSchema.safeParse(req.body);
    if (!parsed.success) {
      return reply.code(400).send(errorResponse(ErrorCodes.VALIDATION_ERROR, "Invalid body", parsed.error.issues));
    }
    await authService.claimAccount(authReq.user.userId, parsed.data);
    await auditService.log({
      action: AuditAction.UPDATE,
      entity: "User",
      entityId: authReq.user.userId,
      userId: authReq.user.userId,
      req,
      metadata: { claimed: true, newEmail: parsed.data.email },
    });
    return reply.send(successResponse({ claimed: true }, "Account claimed; please verify your email"));
  }
}

export const authController = new AuthController();
