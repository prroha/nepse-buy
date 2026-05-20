import { FastifyRequest, FastifyReply } from "fastify";
import { verifyToken, JwtPayload } from "../utils/jwt.js";
import { db } from "../lib/db.js";
import { UserRole } from "@prisma/client";
import { logger } from "../lib/logger.js";
import { AppRequest, AuthenticatedRequest } from "../types/index.js";

// Re-export AuthenticatedRequest for backwards compatibility
export type { AuthenticatedRequest } from "../types/index.js";

/**
 * Error codes for authentication failures
 */
export const AuthErrorCodes = {
  AUTH_REQUIRED: "AUTH_REQUIRED",
  INVALID_AUTH_FORMAT: "INVALID_AUTH_FORMAT",
  TOKEN_MISSING: "TOKEN_MISSING",
  INVALID_TOKEN: "INVALID_TOKEN",
  TOKEN_EXPIRED: "TOKEN_EXPIRED",
  USER_NOT_FOUND: "USER_NOT_FOUND",
  USER_DEACTIVATED: "USER_DEACTIVATED",
  ADMIN_REQUIRED: "ADMIN_REQUIRED",
} as const;

interface AuthErrorResponse {
  success: false;
  error: {
    code: keyof typeof AuthErrorCodes;
    message: string;
  };
}

/**
 * Send auth error directly via reply instead of throwing ApiError.
 *
 * Auth middleware intentionally bypasses the global error handler to:
 * 1. Return structured auth-specific error codes (AUTH_REQUIRED, TOKEN_EXPIRED, etc.)
 *    that clients rely on for token refresh and redirect logic.
 * 2. Avoid the overhead of exception creation and stack trace capture on every
 *    unauthenticated request, which is a hot path.
 * 3. Keep auth error formatting self-contained and predictable regardless of
 *    changes to the global error handler.
 */
function sendAuthError(
  reply: FastifyReply,
  status: number,
  message: string,
  code: keyof typeof AuthErrorCodes
): void {
  const response: AuthErrorResponse = {
    success: false,
    error: {
      code,
      message,
    },
  };
  reply.code(status).send(response);
}

/**
 * Extract bearer token from authorization header
 */
function extractBearerToken(authHeader: string | undefined): string | null {
  if (!authHeader) return null;

  const parts = authHeader.split(" ");
  if (parts.length !== 2) return null;

  const [scheme, token] = parts;
  if (scheme.toLowerCase() !== "bearer") return null;

  return token || null;
}

/**
 * Extract access token from request (cookie or header)
 */
function extractAccessToken(req: FastifyRequest): string | null {
  // First, try httpOnly cookie
  const cookieToken = req.cookies?.accessToken;
  if (cookieToken) return cookieToken;

  // Fallback to Authorization header
  return extractBearerToken(req.headers.authorization);
}

/**
 * Authentication middleware - requires valid JWT token
 */
export async function authMiddleware(
  req: FastifyRequest,
  reply: FastifyReply
): Promise<void> {
  try {
    const token = extractAccessToken(req);

    if (!token || token.trim() === "") {
      sendAuthError(reply, 401, "Authentication required", "AUTH_REQUIRED");
      return;
    }

    let payload: JwtPayload;
    try {
      payload = verifyToken(token, "access");
    } catch (error) {
      const message = error instanceof Error ? error.message : "Invalid token";

      if (message.includes("expired")) {
        sendAuthError(reply, 401, "Token expired", "TOKEN_EXPIRED");
      } else {
        sendAuthError(reply, 401, "Invalid token", "INVALID_TOKEN");
      }
      return;
    }

    const dbClient = (req as FastifyRequest & { db?: typeof db }).db ?? db;
    const user = await dbClient.user.findUnique({
      where: { id: payload.userId },
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        isActive: true,
        emailVerified: true,
        avatarUrl: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    if (!user) {
      sendAuthError(reply, 401, "User not found", "USER_NOT_FOUND");
      return;
    }

    if (!user.isActive) {
      sendAuthError(
        reply,
        403,
        "Your account has been deactivated. Please contact support.",
        "USER_DEACTIVATED"
      );
      return;
    }

    // Attach user info to request
    req.user = payload;
    req.dbUser = user;
  } catch (error) {
    logger.error("Auth middleware error", {
      error: error instanceof Error ? error.message : "Unknown error",
    });
    sendAuthError(reply, 401, "Authentication failed", "INVALID_TOKEN");
  }
}

/**
 * Admin middleware - requires ADMIN or SUPER_ADMIN role
 * Must be used AFTER authMiddleware
 */
export async function adminMiddleware(
  req: FastifyRequest,
  reply: FastifyReply
): Promise<void> {
  if (!req.user || !req.dbUser) {
    sendAuthError(reply, 401, "Authentication required", "AUTH_REQUIRED");
    return;
  }

  const role = req.dbUser.role;
  if (role !== UserRole.ADMIN && role !== UserRole.SUPER_ADMIN) {
    sendAuthError(reply, 403, "Admin access required", "ADMIN_REQUIRED");
    return;
  }
}

/**
 * Super admin middleware - requires SUPER_ADMIN role only
 * Must be used AFTER authMiddleware
 */
export async function superAdminMiddleware(
  req: FastifyRequest,
  reply: FastifyReply
): Promise<void> {
  if (!req.user || !req.dbUser) {
    sendAuthError(reply, 401, "Authentication required", "AUTH_REQUIRED");
    return;
  }

  if (req.dbUser.role !== UserRole.SUPER_ADMIN) {
    sendAuthError(reply, 403, "Super admin access required", "ADMIN_REQUIRED");
    return;
  }
}

/**
 * Optional authentication middleware
 * Attempts to authenticate but doesn't fail if no token
 */
export async function optionalAuthMiddleware(
  req: FastifyRequest
): Promise<void> {
  try {
    const token = extractAccessToken(req);

    if (!token) {
      return;
    }

    let payload: JwtPayload;
    try {
      payload = verifyToken(token, "access");
    } catch {
      return;
    }

    const dbClient = (req as FastifyRequest & { db?: typeof db }).db ?? db;
    const user = await dbClient.user.findUnique({
      where: { id: payload.userId },
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        isActive: true,
        emailVerified: true,
        avatarUrl: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    if (!user || !user.isActive) {
      return;
    }

    req.user = payload;
    req.dbUser = user;
  } catch (error) {
    logger.warn("Optional auth middleware error", {
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
}

/**
 * Helper to check if request is authenticated
 */
export function isAuthenticated(req: AppRequest): req is AuthenticatedRequest {
  return !!req.user && !!req.dbUser;
}

/**
 * Helper to get authenticated user from request
 */
export function getAuthenticatedUser(req: AppRequest): {
  payload: JwtPayload;
  user: AuthenticatedRequest["dbUser"];
} {
  if (!req.user || !req.dbUser) {
    throw new Error("User not authenticated");
  }

  return {
    payload: req.user,
    user: req.dbUser,
  };
}
