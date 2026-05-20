/**
 * Integration Test Helpers
 *
 * Utilities for integration tests that interact with a real database.
 */

import { PrismaClient } from "@prisma/client";
import bcrypt from "bcryptjs";
import { expect } from "vitest";
import type { FastifyInstance } from "fastify";

// Dedicated Prisma client for test setup/teardown
let testDb: PrismaClient | null = null;

export function getTestDb(): PrismaClient {
  if (!testDb) {
    testDb = new PrismaClient();
  }
  return testDb;
}

export async function disconnectTestDb(): Promise<void> {
  if (testDb) {
    await testDb.$disconnect();
    testDb = null;
  }
}

/**
 * Truncate all tables in the correct order (respecting FK constraints).
 */
export async function cleanDatabase(): Promise<void> {
  const db = getTestDb();

  await db.notificationDelivery.deleteMany();
  await db.dailySignal.deleteMany();
  await db.priceObservation.deleteMany();
  await db.fundamentalsObservation.deleteMany();
  await db.watchlistItem.deleteMany();
  await db.stock.deleteMany();
  await db.auditLog.deleteMany();
  await db.notification.deleteMany();
  await db.session.deleteMany();
  await db.passwordResetToken.deleteMany();
  await db.emailVerificationToken.deleteMany();
  await db.user.deleteMany();
}

/**
 * Create a test user directly in the database.
 */
export async function createTestUser(overrides: {
  email?: string;
  password?: string;
  name?: string;
  role?: "USER" | "ADMIN" | "SUPER_ADMIN";
  isActive?: boolean;
  emailVerified?: boolean;
} = {}): Promise<{
  id: string;
  email: string;
  password: string;
  name: string | null;
  role: string;
}> {
  const db = getTestDb();
  const password = overrides.password || "TestPass123";
  const passwordHash = await bcrypt.hash(password, 4);

  const user = await db.user.create({
    data: {
      email: overrides.email || `test-${Date.now()}-${Math.random().toString(36).slice(2)}@example.com`,
      passwordHash,
      name: overrides.name ?? "Test User",
      role: overrides.role || "USER",
      isActive: overrides.isActive ?? true,
      emailVerified: overrides.emailVerified ?? false,
    },
  });

  return {
    id: user.id,
    email: user.email,
    password,
    name: user.name,
    role: user.role,
  };
}

/**
 * Log in a test user via the API and return tokens + cookies.
 * Uses Fastify's inject() method for lightweight in-process testing.
 */
export async function loginTestUser(
  app: FastifyInstance,
  email: string,
  password: string
): Promise<{
  accessToken: string;
  refreshToken: string;
  csrfToken: string;
  cookies: string[];
}> {
  const res = await app.inject({
    method: "POST",
    url: "/api/v1/auth/login",
    payload: { email, password },
  });

  expect(res.statusCode).toBe(200);

  const body = JSON.parse(res.payload);
  const cookies = res.headers["set-cookie"];
  const cookieArray = Array.isArray(cookies) ? cookies : (cookies ? [cookies] : []);

  return {
    accessToken: body.data.accessToken,
    refreshToken: body.data.refreshToken,
    csrfToken: body.data.csrfToken,
    cookies: cookieArray,
  };
}

/**
 * Helper to make authenticated requests using Fastify inject
 */
export function createAuthHeaders(accessToken: string, csrfToken?: string): Record<string, string> {
  const headers: Record<string, string> = {
    authorization: `Bearer ${accessToken}`,
  };
  if (csrfToken) {
    headers["x-csrf-token"] = csrfToken;
    headers.cookie = `csrfToken=${csrfToken}`;
  }
  return headers;
}
