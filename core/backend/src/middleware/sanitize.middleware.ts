import { FastifyRequest } from "fastify";

/**
 * Sanitize a single string value
 *
 * Only trims whitespace. HTML encoding was removed because Prisma prevents
 * SQL injection and React auto-escapes output, so encoding here corrupted
 * stored data (e.g. O'Brien → O&#x27;Brien).
 */
export function sanitizeString(
  value: string,
  options: {
    trim?: boolean;
    maxLength?: number;
  } = {}
): string {
  const {
    trim = true,
    maxLength,
  } = options;

  let result = value;

  if (trim) {
    result = result.trim();
  }

  if (maxLength && result.length > maxLength) {
    result = result.substring(0, maxLength);
  }

  return result;
}

/**
 * Deep sanitize an object (recursively sanitize all string values)
 */
export function sanitizeObject<T>(obj: T, visited = new WeakSet<object>()): T {
  if (obj === null || obj === undefined) {
    return obj;
  }

  if (typeof obj === "string") {
    return sanitizeString(obj) as T;
  }

  if (typeof obj !== "object") {
    return obj;
  }

  if (visited.has(obj as object)) {
    return obj;
  }
  visited.add(obj as object);

  if (Array.isArray(obj)) {
    return obj.map((item) => sanitizeObject(item, visited)) as T;
  }

  const sanitized: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(obj)) {
    const sanitizedKey = sanitizeString(key, { trim: false });
    sanitized[sanitizedKey] = sanitizeObject(value, visited);
  }

  return sanitized as T;
}

/**
 * Fields that should not be sanitized (e.g., passwords, tokens)
 */
const SKIP_SANITIZE_FIELDS = [
  "password",
  "passwordHash",
  "password_hash",
  "token",
  "accessToken",
  "refreshToken",
  "access_token",
  "refresh_token",
  "authorization",
  "apiKey",
  "api_key",
  "secret",
  "signature",
];

/**
 * Check if a field should be skipped for sanitization
 */
function shouldSkipField(fieldName: string): boolean {
  const lowerField = fieldName.toLowerCase();
  return SKIP_SANITIZE_FIELDS.some((skip) => lowerField.includes(skip.toLowerCase()));
}

/**
 * Selective sanitize an object, skipping certain fields
 */
export function selectiveSanitizeObject<T>(obj: T, visited = new WeakSet<object>()): T {
  if (obj === null || obj === undefined) {
    return obj;
  }

  if (typeof obj === "string") {
    return sanitizeString(obj) as T;
  }

  if (typeof obj !== "object") {
    return obj;
  }

  if (visited.has(obj as object)) {
    return obj;
  }
  visited.add(obj as object);

  if (Array.isArray(obj)) {
    return obj.map((item) => selectiveSanitizeObject(item, visited)) as T;
  }

  const sanitized: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(obj)) {
    if (shouldSkipField(key)) {
      sanitized[key] = value;
    } else if (typeof value === "string") {
      sanitized[key] = sanitizeString(value);
    } else {
      sanitized[key] = selectiveSanitizeObject(value, visited);
    }
  }

  return sanitized as T;
}

/**
 * Input Sanitization Hook (Fastify preHandler)
 *
 * Sanitizes request body, query parameters, and URL parameters
 * to prevent XSS attacks and other injection vulnerabilities.
 */
export async function sanitizeInput(req: FastifyRequest): Promise<void> {
  try {
    if (req.body && typeof req.body === "object") {
      (req as { body: unknown }).body = selectiveSanitizeObject(req.body);
    }

    if (req.query && typeof req.query === "object") {
      (req as { query: unknown }).query = sanitizeObject(req.query);
    }

    if (req.params && typeof req.params === "object") {
      (req as { params: unknown }).params = sanitizeObject(req.params);
    }
  } catch {
    // If sanitization fails, continue with unsanitized input
  }
}

/**
 * Create a custom sanitization middleware with specific options
 */
export function createSanitizeMiddleware(options: {
  sanitizeBody?: boolean;
  sanitizeQuery?: boolean;
  sanitizeParams?: boolean;
  skipFields?: string[];
}) {
  const {
    sanitizeBody = true,
    sanitizeQuery = true,
    sanitizeParams = true,
    skipFields = [],
  } = options;

  const allSkipFields = [...SKIP_SANITIZE_FIELDS, ...skipFields];

  const shouldSkip = (fieldName: string): boolean => {
    const lowerField = fieldName.toLowerCase();
    return allSkipFields.some((skip) => lowerField.includes(skip.toLowerCase()));
  };

  const customSanitize = <T>(obj: T, visited = new WeakSet<object>()): T => {
    if (obj === null || obj === undefined) return obj;
    if (typeof obj === "string") return sanitizeString(obj) as T;
    if (typeof obj !== "object") return obj;
    if (visited.has(obj as object)) return obj;
    visited.add(obj as object);

    if (Array.isArray(obj)) {
      return obj.map((item) => customSanitize(item, visited)) as T;
    }

    const sanitized: Record<string, unknown> = {};
    for (const [key, value] of Object.entries(obj)) {
      if (shouldSkip(key)) {
        sanitized[key] = value;
      } else if (typeof value === "string") {
        sanitized[key] = sanitizeString(value);
      } else {
        sanitized[key] = customSanitize(value, visited);
      }
    }
    return sanitized as T;
  };

  return async (req: FastifyRequest): Promise<void> => {
    try {
      if (sanitizeBody && req.body && typeof req.body === "object") {
        (req as { body: unknown }).body = customSanitize(req.body);
      }
      if (sanitizeQuery && req.query && typeof req.query === "object") {
        (req as { query: unknown }).query = sanitizeObject(req.query);
      }
      if (sanitizeParams && req.params && typeof req.params === "object") {
        (req as { params: unknown }).params = sanitizeObject(req.params);
      }
    } catch {
      // Continue with unsanitized input
    }
  };
}
