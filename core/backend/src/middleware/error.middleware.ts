import { FastifyRequest, FastifyReply, FastifyError } from "fastify";
import { ZodError } from "zod";
import { config } from "../config/index.js";
import { logger } from "../lib/logger.js";
import { errorResponse, ErrorCodes, ErrorCode } from "../utils/response.js";

/**
 * Custom error class for API errors
 */
export class ApiError extends Error {
  constructor(
    public statusCode: number,
    message: string,
    public code: string = "API_ERROR",
    public isOperational = true
  ) {
    super(message);
    this.name = "ApiError";
    Error.captureStackTrace(this, this.constructor);
  }

  static badRequest(message: string, code: ErrorCode = ErrorCodes.INVALID_INPUT): ApiError {
    return new ApiError(400, message, code);
  }

  static unauthorized(message = "Unauthorized", code: ErrorCode = ErrorCodes.AUTH_REQUIRED): ApiError {
    return new ApiError(401, message, code);
  }

  static forbidden(message = "Forbidden", code: ErrorCode = ErrorCodes.FORBIDDEN): ApiError {
    return new ApiError(403, message, code);
  }

  static notFound(message = "Not found", code: ErrorCode = ErrorCodes.NOT_FOUND): ApiError {
    return new ApiError(404, message, code);
  }

  static conflict(message: string, code: ErrorCode = ErrorCodes.CONFLICT): ApiError {
    return new ApiError(409, message, code);
  }

  static internal(message = "Internal server error", code: ErrorCode = ErrorCodes.INTERNAL_ERROR): ApiError {
    return new ApiError(500, message, code, false);
  }
}

/**
 * Fastify error handler
 */
export function errorHandler(
  err: FastifyError | Error,
  req: FastifyRequest,
  reply: FastifyReply
): void {
  const requestId = req.id;

  // Handle Zod validation errors
  if (err instanceof ZodError) {
    logger.warn("Validation error", { requestId, errors: err.errors.length });

    const details = err.errors.map((e) => ({
      field: e.path.join("."),
      message: e.message,
    }));
    const response = errorResponse(
      ErrorCodes.VALIDATION_ERROR,
      "Validation error",
      details
    );
    (response.error as { requestId?: string }).requestId = requestId;
    reply.code(400).send(response);
    return;
  }

  // Handle API errors — log 4xx as warn, 5xx as error
  if (err instanceof ApiError) {
    if (err.statusCode < 500) {
      logger.warn(`[${err.statusCode}] ${err.code}: ${err.message}`, { requestId });
    } else {
      logger.error("Server error", { requestId, message: err.message, stack: config.isDevelopment() ? err.stack : undefined });
    }
    const response = errorResponse(err.code, err.message);
    (response.error as { requestId?: string }).requestId = requestId;
    if (config.isDevelopment() && !err.isOperational) {
      (response.error as { stack?: string }).stack = err.stack;
    }
    reply.code(err.statusCode).send(response);
    return;
  }

  // Handle Prisma errors
  if (err.name === "PrismaClientKnownRequestError") {
    logger.warn("Database error", { requestId, message: err.message });
    const details = config.isDevelopment() ? err.message : undefined;
    const response = errorResponse(
      ErrorCodes.DATABASE_ERROR,
      "Database error",
      details
    );
    (response.error as { requestId?: string }).requestId = requestId;
    reply.code(400).send(response);
    return;
  }

  // Handle Fastify validation errors (schema validation)
  if ("validation" in err && (err as FastifyError).validation) {
    const response = errorResponse(
      ErrorCodes.VALIDATION_ERROR,
      err.message
    );
    (response.error as { requestId?: string }).requestId = requestId;
    reply.code(400).send(response);
    return;
  }

  // Handle unknown errors — always log with full details
  logger.error("Unhandled error", { requestId, name: err.name, message: err.message, stack: config.isDevelopment() ? err.stack : undefined });
  const message = config.isProduction() ? "Internal server error" : err.message;
  const response = errorResponse(ErrorCodes.INTERNAL_ERROR, message);
  (response.error as { requestId?: string }).requestId = requestId;
  if (config.isDevelopment()) {
    (response.error as { stack?: string }).stack = err.stack;
  }
  reply.code(500).send(response);
}
