/**
 * Per-file Test Setup
 *
 * Loaded via vitest setupFiles. Sets environment variables
 * that must be present before any application code imports.
 */

// Ensure test environment
process.env.NODE_ENV = "test";
process.env.JWT_SECRET = "test-jwt-secret-that-is-at-least-32-chars-long";

// Disable rate limiting for tests (allow many requests from localhost)
process.env.RATE_LIMIT_MAX_REQUESTS = "10000";

// Suppress noisy logs during tests
process.env.LOG_LEVEL = "error";
