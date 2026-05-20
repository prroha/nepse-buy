/**
 * Cookie Configuration Utilities
 *
 * Centralized cookie settings and helper functions.
 * Ensures consistent cookie configuration across the application.
 */

import { FastifyReply } from "fastify";
import type { CookieSerializeOptions } from "@fastify/cookie";

// ============================================================================
// Cookie Durations (in seconds for Fastify)
// ============================================================================

export const COOKIE_DURATIONS = {
  /** Access token: 7 days (in seconds) */
  ACCESS_TOKEN: 7 * 24 * 60 * 60,
  /** Refresh token: 30 days (in seconds) */
  REFRESH_TOKEN: 30 * 24 * 60 * 60,
  /** CSRF token: 7 days (in seconds) */
  CSRF_TOKEN: 7 * 24 * 60 * 60,
} as const;

// ============================================================================
// Cookie Names
// ============================================================================

export const COOKIE_NAMES = {
  ACCESS_TOKEN: "accessToken",
  REFRESH_TOKEN: "refreshToken",
  CSRF_TOKEN: "csrfToken",
} as const;

// ============================================================================
// Base Cookie Options
// ============================================================================

const isProduction = process.env.NODE_ENV === "production";

/**
 * Base options for HTTP-only cookies (access and refresh tokens)
 */
export const httpOnlyCookieOptions: CookieSerializeOptions = {
  httpOnly: true,
  secure: isProduction,
  sameSite: "lax",
  path: "/",
};

/**
 * Options for access token cookie
 */
export const accessTokenCookieOptions: CookieSerializeOptions = {
  ...httpOnlyCookieOptions,
  maxAge: COOKIE_DURATIONS.ACCESS_TOKEN,
};

/**
 * Options for refresh token cookie
 */
export const refreshTokenCookieOptions: CookieSerializeOptions = {
  ...httpOnlyCookieOptions,
  maxAge: COOKIE_DURATIONS.REFRESH_TOKEN,
};

/**
 * Options for CSRF token cookie (readable by JavaScript)
 */
export const csrfTokenCookieOptions: CookieSerializeOptions = {
  httpOnly: false, // Must be readable by JS to send in header
  secure: isProduction,
  sameSite: "strict",
  maxAge: COOKIE_DURATIONS.CSRF_TOKEN,
  path: "/",
};

// ============================================================================
// Cookie Helper Functions
// ============================================================================

/**
 * Auth tokens that can be set on response
 */
export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  csrfToken?: string;
}

/**
 * Set all authentication cookies on response
 */
export function setAuthCookies(reply: FastifyReply, tokens: AuthTokens): void {
  reply.setCookie(COOKIE_NAMES.ACCESS_TOKEN, tokens.accessToken, accessTokenCookieOptions);
  reply.setCookie(COOKIE_NAMES.REFRESH_TOKEN, tokens.refreshToken, refreshTokenCookieOptions);

  if (tokens.csrfToken) {
    reply.setCookie(COOKIE_NAMES.CSRF_TOKEN, tokens.csrfToken, csrfTokenCookieOptions);
  }
}

/**
 * Clear all authentication cookies
 */
export function clearAuthCookies(reply: FastifyReply): void {
  reply.clearCookie(COOKIE_NAMES.ACCESS_TOKEN, { path: "/" });
  reply.clearCookie(COOKIE_NAMES.REFRESH_TOKEN, { path: "/" });
  reply.clearCookie(COOKIE_NAMES.CSRF_TOKEN, { path: "/" });
}

/**
 * Extract refresh token from request (cookie or body)
 */
export function extractRefreshToken(req: {
  cookies?: { refreshToken?: string };
  body?: { refreshToken?: string } | unknown;
}): string | undefined {
  const cookieToken = req.cookies?.refreshToken;
  if (cookieToken) return cookieToken;

  const body = req.body as { refreshToken?: string } | undefined;
  return body?.refreshToken;
}
