/**
 * Shared Validation Schemas
 *
 * Centralized Zod schemas for common validation patterns.
 * Import these to ensure consistent validation across the application.
 */

import { z } from "zod";

// ============================================================================
// Common Field Schemas
// ============================================================================

/**
 * Email field with proper validation
 */
export const emailSchema = z.string().email("Invalid email format");

/**
 * Password with minimum requirements
 */
export const passwordSchema = z
  .string()
  .min(8, "Password must be at least 8 characters");

/**
 * Strong password with complexity requirements
 */
export const strongPasswordSchema = z
  .string()
  .min(8, "Password must be at least 8 characters")
  .regex(
    /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/,
    "Password must contain at least one uppercase letter, one lowercase letter, and one number"
  );

/**
 * Name field with reasonable constraints
 */
export const nameSchema = z
  .string()
  .min(1, "Name cannot be empty")
  .max(100, "Name must be less than 100 characters");

/**
 * Name with only alphabetic characters, spaces, hyphens, and apostrophes
 */
export const strictNameSchema = nameSchema.regex(
  /^[a-zA-Z\s'-]+$/,
  "Name can only contain letters, spaces, hyphens, and apostrophes"
);

/**
 * Slug field (lowercase letters, numbers, and hyphens)
 */
export const slugSchema = z
  .string()
  .min(1, "Slug is required")
  .max(100, "Slug must be less than 100 characters")
  .regex(/^[a-z0-9-]+$/, "Slug can only contain lowercase letters, numbers, and hyphens");

/**
 * UUID field
 */
export const uuidSchema = z.string().uuid("Invalid ID format");

/**
 * Optional UUID field (nullable)
 */
export const optionalUuidSchema = z.string().uuid().nullable().optional();

// ============================================================================
// Pagination Schemas
// ============================================================================

/**
 * Base pagination query parameters
 */
export const paginationSchema = z.object({
  page: z.coerce.number().int().positive().optional().default(1),
  limit: z.coerce.number().int().positive().max(100).optional().default(20),
});

/**
 * Extended pagination with search
 */
export const searchablePaginationSchema = paginationSchema.extend({
  search: z.string().optional(),
});

/**
 * Pagination with common sort options
 */
export const sortablePaginationSchema = paginationSchema.extend({
  sortBy: z.enum(["createdAt", "updatedAt"]).optional().default("createdAt"),
  sortOrder: z.enum(["asc", "desc"]).optional().default("desc"),
});

// ============================================================================
// Filter Schemas
// ============================================================================

/**
 * Boolean string filter (for query params)
 */
export const booleanFilterSchema = z
  .enum(["true", "false"])
  .optional()
  .transform((val) => (val === undefined ? undefined : val === "true"));

/**
 * Date range filter
 */
export const dateRangeSchema = z.object({
  startDate: z.string().datetime().optional(),
  endDate: z.string().datetime().optional(),
});

/**
 * Active status filter (for admin interfaces)
 */
export const activeFilterSchema = z.object({
  isActive: booleanFilterSchema,
});

// ============================================================================
// Schema Helpers
// ============================================================================

/**
 * Create a password confirmation schema that validates password match
 */
export function createPasswordConfirmSchema<T extends string>(
  passwordField: T,
  confirmField: string = "confirmPassword"
) {
  return z
    .object({
      [passwordField]: strongPasswordSchema,
      [confirmField]: z.string().min(1, "Password confirmation is required"),
    })
    .refine(
      (data) => data[passwordField] === data[confirmField],
      {
        message: "Passwords do not match",
        path: [confirmField],
      }
    );
}

/**
 * Create a schema for entities with order/sort fields
 */
export const orderableSchema = z.object({
  order: z.number().int().optional(),
});

/**
 * Create a schema for publishable/activatable entities
 */
export const publishableSchema = z.object({
  isActive: z.boolean().optional(),
});

// ============================================================================
// Common Entity Schemas
// ============================================================================

/**
 * Base schema for date-bounded entities (e.g., coupons, announcements)
 */
export const dateBoundedSchema = z.object({
  validFrom: z.string().datetime().nullable().optional(),
  validUntil: z.string().datetime().nullable().optional(),
});

/**
 * Convert date strings to Date objects (for use after validation)
 */
export function parseDateBounds(data: {
  validFrom?: string | null;
  validUntil?: string | null;
}): { validFrom?: Date | null; validUntil?: Date | null } {
  return {
    validFrom: data.validFrom ? new Date(data.validFrom) : null,
    validUntil: data.validUntil ? new Date(data.validUntil) : null,
  };
}

// ============================================================================
// SEO/Meta Schemas
// ============================================================================

/**
 * SEO metadata fields
 */
export const seoMetaSchema = z.object({
  metaTitle: z.string().max(60, "Meta title must be less than 60 characters").nullable().optional(),
  metaDesc: z.string().max(160, "Meta description must be less than 160 characters").nullable().optional(),
});
