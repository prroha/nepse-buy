import { describe, it, expect, vi } from "vitest";
import { FastifyRequest, FastifyReply } from "fastify";
import { ZodError, ZodIssue } from "zod";
import { ApiError, errorHandler } from "../../middleware/error.middleware.js";
import { ErrorCodes } from "../../utils/response.js";

// Mock dependencies
vi.mock("../../lib/logger.js", () => ({
  logger: {
    warn: vi.fn(),
    error: vi.fn(),
  },
}));

vi.mock("../../config/index.js", () => ({
  config: {
    nodeEnv: "test",
    isDevelopment: () => false,
    isProduction: () => false,
    isTest: () => true,
  },
}));

function createMockReq(): FastifyRequest {
  return { id: "req-123" } as FastifyRequest;
}

function createMockReply(): FastifyReply {
  const reply = {
    code: vi.fn().mockReturnThis(),
    send: vi.fn().mockReturnThis(),
  } as unknown as FastifyReply;
  return reply;
}

describe("ApiError", () => {
  describe("static factories", () => {
    it("badRequest() returns 400 with INVALID_INPUT code", () => {
      const err = ApiError.badRequest("Bad input");
      expect(err.statusCode).toBe(400);
      expect(err.code).toBe(ErrorCodes.INVALID_INPUT);
      expect(err.message).toBe("Bad input");
      expect(err.isOperational).toBe(true);
    });

    it("unauthorized() returns 401 with AUTH_REQUIRED code", () => {
      const err = ApiError.unauthorized();
      expect(err.statusCode).toBe(401);
      expect(err.code).toBe(ErrorCodes.AUTH_REQUIRED);
      expect(err.message).toBe("Unauthorized");
    });

    it("forbidden() returns 403 with FORBIDDEN code", () => {
      const err = ApiError.forbidden();
      expect(err.statusCode).toBe(403);
      expect(err.code).toBe(ErrorCodes.FORBIDDEN);
    });

    it("notFound() returns 404 with NOT_FOUND code", () => {
      const err = ApiError.notFound("User not found");
      expect(err.statusCode).toBe(404);
      expect(err.code).toBe(ErrorCodes.NOT_FOUND);
      expect(err.message).toBe("User not found");
    });

    it("conflict() returns 409 with CONFLICT code", () => {
      const err = ApiError.conflict("Already exists");
      expect(err.statusCode).toBe(409);
      expect(err.code).toBe(ErrorCodes.CONFLICT);
    });

    it("internal() returns 500 with INTERNAL_ERROR code and isOperational=false", () => {
      const err = ApiError.internal();
      expect(err.statusCode).toBe(500);
      expect(err.code).toBe(ErrorCodes.INTERNAL_ERROR);
      expect(err.isOperational).toBe(false);
    });
  });

  it("allows custom error codes", () => {
    const err = ApiError.badRequest("Invalid email", ErrorCodes.VALIDATION_ERROR);
    expect(err.code).toBe("VALIDATION_ERROR");
  });
});

describe("errorHandler", () => {
  it("handles ZodError with 400 status and field details", () => {
    const issues: ZodIssue[] = [
      {
        code: "too_small",
        minimum: 1,
        type: "string",
        inclusive: true,
        exact: false,
        message: "Email is required",
        path: ["email"],
      },
      {
        code: "too_small",
        minimum: 8,
        type: "string",
        inclusive: true,
        exact: false,
        message: "Password too short",
        path: ["password"],
      },
    ];
    const zodError = new ZodError(issues);

    const req = createMockReq();
    const reply = createMockReply();

    errorHandler(zodError, req, reply);

    expect(reply.code).toHaveBeenCalledWith(400);
    expect(reply.send).toHaveBeenCalledWith(
      expect.objectContaining({
        success: false,
        error: expect.objectContaining({
          code: "VALIDATION_ERROR",
          message: "Validation error",
          details: expect.arrayContaining([
            { field: "email", message: "Email is required" },
            { field: "password", message: "Password too short" },
          ]),
        }),
      })
    );
  });

  it("handles ApiError with correct status and code", () => {
    const err = ApiError.notFound("Resource not found");
    const req = createMockReq();
    const reply = createMockReply();

    errorHandler(err, req, reply);

    expect(reply.code).toHaveBeenCalledWith(404);
    expect(reply.send).toHaveBeenCalledWith(
      expect.objectContaining({
        success: false,
        error: expect.objectContaining({
          code: "NOT_FOUND",
          message: "Resource not found",
        }),
      })
    );
  });

  it("handles ApiError with 500 status", () => {
    const err = ApiError.internal("Server crashed");
    const req = createMockReq();
    const reply = createMockReply();

    errorHandler(err, req, reply);

    expect(reply.code).toHaveBeenCalledWith(500);
  });

  it("handles Prisma errors with 400 DATABASE_ERROR", () => {
    const prismaError = new Error("Unique constraint failed");
    prismaError.name = "PrismaClientKnownRequestError";

    const req = createMockReq();
    const reply = createMockReply();

    errorHandler(prismaError, req, reply);

    expect(reply.code).toHaveBeenCalledWith(400);
    expect(reply.send).toHaveBeenCalledWith(
      expect.objectContaining({
        success: false,
        error: expect.objectContaining({
          code: "DATABASE_ERROR",
          message: "Database error",
        }),
      })
    );
  });

  it("handles unknown errors with 500 INTERNAL_ERROR", () => {
    const err = new Error("Something unexpected");
    const req = createMockReq();
    const reply = createMockReply();

    errorHandler(err, req, reply);

    expect(reply.code).toHaveBeenCalledWith(500);
    expect(reply.send).toHaveBeenCalledWith(
      expect.objectContaining({
        success: false,
        error: expect.objectContaining({
          code: "INTERNAL_ERROR",
        }),
      })
    );
  });

  it("includes requestId in error response", () => {
    const err = ApiError.badRequest("Bad");
    const req = createMockReq();
    const reply = createMockReply();

    errorHandler(err, req, reply);

    const sendCall = vi.mocked(reply.send).mock.calls[0][0] as { error: { requestId: string } };
    expect(sendCall.error.requestId).toBe("req-123");
  });
});
