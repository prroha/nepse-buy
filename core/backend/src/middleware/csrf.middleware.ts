import { FastifyRequest, FastifyReply } from "fastify";
import crypto from "crypto";
import { logger } from "../lib/logger.js";

/**
 * CSRF Error Codes
 */
export const CsrfErrorCodes = {
  CSRF_TOKEN_MISSING: "CSRF_TOKEN_MISSING",
  CSRF_TOKEN_INVALID: "CSRF_TOKEN_INVALID",
} as const;

/**
 * Generate a cryptographically secure CSRF token
 */
export function generateCsrfToken(): string {
  return crypto.randomBytes(32).toString("hex");
}

/**
 * Methods that require CSRF protection (state-changing operations)
 */
const PROTECTED_METHODS = ["POST", "PUT", "PATCH", "DELETE"];

/**
 * Paths that are exempt from CSRF validation
 */
const CSRF_EXEMPT_PATHS = [
  "/api/v1/auth/login",
  "/api/v1/auth/register",
  "/api/v1/auth/refresh",
  "/api/v1/auth/logout",
  "/health",
  "/api/v1/webhooks",
];

/**
 * Check if the request path is exempt from CSRF validation
 */
function isExemptPath(path: string): boolean {
  return CSRF_EXEMPT_PATHS.some((exemptPath) => {
    return path === exemptPath || path.startsWith(`${exemptPath}/`);
  });
}

/**
 * Extract CSRF token from request
 */
function extractCsrfToken(req: FastifyRequest): string | undefined {
  const headerToken =
    req.headers["x-csrf-token"] ||
    req.headers["x-xsrf-token"] ||
    req.headers["csrf-token"];

  if (typeof headerToken === "string" && headerToken.length > 0) {
    return headerToken;
  }

  const body = req.body as Record<string, unknown> | undefined;
  if (body && typeof body._csrf === "string") {
    return body._csrf;
  }

  return undefined;
}

/**
 * Get CSRF token from cookie
 */
function getCsrfTokenFromCookie(req: FastifyRequest): string | undefined {
  return req.cookies?.csrfToken;
}

/**
 * CSRF Protection Hook (Fastify onRequest)
 */
export async function csrfProtection(
  req: FastifyRequest,
  reply: FastifyReply
): Promise<void> {
  // Skip CSRF check for safe methods (GET, HEAD, OPTIONS)
  if (!PROTECTED_METHODS.includes(req.method)) {
    return;
  }

  // Skip CSRF check for exempt paths
  if (isExemptPath(req.url)) {
    return;
  }

  // Get the token from the cookie (set during login)
  const cookieToken = getCsrfTokenFromCookie(req);

  // Get the token from the request (header or body)
  const requestToken = extractCsrfToken(req);

  // Validate tokens exist
  if (!cookieToken || !requestToken) {
    logger.warn("CSRF token missing", {
      path: req.url,
      method: req.method,
      hasCookieToken: !!cookieToken,
      hasRequestToken: !!requestToken,
    });

    return reply.code(403).send({
      success: false,
      error: {
        code: CsrfErrorCodes.CSRF_TOKEN_MISSING,
        message: "CSRF token is required",
      },
    });
  }

  // Use timing-safe comparison to prevent timing attacks
  const cookieTokenBuffer = Buffer.from(cookieToken);
  const requestTokenBuffer = Buffer.from(requestToken);

  if (
    cookieTokenBuffer.length !== requestTokenBuffer.length ||
    !crypto.timingSafeEqual(cookieTokenBuffer, requestTokenBuffer)
  ) {
    logger.warn("CSRF token mismatch", {
      path: req.url,
      method: req.method,
    });

    return reply.code(403).send({
      success: false,
      error: {
        code: CsrfErrorCodes.CSRF_TOKEN_INVALID,
        message: "Invalid CSRF token",
      },
    });
  }

  // Store token on request for potential use
  req.csrfToken = cookieToken;
}

