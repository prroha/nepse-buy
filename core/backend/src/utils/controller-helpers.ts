/**
 * Controller Helper Utilities
 *
 * Reusable utilities for controller operations to reduce code duplication.
 * Provides common patterns for validation, pagination, exports, and error handling.
 */

import { FastifyReply } from "fastify";
import { z, ZodSchema, ZodError } from "zod";
import { AppRequest, AuthenticatedRequest } from "../types/index.js";
import { errorResponse, ErrorCodes } from "./response.js";
import { exportService, CsvColumn } from "../services/export.service.js";

// ============================================================================
// Validation Helpers
// ============================================================================

/**
 * Result of a safe validation operation
 */
export interface SafeValidationResult<T> {
  success: boolean;
  data?: T;
  error?: ZodError;
}

/**
 * Safely validate request body with a Zod schema
 */
export function safeValidate<T>(
  schema: ZodSchema<T>,
  data: unknown
): SafeValidationResult<T> {
  const result = schema.safeParse(data);
  if (result.success) {
    return { success: true, data: result.data };
  }
  return { success: false, error: result.error };
}

/**
 * Validate and send error response if validation fails
 */
export function validateOrRespond<T>(
  schema: ZodSchema<T>,
  data: unknown,
  reply: FastifyReply
): T | null {
  const result = schema.safeParse(data);
  if (!result.success) {
    reply.code(400).send(
      errorResponse(
        ErrorCodes.VALIDATION_ERROR,
        "Invalid input",
        result.error.flatten()
      )
    );
    return null;
  }
  return result.data;
}

// ============================================================================
// Common Parameter Validation Schemas
// ============================================================================

export const paginationQuerySchema = z.object({
  page: z.coerce.number().int().positive().optional().default(1),
  limit: z.coerce.number().int().positive().max(100).optional().default(20),
});

export function createSortSchema<T extends readonly [string, ...string[]]>(
  sortByOptions: T,
  defaultSortBy: T[number] = "createdAt"
) {
  return z.object({
    sortBy: z.enum(sortByOptions).optional().default(defaultSortBy),
    sortOrder: z.enum(["asc", "desc"]).optional().default("desc"),
  });
}

// ============================================================================
// Pagination Helpers
// ============================================================================

export interface PaginationParams {
  skip: number;
  take: number;
  page: number;
  limit: number;
}

export function calculatePagination(page: number, limit: number): PaginationParams {
  const sanitizedPage = Math.max(1, page);
  const sanitizedLimit = Math.min(100, Math.max(1, limit));
  return {
    skip: (sanitizedPage - 1) * sanitizedLimit,
    take: sanitizedLimit,
    page: sanitizedPage,
    limit: sanitizedLimit,
  };
}

export function getPaginationFromQuery(query: {
  page?: string | number;
  limit?: string | number;
}): PaginationParams {
  const page = typeof query.page === "string" ? parseInt(query.page, 10) : (query.page ?? 1);
  const limit = typeof query.limit === "string" ? parseInt(query.limit, 10) : (query.limit ?? 20);
  return calculatePagination(page, limit);
}

// ============================================================================
// Resource Existence Helpers
// ============================================================================

export function sendNotFound(reply: FastifyReply, resourceName: string): void {
  reply.code(404).send(
    errorResponse(ErrorCodes.NOT_FOUND, `${resourceName} not found`)
  );
}

export function sendMissingParam(reply: FastifyReply, paramName: string): void {
  reply.code(400).send(
    errorResponse(ErrorCodes.VALIDATION_ERROR, `${paramName} is required`)
  );
}

export function sendConflict(reply: FastifyReply, message: string): void {
  reply.code(409).send(errorResponse(ErrorCodes.CONFLICT, message));
}

export function ensureExists<T>(
  resource: T | null | undefined,
  reply: FastifyReply,
  resourceName: string
): resource is T {
  if (!resource) {
    sendNotFound(reply, resourceName);
    return false;
  }
  return true;
}

export function ensureParam(
  param: string | undefined | null,
  reply: FastifyReply,
  paramName: string
): param is string {
  if (!param) {
    sendMissingParam(reply, paramName);
    return false;
  }
  return true;
}

// ============================================================================
// CSV Export Helpers
// ============================================================================

export interface CsvExportOptions {
  filenamePrefix: string;
  includeTimestamp?: boolean;
}

export function sendCsvExport<T>(
  reply: FastifyReply,
  data: T[],
  columns: CsvColumn<T>[],
  options: CsvExportOptions
): void {
  const timestamp = options.includeTimestamp !== false
    ? `-${new Date().toISOString().split("T")[0]}`
    : "";
  const filename = `${options.filenamePrefix}${timestamp}.csv`;

  const csv = exportService.exportToCsv(data, columns);

  reply.header("Content-Type", "text/csv; charset=utf-8");
  reply.header("Content-Disposition", `attachment; filename="${filename}"`);
  reply.send(csv);
}

// ============================================================================
// Request Context Helpers
// ============================================================================

export function getAuthUser(req: AppRequest): AuthenticatedRequest["dbUser"] {
  if (!req.dbUser) {
    throw new Error("User not authenticated");
  }
  return req.dbUser;
}

export function getAuthUserId(req: AppRequest): string {
  return getAuthUser(req).id;
}

export function getUserIdFromToken(req: AppRequest): string | undefined {
  return req.user?.userId;
}

// ============================================================================
// Type Guards
// ============================================================================

export function isAuthenticatedRequest(req: AppRequest): req is AuthenticatedRequest {
  return !!req.user && !!req.dbUser;
}
