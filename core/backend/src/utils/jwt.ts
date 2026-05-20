import jwt, { SignOptions } from "jsonwebtoken";
import crypto from "crypto";
import { config } from "../config/index.js";

export type TokenType = "access" | "refresh";

export interface JwtPayload {
  userId: string;
  email: string;
  type: TokenType;
  deviceId?: string;
  iat?: number;
  exp?: number;
}

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

/**
 * Derive a separate signing secret for a given token type.
 * Uses HMAC-SHA256 with the base secret and token type as key material,
 * ensuring access and refresh tokens cannot be confused even if intercepted.
 */
function getSecret(type: TokenType): string {
  return crypto
    .createHmac("sha256", config.jwt.secret)
    .update(type)
    .digest("hex");
}

/**
 * Generate JWT access token
 */
export function generateAccessToken(payload: Omit<JwtPayload, "iat" | "exp" | "type">): string {
  const options: SignOptions = {
    expiresIn: config.jwt.expiresIn as jwt.SignOptions["expiresIn"],
  };
  return jwt.sign({ ...payload, type: "access" as TokenType }, getSecret("access"), options);
}

/**
 * Generate JWT refresh token (longer expiry)
 */
export function generateRefreshToken(payload: Omit<JwtPayload, "iat" | "exp" | "type">): string {
  const options: SignOptions = {
    expiresIn: config.jwt.refreshExpiresIn as jwt.SignOptions["expiresIn"],
  };
  return jwt.sign({ ...payload, type: "refresh" as TokenType }, getSecret("refresh"), options);
}

/**
 * Generate both access and refresh tokens
 */
export function generateTokenPair(payload: Omit<JwtPayload, "iat" | "exp" | "type">): TokenPair {
  const accessToken = generateAccessToken(payload);
  const refreshToken = generateRefreshToken(payload);
  const expiresIn = parseExpiry(config.jwt.expiresIn);

  return {
    accessToken,
    refreshToken,
    expiresIn,
  };
}

/**
 * Verify and decode JWT token, enforcing the expected token type.
 */
export function verifyToken(token: string, expectedType: TokenType = "access"): JwtPayload {
  try {
    const payload = jwt.verify(token, getSecret(expectedType)) as JwtPayload;

    if (payload.type !== expectedType) {
      throw new Error("Invalid token type");
    }

    return payload;
  } catch (error) {
    if (error instanceof jwt.TokenExpiredError) {
      throw new Error("Token expired");
    }
    if (error instanceof jwt.JsonWebTokenError) {
      throw new Error("Invalid token");
    }
    throw error;
  }
}

/**
 * Decode a token without verifying its signature. Returns null on parse failure.
 * Useful for inspection (e.g., reading claims from an expired token); never use
 * the returned payload for authorization.
 */
export function decodeToken(token: string): JwtPayload | null {
  try {
    const decoded = jwt.decode(token);
    if (!decoded || typeof decoded === "string") return null;
    return decoded as JwtPayload;
  } catch {
    return null;
  }
}

/**
 * Parse expiry string to seconds (e.g., "7d" -> 604800)
 */
function parseExpiry(expiry: string): number {
  const match = expiry.match(/^(\d+)([smhd])$/);
  if (!match) {
    return 3600; // Default 1 hour
  }

  const value = parseInt(match[1], 10);
  const unit = match[2];

  switch (unit) {
    case "s":
      return value;
    case "m":
      return value * 60;
    case "h":
      return value * 3600;
    case "d":
      return value * 86400;
    default:
      return 3600;
  }
}
