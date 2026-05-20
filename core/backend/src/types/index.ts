import { User } from "@prisma/client";

/**
 * JWT Payload structure
 */
export interface JwtPayload {
  userId: string;
  email: string;
  deviceId?: string;
  iat?: number;
  exp?: number;
}

/**
 * User type for authenticated requests (subset of Prisma User).
 * Matches the `select` projection in auth middleware — never includes passwordHash.
 */
export type AuthUser = Pick<
  User,
  "id" | "email" | "name" | "role" | "isActive" | "emailVerified" | "avatarUrl" | "createdAt" | "updatedAt"
>;

// Re-export Fastify-based request/reply types
export type { AppRequest, AuthenticatedRequest, AppReply } from "./fastify.js";

/**
 * Pagination query parameters
 */
export interface PaginationQuery {
  page?: number;
  limit?: number;
}

/**
 * Pagination result
 */
export interface PaginationResult {
  page: number;
  limit: number;
  total: number;
  totalPages: number;
  hasNext: boolean;
  hasPrev: boolean;
}
