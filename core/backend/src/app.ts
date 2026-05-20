import { createApp } from "./create-app.js";
import { config } from "./config/index.js";
import { cleanupRateLimitStores } from "./middleware/rate-limit.middleware.js";
import { startTokenCleanup, stopTokenCleanup } from "./services/token-cleanup.service.js";
import { startJobs, stopJobs } from "./jobs/index.js";
import { logger } from "./lib/logger.js";
import { db } from "./lib/db.js";

const app = await createApp();

// Start server
const PORT = config.port;

await app.listen({ port: PORT, host: "0.0.0.0" });

// Start background jobs
startTokenCleanup();
await startJobs();

logger.info(`Server started`, {
  port: PORT,
  environment: config.nodeEnv,
  url: `http://localhost:${PORT}`,
});

// Graceful shutdown with timeout guard
const SHUTDOWN_TIMEOUT_MS = 10_000;

const shutdown = async () => {
  logger.info("Shutting down gracefully...");

  // Timeout guard to force exit if cleanup hangs
  const forceExit = setTimeout(() => {
    logger.error("Shutdown timed out, forcing exit");
    process.exit(1);
  }, SHUTDOWN_TIMEOUT_MS);
  forceExit.unref();

  try {
    stopTokenCleanup();
    await stopJobs();
    await app.close();
    await cleanupRateLimitStores();
    await db.$disconnect();
  } catch (err) {
    logger.error("Error during shutdown", {
      error: err instanceof Error ? err.message : String(err),
    });
  }

  clearTimeout(forceExit);
  process.exit(0);
};

process.on("SIGTERM", shutdown);
process.on("SIGINT", shutdown);

export { app };
