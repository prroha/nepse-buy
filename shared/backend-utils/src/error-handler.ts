import { FastifyRequest, FastifyReply, FastifyError } from "fastify";
import { ApiError } from "./errors.js";
import { sendError } from "./response.js";

export interface ErrorHandlerOptions {
  isDevelopment?: boolean;
  logger?: {
    warn: (msg: string, meta?: Record<string, unknown>) => void;
    error: (msg: string, meta?: Record<string, unknown>) => void;
  };
}

export function createErrorHandler(options: ErrorHandlerOptions = {}) {
  const { isDevelopment = process.env.NODE_ENV !== "production", logger } = options;

  return function errorHandler(
    err: FastifyError | Error,
    req: FastifyRequest,
    reply: FastifyReply
  ): void {
    const requestId = req.id;

    if (err instanceof ApiError) {
      if (err.statusCode < 500) {
        logger?.warn(`[${err.statusCode}] ${err.code}: ${err.message}`, { requestId });
      } else {
        logger?.error("Server error", { requestId, message: err.message, stack: isDevelopment ? err.stack : undefined });
      }
      sendError(reply, err.message, err.statusCode, err.code, err.details);
      return;
    }

    logger?.error("Unhandled error", { requestId, name: err.name, message: err.message, stack: isDevelopment ? err.stack : undefined });

    // Handle Prisma errors
    if (err.name === "PrismaClientKnownRequestError") {
      const prismaError = err as { code?: string; meta?: { target?: string[] } };
      if (prismaError.code === "P2002") {
        const targets = prismaError.meta?.target || [];
        const fieldMap: Record<string, string> = { email: "email", slug: "slug", code: "code", orderNumber: "order number" };
        const friendlyFields = (targets as string[]).map(t => fieldMap[t] || "value").join(", ");
        sendError(reply, `A record with this ${friendlyFields} already exists`, 409, "CONFLICT");
        return;
      }
      if (prismaError.code === "P2025") {
        sendError(reply, "Record not found", 404, "NOT_FOUND");
        return;
      }
    }

    // Handle Zod validation errors
    if (err.name === "ZodError") {
      const zodErr = err as unknown as { errors: Array<{ path: string[]; message: string }>; flatten: () => unknown };
      const details = zodErr.errors?.map(e => ({
        path: Array.isArray(e.path) ? e.path.join(".") : String(e.path),
        message: e.message,
      }));
      sendError(reply, "Validation failed", 400, "VALIDATION_ERROR", details);
      return;
    }

    // Handle Fastify validation errors
    if ("validation" in err && (err as FastifyError).validation) {
      sendError(reply, err.message, 400, "VALIDATION_ERROR");
      return;
    }

    const message = isDevelopment ? err.message : "Internal server error";
    sendError(reply, message, 500, "INTERNAL_ERROR");
  };
}
