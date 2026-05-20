export class ApiError extends Error {
  public readonly statusCode: number;
  public readonly code: string;
  public readonly details?: unknown;
  public readonly isOperational: boolean;

  constructor(
    message: string,
    statusCode = 400,
    code = "API_ERROR",
    details?: unknown,
    isOperational = true
  ) {
    super(message);
    this.name = "ApiError";
    this.statusCode = statusCode;
    this.code = code;
    this.details = details;
    this.isOperational = isOperational;
    Error.captureStackTrace(this, this.constructor);
  }

  static badRequest(message: string, code = "BAD_REQUEST", details?: unknown): ApiError {
    return new ApiError(message, 400, code, details);
  }

  static unauthorized(message = "Unauthorized", code = "UNAUTHORIZED"): ApiError {
    return new ApiError(message, 401, code);
  }

  static forbidden(message = "Forbidden", code = "FORBIDDEN"): ApiError {
    return new ApiError(message, 403, code);
  }

  static notFound(resource = "Resource"): ApiError {
    return new ApiError(`${resource} not found`, 404, "NOT_FOUND");
  }

  static conflict(message: string): ApiError {
    return new ApiError(message, 409, "CONFLICT");
  }

  static tooManyRequests(message = "Too many requests"): ApiError {
    return new ApiError(message, 429, "TOO_MANY_REQUESTS");
  }

  static internal(message = "Internal server error"): ApiError {
    return new ApiError(message, 500, "INTERNAL_ERROR", undefined, false);
  }

  static validation(details: unknown): ApiError {
    return new ApiError("Validation failed", 400, "VALIDATION_ERROR", details);
  }
}
