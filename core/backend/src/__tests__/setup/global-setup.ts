/**
 * Global Test Setup
 *
 * Runs once before all test files.
 * Sets up the test database and applies migrations.
 */

import { execSync } from "child_process";
import path from "path";

const TEST_DATABASE_NAME = "fullstack_test";

/**
 * Build the test DATABASE_URL from the dev one, swapping the DB name.
 */
function getTestDatabaseUrl(): string {
  // If explicitly set, use it
  if (process.env.TEST_DATABASE_URL) {
    return process.env.TEST_DATABASE_URL;
  }

  // Derive from dev DATABASE_URL by replacing the DB name
  const devUrl = process.env.DATABASE_URL || "postgresql://postgres:localpass@localhost:5433/fullstack_dev";
  const url = new URL(devUrl);
  url.pathname = `/${TEST_DATABASE_NAME}`;
  return url.toString();
}

export async function setup(): Promise<void> {
  const testDatabaseUrl = getTestDatabaseUrl();
  process.env.DATABASE_URL = testDatabaseUrl;
  process.env.NODE_ENV = "test";
  process.env.JWT_SECRET = "test-jwt-secret-that-is-at-least-32-chars-long";

  // Allow CI / local-without-Postgres runs to skip DB provisioning.
  // Integration tests will then fail individually when they hit Prisma — which
  // is the correct signal — but unit tests using mocks run unimpeded.
  if (process.env.SKIP_DB_SETUP === "1") {
    console.warn("[test-setup] SKIP_DB_SETUP=1 — skipping test DB provisioning");
    return;
  }

  const prismaDir = path.resolve(import.meta.dirname, "../../../prisma");

  // Create the test database if it doesn't exist
  const baseUrl = new URL(testDatabaseUrl);
  baseUrl.pathname = "/postgres";
  try {
    execSync(
      `echo "SELECT 'CREATE DATABASE ${TEST_DATABASE_NAME}' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${TEST_DATABASE_NAME}')\\gexec" | psql "${baseUrl.toString()}"`,
      { stdio: "pipe" }
    );
  } catch {
    // psql unavailable or DB already exists — proceed
  }

  // Apply migrations to test database. If the DB is unreachable, warn and bail
  // so that unit tests can still run.
  try {
    execSync(`npx prisma migrate deploy --schema="${prismaDir}/schema.prisma"`, {
      env: { ...process.env, DATABASE_URL: testDatabaseUrl },
      stdio: "pipe",
      cwd: path.resolve(import.meta.dirname, "../../.."),
    });
  } catch (_error) {
    try {
      execSync(`npx prisma db push --schema="${prismaDir}/schema.prisma" --skip-generate`, {
        env: { ...process.env, DATABASE_URL: testDatabaseUrl },
        stdio: "pipe",
        cwd: path.resolve(import.meta.dirname, "../../.."),
      });
    } catch (pushErr) {
      console.warn(
        `[test-setup] Test DB unreachable at ${new URL(testDatabaseUrl).host} — integration tests will fail. ` +
          `Run docker compose -f docker-compose.dev.yml up postgres, or set SKIP_DB_SETUP=1.`
      );
      return;
    }
  }

  console.warn(`[test-setup] Test database ready: ${TEST_DATABASE_NAME}`);
}

export async function teardown(): Promise<void> {
  // Nothing to clean up globally — each test file cleans its own data
}
