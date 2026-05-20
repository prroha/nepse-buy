/**
 * Response Helper Utilities
 *
 * Provides standardized error response formatting for API endpoints.
 */

export interface SuccessResponse<T> {
  success: true;
  data: T;
  message?: string;
}

export interface ErrorResponseBody {
  success: false;
  error: {
    code: string;
    message: string;
    details?: unknown;
  };
}

export interface PaginatedResponse<T> {
  success: true;
  data: {
    items: T[];
    pagination: {
      page: number;
      limit: number;
      total: number;
      totalPages: number;
      hasNext: boolean;
      hasPrev: boolean;
    };
  };
}

/**
 * Create a success response
 */
export const successResponse = <T>(data: T, message?: string): SuccessResponse<T> => {
  return {
    success: true,
    data,
    ...(message && { message }),
  };
};

/**
 * Create a paginated response
 */
export const paginatedResponse = <T>(
  items: T[],
  page: number,
  limit: number,
  total: number
): PaginatedResponse<T> => {
  const totalPages = Math.ceil(total / limit);
  return {
    success: true,
    data: {
      items,
      pagination: {
        page,
        limit,
        total,
        totalPages,
        hasNext: page < totalPages,
        hasPrev: page > 1,
      },
    },
  };
};

/**
 * Create an error response
 */
export const errorResponse = (
  code: string,
  message: string,
  details?: unknown
): ErrorResponseBody => {
  const response: ErrorResponseBody = {
    success: false,
    error: {
      code,
      message,
    },
  };

  if (details !== undefined) {
    response.error.details = details;
  }

  return response;
};

/**
 * Common error codes for API responses
 */
export const ErrorCodes = {
  // Authentication errors
  AUTH_REQUIRED: "AUTH_REQUIRED",
  TOKEN_EXPIRED: "TOKEN_EXPIRED",
  TOKEN_INVALID: "TOKEN_INVALID",
  INVALID_TOKEN: "INVALID_TOKEN",
  TOKEN_MISSING: "TOKEN_MISSING",
  INVALID_CREDENTIALS: "INVALID_CREDENTIALS",
  USER_NOT_FOUND: "USER_NOT_FOUND",
  ACCOUNT_LOCKED: "ACCOUNT_LOCKED",
  PASSWORD_CHANGE_FAILED: "PASSWORD_CHANGE_FAILED",

  // Authorization errors
  FORBIDDEN: "FORBIDDEN",
  INSUFFICIENT_PERMISSIONS: "INSUFFICIENT_PERMISSIONS",

  // Validation errors
  VALIDATION_ERROR: "VALIDATION_ERROR",
  INVALID_INPUT: "INVALID_INPUT",

  // Resource errors
  NOT_FOUND: "NOT_FOUND",
  ALREADY_EXISTS: "ALREADY_EXISTS",
  CONFLICT: "CONFLICT",

  // Server errors
  INTERNAL_ERROR: "INTERNAL_ERROR",
  DATABASE_ERROR: "DATABASE_ERROR",
  SERVICE_UNAVAILABLE: "SERVICE_UNAVAILABLE",

  // Rate limiting
  RATE_LIMIT_EXCEEDED: "RATE_LIMIT_EXCEEDED",
  AUTH_RATE_LIMIT_EXCEEDED: "AUTH_RATE_LIMIT_EXCEEDED",
  USER_RATE_LIMIT_EXCEEDED: "USER_RATE_LIMIT_EXCEEDED",
  SENSITIVE_RATE_LIMIT_EXCEEDED: "SENSITIVE_RATE_LIMIT_EXCEEDED",
  API_RATE_LIMIT_EXCEEDED: "API_RATE_LIMIT_EXCEEDED",

  // CSRF errors
  CSRF_TOKEN_MISSING: "CSRF_TOKEN_MISSING",
  CSRF_TOKEN_INVALID: "CSRF_TOKEN_INVALID",
} as const;

export type ErrorCode = (typeof ErrorCodes)[keyof typeof ErrorCodes];
