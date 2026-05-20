import { describe, it, expect, vi, beforeEach } from "vitest";
import { FastifyRequest, FastifyReply } from "fastify";
import {
  authMiddleware,
  adminMiddleware,
  superAdminMiddleware,
  optionalAuthMiddleware,
} from "../../middleware/auth.middleware.js";
import { AuthenticatedRequest } from "../../types/index.js";

// Mock dependencies
vi.mock("../../utils/jwt.js", () => ({
  verifyToken: vi.fn(),
}));

vi.mock("../../lib/db.js", () => ({
  db: {
    user: {
      findUnique: vi.fn(),
    },
  },
}));

vi.mock("../../lib/logger.js", () => ({
  logger: {
    error: vi.fn(),
    warn: vi.fn(),
  },
}));

import { verifyToken } from "../../utils/jwt.js";
import { db } from "../../lib/db.js";

const mockVerifyToken = vi.mocked(verifyToken);
const mockFindUnique = vi.mocked(db.user.findUnique);

function createMockReq(overrides: Partial<FastifyRequest> = {}): FastifyRequest {
  return {
    cookies: {},
    headers: {},
    ...overrides,
  } as FastifyRequest;
}

function createMockReply(): FastifyReply {
  const reply = {
    code: vi.fn().mockReturnThis(),
    send: vi.fn().mockReturnThis(),
  } as unknown as FastifyReply;
  return reply;
}

const mockUser = {
  id: "user-123",
  email: "test@example.com",
  name: "Test User",
  role: "USER" as const,
  isActive: true,
  createdAt: new Date(),
  updatedAt: new Date(),
};

const mockPayload = { userId: "user-123", email: "test@example.com", type: "access" as const };

beforeEach(() => {
  vi.clearAllMocks();
});

describe("authMiddleware", () => {
  it("should return 401 AUTH_REQUIRED when no token provided", async () => {
    const req = createMockReq();
    const reply = createMockReply();

    await authMiddleware(req, reply);

    expect(reply.code).toHaveBeenCalledWith(401);
    expect(reply.send).toHaveBeenCalledWith(
      expect.objectContaining({
        success: false,
        error: expect.objectContaining({ code: "AUTH_REQUIRED" }),
      })
    );
  });

  it("should return 401 AUTH_REQUIRED for empty string token", async () => {
    const req = createMockReq({ cookies: { accessToken: "  " } } as Partial<FastifyRequest>);
    const reply = createMockReply();

    await authMiddleware(req, reply);

    expect(reply.code).toHaveBeenCalledWith(401);
    expect(reply.send).toHaveBeenCalledWith(
      expect.objectContaining({
        error: expect.objectContaining({ code: "AUTH_REQUIRED" }),
      })
    );
  });

  it("should attach user for valid token + active user (no reply call)", async () => {
    mockVerifyToken.mockReturnValue(mockPayload as ReturnType<typeof verifyToken>);
    mockFindUnique.mockResolvedValue(mockUser as Awaited<ReturnType<typeof db.user.findUnique>>);

    const req = createMockReq({ cookies: { accessToken: "valid-token" } } as Partial<FastifyRequest>);
    const reply = createMockReply();

    await authMiddleware(req, reply);

    // In Fastify, successful middleware just returns without calling reply
    expect(reply.code).not.toHaveBeenCalled();
    expect((req as AuthenticatedRequest).user).toEqual(mockPayload);
    expect((req as AuthenticatedRequest).dbUser).toEqual(mockUser);
  });

  it("should return 401 TOKEN_EXPIRED for expired token", async () => {
    mockVerifyToken.mockImplementation(() => {
      throw new Error("Token expired");
    });

    const req = createMockReq({ cookies: { accessToken: "expired-token" } } as Partial<FastifyRequest>);
    const reply = createMockReply();

    await authMiddleware(req, reply);

    expect(reply.code).toHaveBeenCalledWith(401);
    expect(reply.send).toHaveBeenCalledWith(
      expect.objectContaining({
        error: expect.objectContaining({ code: "TOKEN_EXPIRED" }),
      })
    );
  });

  it("should return 401 INVALID_TOKEN for invalid token", async () => {
    mockVerifyToken.mockImplementation(() => {
      throw new Error("Invalid token");
    });

    const req = createMockReq({ cookies: { accessToken: "bad-token" } } as Partial<FastifyRequest>);
    const reply = createMockReply();

    await authMiddleware(req, reply);

    expect(reply.code).toHaveBeenCalledWith(401);
    expect(reply.send).toHaveBeenCalledWith(
      expect.objectContaining({
        error: expect.objectContaining({ code: "INVALID_TOKEN" }),
      })
    );
  });

  it("should return 401 USER_NOT_FOUND when user does not exist", async () => {
    mockVerifyToken.mockReturnValue(mockPayload as ReturnType<typeof verifyToken>);
    mockFindUnique.mockResolvedValue(null);

    const req = createMockReq({ cookies: { accessToken: "valid-token" } } as Partial<FastifyRequest>);
    const reply = createMockReply();

    await authMiddleware(req, reply);

    expect(reply.code).toHaveBeenCalledWith(401);
    expect(reply.send).toHaveBeenCalledWith(
      expect.objectContaining({
        error: expect.objectContaining({ code: "USER_NOT_FOUND" }),
      })
    );
  });

  it("should return 403 USER_DEACTIVATED for inactive user", async () => {
    mockVerifyToken.mockReturnValue(mockPayload as ReturnType<typeof verifyToken>);
    mockFindUnique.mockResolvedValue({
      ...mockUser,
      isActive: false,
    } as Awaited<ReturnType<typeof db.user.findUnique>>);

    const req = createMockReq({ cookies: { accessToken: "valid-token" } } as Partial<FastifyRequest>);
    const reply = createMockReply();

    await authMiddleware(req, reply);

    expect(reply.code).toHaveBeenCalledWith(403);
    expect(reply.send).toHaveBeenCalledWith(
      expect.objectContaining({
        error: expect.objectContaining({ code: "USER_DEACTIVATED" }),
      })
    );
  });

  it("should prefer cookie token over Authorization header", async () => {
    mockVerifyToken.mockReturnValue(mockPayload as ReturnType<typeof verifyToken>);
    mockFindUnique.mockResolvedValue(mockUser as Awaited<ReturnType<typeof db.user.findUnique>>);

    const req = createMockReq({
      cookies: { accessToken: "cookie-token" },
      headers: { authorization: "Bearer header-token" },
    } as Partial<FastifyRequest>);
    const reply = createMockReply();

    await authMiddleware(req, reply);

    expect(mockVerifyToken).toHaveBeenCalledWith("cookie-token");
  });

  it("should fall back to Authorization header when no cookie", async () => {
    mockVerifyToken.mockReturnValue(mockPayload as ReturnType<typeof verifyToken>);
    mockFindUnique.mockResolvedValue(mockUser as Awaited<ReturnType<typeof db.user.findUnique>>);

    const req = createMockReq({
      cookies: {},
      headers: { authorization: "Bearer header-token" },
    } as Partial<FastifyRequest>);
    const reply = createMockReply();

    await authMiddleware(req, reply);

    expect(mockVerifyToken).toHaveBeenCalledWith("header-token");
  });
});

describe("adminMiddleware", () => {
  it("should not call reply for ADMIN user", async () => {
    const req = createMockReq() as AuthenticatedRequest;
    req.user = mockPayload;
    req.dbUser = { ...mockUser, role: "ADMIN" } as AuthenticatedRequest["dbUser"];
    const reply = createMockReply();

    await adminMiddleware(req, reply);

    expect(reply.code).not.toHaveBeenCalled();
  });

  it("should not call reply for SUPER_ADMIN user", async () => {
    const req = createMockReq() as AuthenticatedRequest;
    req.user = mockPayload;
    req.dbUser = { ...mockUser, role: "SUPER_ADMIN" } as AuthenticatedRequest["dbUser"];
    const reply = createMockReply();

    await adminMiddleware(req, reply);

    expect(reply.code).not.toHaveBeenCalled();
  });

  it("should return 403 for regular USER", async () => {
    const req = createMockReq() as AuthenticatedRequest;
    req.user = mockPayload;
    req.dbUser = mockUser as AuthenticatedRequest["dbUser"];
    const reply = createMockReply();

    await adminMiddleware(req, reply);

    expect(reply.code).toHaveBeenCalledWith(403);
  });

  it("should return 401 when no user attached", async () => {
    const req = createMockReq();
    const reply = createMockReply();

    await adminMiddleware(req, reply);

    expect(reply.code).toHaveBeenCalledWith(401);
  });
});

describe("superAdminMiddleware", () => {
  it("should not call reply for SUPER_ADMIN user", async () => {
    const req = createMockReq() as AuthenticatedRequest;
    req.user = mockPayload;
    req.dbUser = { ...mockUser, role: "SUPER_ADMIN" } as AuthenticatedRequest["dbUser"];
    const reply = createMockReply();

    await superAdminMiddleware(req, reply);

    expect(reply.code).not.toHaveBeenCalled();
  });

  it("should return 403 for ADMIN user", async () => {
    const req = createMockReq() as AuthenticatedRequest;
    req.user = mockPayload;
    req.dbUser = { ...mockUser, role: "ADMIN" } as AuthenticatedRequest["dbUser"];
    const reply = createMockReply();

    await superAdminMiddleware(req, reply);

    expect(reply.code).toHaveBeenCalledWith(403);
  });

  it("should return 403 for regular USER", async () => {
    const req = createMockReq() as AuthenticatedRequest;
    req.user = mockPayload;
    req.dbUser = mockUser as AuthenticatedRequest["dbUser"];
    const reply = createMockReply();

    await superAdminMiddleware(req, reply);

    expect(reply.code).toHaveBeenCalledWith(403);
  });
});

describe("optionalAuthMiddleware", () => {
  it("should attach user when valid token provided", async () => {
    mockVerifyToken.mockReturnValue(mockPayload as ReturnType<typeof verifyToken>);
    mockFindUnique.mockResolvedValue(mockUser as Awaited<ReturnType<typeof db.user.findUnique>>);

    const req = createMockReq({ cookies: { accessToken: "valid-token" } } as Partial<FastifyRequest>);

    await optionalAuthMiddleware(req);

    expect((req as AuthenticatedRequest).user).toEqual(mockPayload);
  });

  it("should not attach user when no token", async () => {
    const req = createMockReq();

    await optionalAuthMiddleware(req);

    expect(req.user).toBeUndefined();
  });

  it("should not attach user when token is invalid", async () => {
    mockVerifyToken.mockImplementation(() => {
      throw new Error("Invalid token");
    });

    const req = createMockReq({ cookies: { accessToken: "bad-token" } } as Partial<FastifyRequest>);

    await optionalAuthMiddleware(req);

    expect(req.user).toBeUndefined();
  });
});
