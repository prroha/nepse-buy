import { describe, it, expect, beforeAll, beforeEach, afterAll } from "vitest";
import type { FastifyInstance } from "fastify";
import {
  cleanDatabase,
  createTestUser,
  loginTestUser,
  createAuthHeaders,
  getTestDb,
  disconnectTestDb,
} from "../setup/test-helpers.js";

let app: FastifyInstance;

beforeAll(async () => {
  // Dynamic import to ensure env vars are set before config loads
  const { createApp } = await import("../../create-app.js");
  app = await createApp();
  await app.ready();
});

beforeEach(async () => {
  await cleanDatabase();
});

afterAll(async () => {
  await app.close();
  await disconnectTestDb();
});

// ============================================================================
// Registration
// ============================================================================

describe("POST /api/v1/auth/register", () => {
  it("should register a new user with valid data", async () => {
    const res = await app.inject({
      method: "POST",
      url: "/api/v1/auth/register",
      payload: {
        email: "newuser@example.com",
        password: "SecurePass123",
        name: "New User",
      },
    });

    expect(res.statusCode).toBe(201);
    const body = JSON.parse(res.payload);
    expect(body.success).toBe(true);
    expect(body.data.user).toBeDefined();
    expect(body.data.user.email).toBe("newuser@example.com");
    expect(body.data.user.name).toBe("New User");
    expect(body.data.user.role).toBe("USER");
    // Password hash should never be returned
    expect(body.data.user.passwordHash).toBeUndefined();
  });

  it("should return 409 when registering with an existing email", async () => {
    await createTestUser({ email: "existing@example.com" });

    const res = await app.inject({
      method: "POST",
      url: "/api/v1/auth/register",
      payload: {
        email: "existing@example.com",
        password: "SecurePass123",
        name: "Duplicate User",
      },
    });

    expect(res.statusCode).toBe(409);
    const body = JSON.parse(res.payload);
    expect(body.success).toBe(false);
    expect(body.error.code).toBe("ALREADY_EXISTS");
  });

  it("should return 400 for invalid email format", async () => {
    const res = await app.inject({
      method: "POST",
      url: "/api/v1/auth/register",
      payload: {
        email: "not-an-email",
        password: "SecurePass123",
      },
    });

    expect(res.statusCode).toBe(400);
    const body = JSON.parse(res.payload);
    expect(body.success).toBe(false);
  });

  it("should return 400 for password shorter than 8 characters", async () => {
    const res = await app.inject({
      method: "POST",
      url: "/api/v1/auth/register",
      payload: {
        email: "valid@example.com",
        password: "short",
      },
    });

    expect(res.statusCode).toBe(400);
    const body = JSON.parse(res.payload);
    expect(body.success).toBe(false);
  });

  it("should normalize email to lowercase", async () => {
    const res = await app.inject({
      method: "POST",
      url: "/api/v1/auth/register",
      payload: {
        email: "UpperCase@Example.COM",
        password: "SecurePass123",
      },
    });

    expect(res.statusCode).toBe(201);
    const body = JSON.parse(res.payload);
    expect(body.data.user.email).toBe("uppercase@example.com");
  });
});

// ============================================================================
// Login
// ============================================================================

describe("POST /api/v1/auth/login", () => {
  it("should login with valid credentials and return tokens", async () => {
    const user = await createTestUser({
      email: "login@example.com",
      password: "TestPass123",
    });

    const res = await app.inject({
      method: "POST",
      url: "/api/v1/auth/login",
      payload: {
        email: user.email,
        password: "TestPass123",
      },
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.payload);
    expect(body.success).toBe(true);
    expect(body.data.user.email).toBe(user.email);
    expect(body.data.accessToken).toBeDefined();
    expect(body.data.refreshToken).toBeDefined();
    expect(body.data.csrfToken).toBeDefined();
  });

  it("should set httpOnly cookies on login", async () => {
    const user = await createTestUser({ password: "TestPass123" });

    const res = await app.inject({
      method: "POST",
      url: "/api/v1/auth/login",
      payload: { email: user.email, password: "TestPass123" },
    });

    const cookies = res.headers["set-cookie"];
    expect(cookies).toBeDefined();

    const cookieStr = Array.isArray(cookies) ? cookies.join("; ") : cookies;
    expect(cookieStr).toContain("accessToken=");
    expect(cookieStr).toContain("refreshToken=");
  });

  it("should return 401 for wrong password", async () => {
    const user = await createTestUser({ password: "TestPass123" });

    const res = await app.inject({
      method: "POST",
      url: "/api/v1/auth/login",
      payload: { email: user.email, password: "WrongPassword1" },
    });

    expect(res.statusCode).toBe(401);
    const body = JSON.parse(res.payload);
    expect(body.success).toBe(false);
    expect(body.error.code).toBe("INVALID_CREDENTIALS");
  });

  it("should return 401 for non-existent email", async () => {
    const res = await app.inject({
      method: "POST",
      url: "/api/v1/auth/login",
      payload: { email: "nonexistent@example.com", password: "TestPass123" },
    });

    expect(res.statusCode).toBe(401);
    const body = JSON.parse(res.payload);
    expect(body.success).toBe(false);
    expect(body.error.code).toBe("INVALID_CREDENTIALS");
  });

  it("should return 403 for deactivated user", async () => {
    const user = await createTestUser({
      password: "TestPass123",
      isActive: false,
    });

    const res = await app.inject({
      method: "POST",
      url: "/api/v1/auth/login",
      payload: { email: user.email, password: "TestPass123" },
    });

    expect(res.statusCode).toBe(403);
    const body = JSON.parse(res.payload);
    expect(body.success).toBe(false);
  });

  it("should create a session in the database on login", async () => {
    const user = await createTestUser({ password: "TestPass123" });

    const res = await app.inject({
      method: "POST",
      url: "/api/v1/auth/login",
      payload: { email: user.email, password: "TestPass123" },
    });
    expect(res.statusCode).toBe(200);

    const db = getTestDb();
    const sessions = await db.session.findMany({
      where: { userId: user.id },
    });
    expect(sessions.length).toBe(1);
  });
});

// ============================================================================
// Authenticated Access (GET /auth/me)
// ============================================================================

describe("GET /api/v1/auth/me", () => {
  it("should return user data with valid access token", async () => {
    const user = await createTestUser({ password: "TestPass123" });
    const { accessToken } = await loginTestUser(app, user.email, "TestPass123");

    const res = await app.inject({
      method: "GET",
      url: "/api/v1/auth/me",
      headers: createAuthHeaders(accessToken),
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.payload);
    expect(body.success).toBe(true);
    expect(body.data.user.email).toBe(user.email);
    expect(body.data.user.id).toBe(user.id);
  });

  it("should return 401 without a token", async () => {
    const res = await app.inject({
      method: "GET",
      url: "/api/v1/auth/me",
    });

    expect(res.statusCode).toBe(401);
    const body = JSON.parse(res.payload);
    expect(body.success).toBe(false);
    expect(body.error.code).toBe("AUTH_REQUIRED");
  });

  it("should return 401 with an invalid token", async () => {
    const res = await app.inject({
      method: "GET",
      url: "/api/v1/auth/me",
      headers: { authorization: "Bearer invalid-token-value" },
    });

    expect(res.statusCode).toBe(401);
    const body = JSON.parse(res.payload);
    expect(body.success).toBe(false);
    expect(body.error.code).toBe("INVALID_TOKEN");
  });

  it("should return 401 with malformed Authorization header", async () => {
    const res = await app.inject({
      method: "GET",
      url: "/api/v1/auth/me",
      headers: { authorization: "NotBearer token" },
    });

    expect(res.statusCode).toBe(401);
    const body = JSON.parse(res.payload);
    expect(body.success).toBe(false);
  });
});

// ============================================================================
// Token Refresh
// ============================================================================

describe("POST /api/v1/auth/refresh", () => {
  it("should return new tokens with a valid refresh token", async () => {
    const user = await createTestUser({ password: "TestPass123" });
    const { refreshToken } = await loginTestUser(app, user.email, "TestPass123");

    const res = await app.inject({
      method: "POST",
      url: "/api/v1/auth/refresh",
      payload: { refreshToken },
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.payload);
    expect(body.success).toBe(true);
    expect(body.data.accessToken).toBeDefined();
    expect(body.data.refreshToken).toBeDefined();
    expect(body.data.user.email).toBe(user.email);
  });

  it("should return error with an invalid refresh token", async () => {
    const res = await app.inject({
      method: "POST",
      url: "/api/v1/auth/refresh",
      payload: { refreshToken: "invalid-refresh-token" },
    });

    expect(res.statusCode).toBeGreaterThanOrEqual(400);
    const body = JSON.parse(res.payload);
    expect(body.success).toBe(false);
  });

  it("should return 400 without a refresh token", async () => {
    const res = await app.inject({
      method: "POST",
      url: "/api/v1/auth/refresh",
      payload: {},
    });

    expect(res.statusCode).toBe(400);
    const body = JSON.parse(res.payload);
    expect(body.success).toBe(false);
  });
});

// ============================================================================
// Logout
// ============================================================================

describe("POST /api/v1/auth/logout", () => {
  it("should clear cookies and delete session", async () => {
    const user = await createTestUser({ password: "TestPass123" });
    const { refreshToken, cookies } = await loginTestUser(app, user.email, "TestPass123");

    // Verify session exists before logout
    const db = getTestDb();
    const sessionsBefore = await db.session.findMany({ where: { userId: user.id } });
    expect(sessionsBefore.length).toBe(1);

    const res = await app.inject({
      method: "POST",
      url: "/api/v1/auth/logout",
      headers: {
        cookie: cookies.join("; "),
      },
      payload: { refreshToken },
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.payload);
    expect(body.success).toBe(true);

    // Verify session deleted
    const sessionsAfter = await db.session.findMany({ where: { userId: user.id } });
    expect(sessionsAfter.length).toBe(0);
  });
});

// ============================================================================
// Password Change
// ============================================================================

describe("POST /api/v1/auth/change-password", () => {
  it("should change password with correct current password", async () => {
    const user = await createTestUser({ password: "OldPass123" });
    const { accessToken, csrfToken, cookies } = await loginTestUser(app, user.email, "OldPass123");

    const res = await app.inject({
      method: "POST",
      url: "/api/v1/auth/change-password",
      headers: {
        ...createAuthHeaders(accessToken, csrfToken),
        cookie: cookies.join("; "),
      },
      payload: {
        currentPassword: "OldPass123",
        newPassword: "NewPass456",
        confirmPassword: "NewPass456",
      },
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.payload);
    expect(body.success).toBe(true);
  });

  it("should allow login with new password after change", async () => {
    const user = await createTestUser({ password: "OldPass123" });
    const { accessToken, csrfToken, cookies } = await loginTestUser(app, user.email, "OldPass123");

    const changeRes = await app.inject({
      method: "POST",
      url: "/api/v1/auth/change-password",
      headers: {
        ...createAuthHeaders(accessToken, csrfToken),
        cookie: cookies.join("; "),
      },
      payload: {
        currentPassword: "OldPass123",
        newPassword: "NewPass456",
        confirmPassword: "NewPass456",
      },
    });
    expect(changeRes.statusCode).toBe(200);

    // Login with new password should work
    const loginRes = await app.inject({
      method: "POST",
      url: "/api/v1/auth/login",
      payload: { email: user.email, password: "NewPass456" },
    });

    expect(loginRes.statusCode).toBe(200);
  });

  it("should reject password change with wrong current password", async () => {
    const user = await createTestUser({ password: "OldPass123" });
    const { accessToken, csrfToken, cookies } = await loginTestUser(app, user.email, "OldPass123");

    const res = await app.inject({
      method: "POST",
      url: "/api/v1/auth/change-password",
      headers: {
        ...createAuthHeaders(accessToken, csrfToken),
        cookie: cookies.join("; "),
      },
      payload: {
        currentPassword: "WrongPass999",
        newPassword: "NewPass456",
        confirmPassword: "NewPass456",
      },
    });

    expect(res.statusCode).toBe(401);
    const body = JSON.parse(res.payload);
    expect(body.success).toBe(false);
  });

  it("should reject password change without authentication", async () => {
    const res = await app.inject({
      method: "POST",
      url: "/api/v1/auth/change-password",
      payload: {
        currentPassword: "OldPass123",
        newPassword: "NewPass456",
        confirmPassword: "NewPass456",
      },
    });

    // CSRF middleware blocks unauthenticated POST requests with 403
    // before auth middleware runs — both are valid rejection paths
    expect([401, 403]).toContain(res.statusCode);
    const body = JSON.parse(res.payload);
    expect(body.success).toBe(false);
  });
});

// ============================================================================
// Full Auth Flow (end-to-end)
// ============================================================================

describe("Full auth flow", () => {
  it("should support register → login → access → logout", async () => {
    // Register
    const registerRes = await app.inject({
      method: "POST",
      url: "/api/v1/auth/register",
      payload: {
        email: "flow@example.com",
        password: "FlowPass123",
        name: "Flow User",
      },
    });
    expect(registerRes.statusCode).toBe(201);

    // Login
    const loginRes = await app.inject({
      method: "POST",
      url: "/api/v1/auth/login",
      payload: { email: "flow@example.com", password: "FlowPass123" },
    });
    expect(loginRes.statusCode).toBe(200);
    const loginBody = JSON.parse(loginRes.payload);
    const { accessToken, refreshToken } = loginBody.data;
    const cookies = loginRes.headers["set-cookie"];
    const cookieStr = Array.isArray(cookies) ? cookies.join("; ") : (cookies || "");

    // Access protected route
    const meRes = await app.inject({
      method: "GET",
      url: "/api/v1/auth/me",
      headers: { authorization: `Bearer ${accessToken}` },
    });
    expect(meRes.statusCode).toBe(200);
    const meBody = JSON.parse(meRes.payload);
    expect(meBody.data.user.email).toBe("flow@example.com");

    // Logout
    const logoutRes = await app.inject({
      method: "POST",
      url: "/api/v1/auth/logout",
      headers: { cookie: cookieStr },
      payload: { refreshToken },
    });
    expect(logoutRes.statusCode).toBe(200);
  });
});
