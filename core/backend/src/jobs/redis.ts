import { Redis } from "ioredis";
import { config } from "../config/index.js";

/**
 * Shared ioredis connection for BullMQ. BullMQ requires connections with
 * `maxRetriesPerRequest: null` for blocking commands; we honor that here.
 */
let cached: Redis | null = null;

export function getRedis(): Redis {
  if (!cached) {
    cached = new Redis(config.redisUrl, {
      maxRetriesPerRequest: null,
      enableReadyCheck: false,
    });
  }
  return cached;
}

export type { Redis };

export async function disconnectRedis(): Promise<void> {
  if (cached) {
    await cached.quit().catch(() => undefined);
    cached = null;
  }
}
