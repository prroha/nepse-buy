import { describe, it, expect, vi, beforeEach } from "vitest";

// Mock all dependencies before importing the service
vi.mock("../../lib/db.js", () => ({
  db: {
    user: {
      findUnique: vi.fn(),
      create: vi.fn(),
      update: vi.fn(),
    },
  },
}));

vi.mock("../../utils/jwt.js", () => ({
  generateTokenPair: vi.fn().mockReturnValue({
    accessToken: "mock-access-token",
    refreshToken: "mock-refresh-token",
    expiresIn: 604800,
  }),
  verifyToken: vi.fn(),
}));

vi.mock("../../services/lockout.service.js", () => ({
  lockoutService: {
    getLockoutStatus: vi.fn().mockReturnValue({ isLocked: false }),
    recordFailedAttempt: vi.fn().mockReturnValue({ isLocked: false }),
    resetFailedAttempts: vi.fn(),
  },
  LockoutStatus: {},
}));

vi.mock("../../services/email-verification.service.js", () => ({
  emailVerificationService: {
    sendVerificationEmail: vi.fn(),
  },
}));

vi.mock("../../services/email.service.js", () => ({
  emailService: {
    sendWelcomeEmail: vi.fn(),
    sendPasswordChangedEmail: vi.fn(),
  },
}));

vi.mock("../../services/session.service.js", () => ({
  sessionService: {
    createSession: vi.fn().mockResolvedValue("mock-session-id"),
    deleteSessionByRefreshToken: vi.fn(),
    findSessionByRefreshToken: vi.fn(),
    updateSessionActivity: vi.fn(),
  },
}));

vi.mock("../../lib/logger.js", () => ({
  logger: {
    info: vi.fn(),
    error: vi.fn(),
    warn: vi.fn(),
  },
}));

import { db } from "../../lib/db.js";
import { authService } from "../../services/auth.service.js";
import { sessionService } from "../../services/session.service.js";
import bcrypt from "bcryptjs";

const mockFindUnique = vi.mocked(db.user.findUnique);
const mockCreate = vi.mocked(db.user.create);

beforeEach(() => {
  vi.clearAllMocks();
});

// ============================================================================
// Register
// ============================================================================

describe("authService.register", () => {
  it("should hash password and create user", async () => {
    mockFindUnique.mockResolvedValue(null); // No existing user
    mockCreate.mockResolvedValue({
      id: "user-1",
      email: "test@example.com",
      name: "Test",
      role: "USER",
      emailVerified: false,
      createdAt: new Date(),
    } as ReturnType<typeof db.user.create> extends Promise<infer T> ? T : never);

    const result = await authService.register({
      email: "test@example.com",
      password: "SecurePass123",
      name: "Test",
    });

    expect(result.email).toBe("test@example.com");
    // Verify that the password was hashed (not stored in plain text)
    const createCall = mockCreate.mock.calls[0][0];
    const storedHash = (createCall as { data: { passwordHash: string } }).data.passwordHash;
    expect(storedHash).not.toBe("SecurePass123");
    expect(await bcrypt.compare("SecurePass123", storedHash)).toBe(true);
  });

  it("should throw conflict error on duplicate email", async () => {
    mockFindUnique.mockResolvedValue({
      id: "existing-user",
      email: "test@example.com",
    } as Awaited<ReturnType<typeof db.user.findUnique>>);

    await expect(
      authService.register({
        email: "test@example.com",
        password: "SecurePass123",
      })
    ).rejects.toThrow(/already registered/i);
  });

  it("should normalize email to lowercase", async () => {
    mockFindUnique.mockResolvedValue(null);
    mockCreate.mockResolvedValue({
      id: "user-1",
      email: "test@example.com",
      name: null,
      role: "USER",
      emailVerified: false,
      createdAt: new Date(),
    } as ReturnType<typeof db.user.create> extends Promise<infer T> ? T : never);

    await authService.register({
      email: "TEST@EXAMPLE.COM",
      password: "SecurePass123",
    });

    expect(mockFindUnique).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { email: "test@example.com" },
      })
    );
  });
});

// ============================================================================
// Login
// ============================================================================

describe("authService.login", () => {
  const validPasswordHash = bcrypt.hashSync("TestPass123", 4);
  const mockUser = {
    id: "user-1",
    email: "test@example.com",
    name: "Test",
    role: "USER",
    isActive: true,
    passwordHash: validPasswordHash,
    failedLoginAttempts: 0,
    lockedUntil: null,
    lastFailedLogin: null,
    activeDeviceId: null,
  };

  it("should return tokens for valid credentials", async () => {
    mockFindUnique.mockResolvedValue(mockUser as Awaited<ReturnType<typeof db.user.findUnique>>);

    const result = await authService.login({
      email: "test@example.com",
      password: "TestPass123",
    });

    expect(result.user.email).toBe("test@example.com");
    expect(result.accessToken).toBeDefined();
    expect(result.refreshToken).toBeDefined();
    expect(result.sessionId).toBe("mock-session-id");
  });

  it("should throw on invalid password", async () => {
    mockFindUnique.mockResolvedValue(mockUser as Awaited<ReturnType<typeof db.user.findUnique>>);

    await expect(
      authService.login({
        email: "test@example.com",
        password: "WrongPassword1",
      })
    ).rejects.toThrow(/invalid credentials/i);
  });

  it("should throw on non-existent user", async () => {
    mockFindUnique.mockResolvedValue(null);

    await expect(
      authService.login({
        email: "nobody@example.com",
        password: "TestPass123",
      })
    ).rejects.toThrow(/invalid credentials/i);
  });

  it("should create a session in the database on successful login", async () => {
    mockFindUnique.mockResolvedValue(mockUser as Awaited<ReturnType<typeof db.user.findUnique>>);

    await authService.login({
      email: "test@example.com",
      password: "TestPass123",
    });

    expect(sessionService.createSession).toHaveBeenCalledWith(
      expect.objectContaining({
        userId: "user-1",
      })
    );
  });

  it("should throw for deactivated user", async () => {
    mockFindUnique.mockResolvedValue({
      ...mockUser,
      isActive: false,
    } as Awaited<ReturnType<typeof db.user.findUnique>>);

    await expect(
      authService.login({
        email: "test@example.com",
        password: "TestPass123",
      })
    ).rejects.toThrow(/deactivated/i);
  });
});

// ============================================================================
// Logout
// ============================================================================

describe("authService.logout", () => {
  it("should delete session by refresh token", async () => {
    await authService.logout({ refreshToken: "test-refresh-token" });

    expect(sessionService.deleteSessionByRefreshToken).toHaveBeenCalledWith(
      "test-refresh-token"
    );
  });

  it("should handle logout without refresh token", async () => {
    await authService.logout({});

    expect(sessionService.deleteSessionByRefreshToken).not.toHaveBeenCalled();
  });
});

// ============================================================================
// Password Hashing (round-trip)
// ============================================================================

describe("Password hashing", () => {
  it("should hash password so it can be verified with bcrypt", async () => {
    mockFindUnique.mockResolvedValue(null);
    // Prisma's create() returns a Prisma__UserClient (thenable), not a Promise.
    // mockResolvedValue handles this correctly; mockImplementation requires matching
    // the unawaited return type, which is awkward to construct in tests.
    mockCreate.mockImplementation(((args: { data: { email: string } }) =>
      Promise.resolve({
        id: "user-1",
        email: args.data.email,
        name: null,
        role: "USER",
        emailVerified: false,
        createdAt: new Date(),
      })) as unknown as typeof db.user.create);

    await authService.register({
      email: "hash-test@example.com",
      password: "MyPassword123",
    });

    const createCall = mockCreate.mock.calls[0][0];
    const hash = (createCall as { data: { passwordHash: string } }).data.passwordHash;

    // Verify the hash is valid bcrypt
    expect(hash).toMatch(/^\$2[aby]\$/);
    expect(await bcrypt.compare("MyPassword123", hash)).toBe(true);
    expect(await bcrypt.compare("WrongPassword", hash)).toBe(false);
  });
});
