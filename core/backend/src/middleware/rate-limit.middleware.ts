import { FastifyInstance, FastifyRequest, FastifyReply } from "fastify";
import fastifyRateLimit from "@fastify/rate-limit";
import { config } from "../config/index.js";
import { logger } from "../lib/logger.js";

// Maximum window duration for store cleanup (24 hours)
const MAX_WINDOW_MS = 24 * 60 * 60 * 1000;

// ============================================================================
// Types & Interfaces
// ============================================================================

interface RateLimitErrorResponse {
  success: false;
  error: {
    code: string;
    message: string;
    retryAfter?: number;
  };
}

interface SlidingWindowEntry {
  timestamps: number[];
  points: number;
}

interface PlanLimitConfig {
  requests: number;
  window: string;
}

type UserPlan = "free" | "basic" | "pro" | "enterprise";

interface RateLimitInfo {
  limit: number;
  remaining: number;
  resetTime: number;
}

interface RateLimitStore {
  get(key: string): Promise<SlidingWindowEntry | null>;
  set(key: string, entry: SlidingWindowEntry, windowMs: number): Promise<void>;
  increment(key: string, points: number, windowMs: number): Promise<SlidingWindowEntry>;
  close(): Promise<void>;
}

// ============================================================================
// Plan Limits Configuration
// ============================================================================

export const PLAN_LIMITS: Record<UserPlan, PlanLimitConfig> = {
  free: { requests: 100, window: "1m" },
  basic: { requests: 500, window: "1m" },
  pro: { requests: 2000, window: "1m" },
  enterprise: { requests: 10000, window: "1m" },
};

export const DEFAULT_ENDPOINT_COSTS: Record<string, number> = {
  default: 1,
  "file-upload": 5,
  search: 3,
  "heavy-query": 3,
  export: 5,
  import: 5,
  "bulk-operation": 10,
};

// ============================================================================
// Utility Functions
// ============================================================================

export function parseWindowString(window: string): number {
  const match = window.match(/^(\d+)(s|m|h|d)$/);
  if (!match) {
    throw new Error(`Invalid window format: ${window}. Use format like '1m', '15m', '1h', '1d'`);
  }

  const value = parseInt(match[1], 10);
  const unit = match[2];

  switch (unit) {
    case "s": return value * 1000;
    case "m": return value * 60 * 1000;
    case "h": return value * 60 * 60 * 1000;
    case "d": return value * 24 * 60 * 60 * 1000;
    default: throw new Error(`Unknown time unit: ${unit}`);
  }
}

function getIpFromRequest(req: FastifyRequest): string {
  return req.ip || "unknown";
}

function getUserBasedKey(req: FastifyRequest): string {
  if (req.user?.userId) {
    return `user:${req.user.userId}`;
  }
  return `ip:${getIpFromRequest(req)}`;
}

function getIpBasedKey(req: FastifyRequest): string {
  return `ip:${getIpFromRequest(req)}`;
}

function getUserPlan(req: FastifyRequest): UserPlan {
  const plan = (req.user as { plan?: string } | undefined)?.plan;
  if (plan && plan in PLAN_LIMITS) {
    return plan as UserPlan;
  }
  return "free";
}

function setRateLimitHeaders(reply: FastifyReply, info: RateLimitInfo): void {
  reply.header("X-RateLimit-Limit", info.limit);
  reply.header("X-RateLimit-Remaining", Math.max(0, info.remaining));
  reply.header("X-RateLimit-Reset", info.resetTime);
}

function setRetryAfterHeader(reply: FastifyReply, retryAfterSeconds: number): void {
  reply.header("Retry-After", retryAfterSeconds);
}

// ============================================================================
// In-Memory Store Implementation
// ============================================================================

class MemoryStore implements RateLimitStore {
  private store: Map<string, SlidingWindowEntry> = new Map();
  private cleanupInterval: NodeJS.Timeout | null = null;

  constructor() {
    this.cleanupInterval = setInterval(() => this.cleanup(), 60000);
  }

  async get(key: string): Promise<SlidingWindowEntry | null> {
    return this.store.get(key) || null;
  }

  async set(key: string, entry: SlidingWindowEntry, _windowMs: number): Promise<void> {
    this.store.set(key, entry);
  }

  async increment(key: string, points: number, windowMs: number): Promise<SlidingWindowEntry> {
    const now = Date.now();
    const windowStart = now - windowMs;

    let entry = this.store.get(key);

    if (!entry) {
      entry = { timestamps: [], points: 0 };
    }

    entry.timestamps = entry.timestamps.filter((ts) => ts > windowStart);
    entry.timestamps.push(now);
    entry.points = entry.timestamps.length * points;

    this.store.set(key, entry);
    return entry;
  }

  async close(): Promise<void> {
    if (this.cleanupInterval) {
      clearInterval(this.cleanupInterval);
      this.cleanupInterval = null;
    }
    this.store.clear();
  }

  private cleanup(): void {
    const now = Date.now();

    for (const [key, entry] of this.store.entries()) {
      if (entry.timestamps.length === 0 || entry.timestamps[entry.timestamps.length - 1] < now - MAX_WINDOW_MS) {
        this.store.delete(key);
      }
    }
  }
}

// ============================================================================
// Redis Store Implementation (Optional)
// ============================================================================

interface RedisClientType {
  connect(): Promise<void>;
  quit(): Promise<void>;
  on(event: string, callback: (arg?: unknown) => void): void;
  zRangeWithScores(key: string, start: number, end: number): Promise<Array<{ score: number; value: string }>>;
  zRemRangeByScore(key: string, min: number, max: number): Promise<number>;
  zAdd(key: string, member: { score: number; value: string }): Promise<number>;
  del(key: string): Promise<number>;
  expire(key: string, seconds: number): Promise<boolean>;
  multi(): RedisMultiType;
}

interface RedisMultiType {
  del(key: string): RedisMultiType;
  zAdd(key: string, member: { score: number; value: string }): RedisMultiType;
  zRemRangeByScore(key: string, min: number, max: number): RedisMultiType;
  zRangeWithScores(key: string, start: number, end: number): RedisMultiType;
  expire(key: string, seconds: number): RedisMultiType;
  exec(): Promise<unknown[]>;
}

class RedisStore implements RateLimitStore {
  private client: RedisClientType | null = null;
  private isConnected: boolean = false;
  private connectionPromise: Promise<void> | null = null;

  constructor(private redisUrl: string) {}

  async connect(): Promise<void> {
    if (this.connectionPromise) return this.connectionPromise;
    this.connectionPromise = this.initConnection();
    return this.connectionPromise;
  }

  private async initConnection(): Promise<void> {
    try {
      const redis = await import("redis");
      // The redis package's createClient return type doesn't exactly match our
      // RedisClientType interface (which declares only the subset of methods we use).
      // A single assertion is acceptable here since the runtime API is compatible.
      this.client = redis.createClient({ url: this.redisUrl }) as unknown as RedisClientType;

      this.client.on("error", (err: unknown) => {
        const message = err instanceof Error ? err.message : String(err);
        logger.error("[rate-limit] Redis client error", { error: message });
        this.isConnected = false;
      });

      this.client.on("connect", () => {
        logger.info("[rate-limit] Redis connected");
        this.isConnected = true;
      });

      this.client.on("disconnect", () => {
        logger.warn("[rate-limit] Redis disconnected");
        this.isConnected = false;
      });

      await this.client.connect();
      this.isConnected = true;
    } catch (error) {
      logger.error("[rate-limit] Failed to connect to Redis", { error: error instanceof Error ? error.message : String(error) });
      this.isConnected = false;
      throw error;
    }
  }

  async get(key: string): Promise<SlidingWindowEntry | null> {
    if (!this.isConnected || !this.client) return null;

    try {
      const data = await this.client.zRangeWithScores(key, 0, -1);
      if (!data || data.length === 0) return null;

      const timestamps = data.map((item: { score: number }) => item.score);
      const points = data.reduce((sum: number, item: { value: string }) => sum + parseInt(item.value, 10), 0);
      return { timestamps, points };
    } catch (error) {
      logger.error("[rate-limit] Redis get error", { error: error instanceof Error ? error.message : String(error) });
      return null;
    }
  }

  async set(key: string, entry: SlidingWindowEntry, windowMs: number): Promise<void> {
    if (!this.isConnected || !this.client) return;

    try {
      const pipeline = this.client.multi();
      pipeline.del(key);
      for (const ts of entry.timestamps) {
        pipeline.zAdd(key, { score: ts, value: "1" });
      }
      pipeline.expire(key, Math.ceil(windowMs / 1000) + 60);
      await pipeline.exec();
    } catch (error) {
      logger.error("[rate-limit] Redis set error", { error: error instanceof Error ? error.message : String(error) });
    }
  }

  async increment(key: string, points: number, windowMs: number): Promise<SlidingWindowEntry> {
    if (!this.isConnected || !this.client) return { timestamps: [], points: 0 };

    try {
      const now = Date.now();
      const windowStart = now - windowMs;

      const pipeline = this.client.multi();
      pipeline.zRemRangeByScore(key, 0, windowStart);
      pipeline.zAdd(key, { score: now, value: String(points) });
      pipeline.zRangeWithScores(key, 0, -1);
      pipeline.expire(key, Math.ceil(windowMs / 1000) + 60);

      const results = await pipeline.exec();
      const rangeResult = results[2] as Array<{ score: number; value: string }> | null;

      if (!rangeResult) return { timestamps: [now], points };

      const timestamps = rangeResult.map((item) => item.score);
      const totalPoints = rangeResult.reduce((sum, item) => sum + parseInt(item.value, 10), 0);
      return { timestamps, points: totalPoints };
    } catch (error) {
      logger.error("[rate-limit] Redis increment error", { error: error instanceof Error ? error.message : String(error) });
      return { timestamps: [], points: 0 };
    }
  }

  async close(): Promise<void> {
    if (this.client && this.isConnected) {
      await this.client.quit();
      this.isConnected = false;
    }
  }
}

// ============================================================================
// Store Factory
// ============================================================================

let sharedStore: RateLimitStore | null = null;

export async function getStore(): Promise<RateLimitStore> {
  if (sharedStore) return sharedStore;

  const redisUrl = process.env.REDIS_URL;

  if (redisUrl) {
    try {
      const redisStore = new RedisStore(redisUrl);
      await redisStore.connect();
      sharedStore = redisStore;
      logger.info("[rate-limit] Using Redis store");
      return sharedStore;
    } catch (error) {
      logger.warn("[rate-limit] Redis connection failed, falling back to memory store", { error: error instanceof Error ? error.message : String(error) });
    }
  }

  sharedStore = new MemoryStore();
  logger.info("[rate-limit] Using in-memory store");
  return sharedStore;
}

// Shared in-memory store for all specific rate limiters (single cleanup interval)
const endpointStore = new MemoryStore();

function getEndpointStore(): MemoryStore {
  return endpointStore;
}

// Registry of stores created inside factory functions (createCostBasedLimiter,
// createPlanBasedLimiter). Each factory call creates a new MemoryStore with its own
// setInterval timer; without registry tracking these intervals leak forever (MED-12).
const factoryStores = new Set<{ close: () => void | Promise<void> }>();

function registerFactoryStore(store: { close: () => void | Promise<void> }): void {
  factoryStores.add(store);
}

// ============================================================================
// Fastify Rate Limiter Registration
// ============================================================================

/**
 * Register the general rate limiter using @fastify/rate-limit plugin
 */
export async function registerRateLimiter(app: FastifyInstance): Promise<void> {
  await app.register(fastifyRateLimit, {
    max: config.rateLimit.maxRequests,
    timeWindow: config.rateLimit.windowMs,
    keyGenerator: (req: FastifyRequest) => req.ip,
    errorResponseBuilder: (_req: FastifyRequest, context) => ({
      success: false,
      error: {
        code: "RATE_LIMIT_EXCEEDED",
        message: "Too many requests, please try again later",
        retryAfter: Math.ceil(context.ttl / 1000),
      },
    }),
  });
}

// ============================================================================
// Specific Rate Limiter Hooks (preHandler)
// ============================================================================

/**
 * Create an auth rate limiter preHandler hook
 */
function createRateLimiterHook(options: {
  windowMs: number;
  maxRequests: number;
  keyGenerator: "ip" | "user";
  errorCode: string;
  errorMessage: string;
}): (req: FastifyRequest, reply: FastifyReply) => Promise<void> {
  const store = getEndpointStore();
  const keyGen = options.keyGenerator === "ip" ? getIpBasedKey : getUserBasedKey;

  return async (req: FastifyRequest, reply: FastifyReply): Promise<void> => {
    try {
      const key = `ratelimit:${options.errorCode.toLowerCase()}:${keyGen(req)}`;
      const now = Date.now();
      const windowStart = now - options.windowMs;

      const entry = await store.increment(key, 1, options.windowMs);
      const requestCount = entry.timestamps.filter((ts) => ts > windowStart).length;
      const resetTime = Math.ceil((now + options.windowMs) / 1000);

      setRateLimitHeaders(reply, {
        limit: options.maxRequests,
        remaining: options.maxRequests - requestCount,
        resetTime,
      });

      if (requestCount > options.maxRequests) {
        const retryAfterSeconds = Math.ceil(options.windowMs / 1000);
        setRetryAfterHeader(reply, retryAfterSeconds);
        return reply.code(429).send({
          success: false,
          error: {
            code: options.errorCode,
            message: options.errorMessage,
            retryAfter: retryAfterSeconds,
          },
        });
      }
    } catch (error) {
      logger.error(`[rate-limit] ${options.errorCode} error (denying request)`, { error: error instanceof Error ? error.message : String(error) });
      return reply.code(503).send({
        success: false,
        error: {
          code: "SERVICE_UNAVAILABLE",
          message: "Rate limiting service unavailable, please try again shortly",
        },
      });
    }
  };
}

export const authRateLimiter = createRateLimiterHook({
  windowMs: 15 * 60 * 1000,
  maxRequests: config.isTest() ? 10000 : 10,
  keyGenerator: "ip",
  errorCode: "AUTH_RATE_LIMIT_EXCEEDED",
  errorMessage: "Too many authentication attempts, please try again in 15 minutes",
});

export const userRateLimiter = createRateLimiterHook({
  windowMs: 60 * 1000,
  maxRequests: 60,
  keyGenerator: "user",
  errorCode: "USER_RATE_LIMIT_EXCEEDED",
  errorMessage: "Too many requests, please slow down",
});

export const sensitiveRateLimiter = createRateLimiterHook({
  windowMs: 60 * 60 * 1000,
  maxRequests: 5,
  keyGenerator: "user",
  errorCode: "SENSITIVE_RATE_LIMIT_EXCEEDED",
  errorMessage: "Too many attempts for this sensitive operation, please try again later",
});

export const apiKeyRateLimiter = createRateLimiterHook({
  windowMs: 60 * 1000,
  maxRequests: 120,
  keyGenerator: "ip",
  errorCode: "API_RATE_LIMIT_EXCEEDED",
  errorMessage: "API rate limit exceeded",
});

/**
 * Stricter rate limiter for authentication endpoints (alias for backward compat)
 */
export const generalRateLimiter = authRateLimiter;

// ============================================================================
// Sliding Window Rate Limiter Factory
// ============================================================================

export function createSlidingWindowLimiter(options: {
  windowMs: number;
  maxRequests: number;
  keyGenerator?: "ip" | "user" | ((req: FastifyRequest) => string);
  errorCode?: string;
  errorMessage?: string;
  store?: RateLimitStore;
}): (req: FastifyRequest, reply: FastifyReply) => Promise<void> {
  const {
    windowMs,
    maxRequests,
    keyGenerator = "ip",
    errorCode = "RATE_LIMIT_EXCEEDED",
    errorMessage = "Too many requests, please try again later",
  } = options;

  const store = options.store || getEndpointStore();

  let keyGen: (req: FastifyRequest) => string;
  if (keyGenerator === "ip") {
    keyGen = getIpBasedKey;
  } else if (keyGenerator === "user") {
    keyGen = getUserBasedKey;
  } else {
    keyGen = keyGenerator;
  }

  return async (req: FastifyRequest, reply: FastifyReply): Promise<void> => {
    try {
      const key = `ratelimit:sliding:${keyGen(req)}`;
      const now = Date.now();
      const windowStart = now - windowMs;

      const entry = await store.increment(key, 1, windowMs);
      const requestCount = entry.timestamps.filter((ts) => ts > windowStart).length;
      const resetTime = Math.ceil((now + windowMs) / 1000);

      setRateLimitHeaders(reply, {
        limit: maxRequests,
        remaining: maxRequests - requestCount,
        resetTime,
      });

      if (requestCount > maxRequests) {
        const retryAfterSeconds = Math.ceil(windowMs / 1000);
        setRetryAfterHeader(reply, retryAfterSeconds);
        return reply.code(429).send({
          success: false,
          error: {
            code: errorCode,
            message: errorMessage,
            retryAfter: retryAfterSeconds,
          },
        });
      }
    } catch (error) {
      logger.error("[rate-limit] Sliding window error (denying request)", { error: error instanceof Error ? error.message : String(error) });
      return reply.code(503).send({
        success: false,
        error: {
          code: "SERVICE_UNAVAILABLE",
          message: "Rate limiting service unavailable, please try again shortly",
        },
      });
    }
  };
}

// ============================================================================
// Cost-Based Rate Limiter
// ============================================================================

interface CostTrackingEntry {
  requests: Array<{ timestamp: number; cost: number }>;
  totalCost: number;
}

class CostBasedMemoryStore {
  private store: Map<string, CostTrackingEntry> = new Map();
  private cleanupInterval: NodeJS.Timeout | null = null;

  constructor() {
    this.cleanupInterval = setInterval(() => this.cleanup(), 60000);
  }

  increment(key: string, cost: number, windowMs: number): CostTrackingEntry {
    const now = Date.now();
    const windowStart = now - windowMs;

    let entry = this.store.get(key);
    if (!entry) {
      entry = { requests: [], totalCost: 0 };
    }

    entry.requests = entry.requests.filter((r) => r.timestamp > windowStart);
    entry.requests.push({ timestamp: now, cost });
    entry.totalCost = entry.requests.reduce((sum, r) => sum + r.cost, 0);

    this.store.set(key, entry);
    return entry;
  }

  get(key: string): CostTrackingEntry | null {
    return this.store.get(key) || null;
  }

  close(): void {
    if (this.cleanupInterval) {
      clearInterval(this.cleanupInterval);
      this.cleanupInterval = null;
    }
    this.store.clear();
  }

  private cleanup(): void {
    const now = Date.now();

    for (const [key, entry] of this.store.entries()) {
      if (entry.requests.length === 0 || entry.requests[entry.requests.length - 1].timestamp < now - MAX_WINDOW_MS) {
        this.store.delete(key);
      }
    }
  }
}

export function createCostBasedLimiter(
  costs: Record<string, number>,
  options?: {
    windowMs?: number;
    maxPoints?: number;
    keyGenerator?: "ip" | "user" | ((req: FastifyRequest) => string);
    getCostKey?: (req: FastifyRequest) => string;
    errorCode?: string;
    errorMessage?: string;
  }
): (req: FastifyRequest, reply: FastifyReply) => Promise<void> {
  const {
    windowMs = 60000,
    maxPoints = 100,
    keyGenerator = "user",
    getCostKey = (req: FastifyRequest) => {
      const costHeader = req.headers["x-request-cost-key"];
      if (typeof costHeader === "string") return costHeader;
      return "default";
    },
    errorCode = "RATE_LIMIT_EXCEEDED",
    errorMessage = "Rate limit exceeded. Some operations cost more points.",
  } = options || {};

  const store = new CostBasedMemoryStore();
  registerFactoryStore(store);

  let keyGen: (req: FastifyRequest) => string;
  if (keyGenerator === "ip") {
    keyGen = getIpBasedKey;
  } else if (keyGenerator === "user") {
    keyGen = getUserBasedKey;
  } else {
    keyGen = keyGenerator;
  }

  return async (req: FastifyRequest, reply: FastifyReply): Promise<void> => {
    try {
      const key = `ratelimit:cost:${keyGen(req)}`;
      const costKey = getCostKey(req);
      const cost = costs[costKey] ?? costs.default ?? 1;

      const now = Date.now();
      const entry = store.increment(key, cost, windowMs);
      const resetTime = Math.ceil((now + windowMs) / 1000);

      setRateLimitHeaders(reply, {
        limit: maxPoints,
        remaining: maxPoints - entry.totalCost,
        resetTime,
      });

      reply.header("X-RateLimit-Cost", cost);

      if (entry.totalCost > maxPoints) {
        const retryAfterSeconds = Math.ceil(windowMs / 1000);
        setRetryAfterHeader(reply, retryAfterSeconds);
        return reply.code(429).send({
          success: false,
          error: {
            code: errorCode,
            message: errorMessage,
            retryAfter: retryAfterSeconds,
            pointsUsed: entry.totalCost,
            pointsLimit: maxPoints,
          },
        });
      }
    } catch (error) {
      logger.error("[rate-limit] Cost-based limiter error (denying request)", { error: error instanceof Error ? error.message : String(error) });
      return reply.code(503).send({
        success: false,
        error: {
          code: "SERVICE_UNAVAILABLE",
          message: "Rate limiting service unavailable, please try again shortly",
        },
      });
    }
  };
}

// ============================================================================
// Plan-Based Rate Limiter
// ============================================================================

export function createPlanBasedLimiter(options?: {
  planLimits?: Record<UserPlan, PlanLimitConfig>;
  keyGenerator?: "ip" | "user" | ((req: FastifyRequest) => string);
  getPlan?: (req: FastifyRequest) => UserPlan;
  errorCode?: string;
  errorMessage?: string;
}): (req: FastifyRequest, reply: FastifyReply) => Promise<void> {
  const {
    planLimits = PLAN_LIMITS,
    keyGenerator = "user",
    getPlan = getUserPlan,
    errorCode = "RATE_LIMIT_EXCEEDED",
    errorMessage = "Rate limit exceeded for your plan",
  } = options || {};

  const store = new CostBasedMemoryStore();
  registerFactoryStore(store);

  let keyGen: (req: FastifyRequest) => string;
  if (keyGenerator === "ip") {
    keyGen = getIpBasedKey;
  } else if (keyGenerator === "user") {
    keyGen = getUserBasedKey;
  } else {
    keyGen = keyGenerator;
  }

  return async (req: FastifyRequest, reply: FastifyReply): Promise<void> => {
    try {
      const plan = getPlan(req);
      const limits = planLimits[plan] || planLimits.free;
      const windowMs = parseWindowString(limits.window);
      const maxRequests = limits.requests;

      const key = `ratelimit:plan:${plan}:${keyGen(req)}`;
      const now = Date.now();

      const entry = store.increment(key, 1, windowMs);
      const requestCount = entry.requests.length;
      const resetTime = Math.ceil((now + windowMs) / 1000);

      setRateLimitHeaders(reply, {
        limit: maxRequests,
        remaining: maxRequests - requestCount,
        resetTime,
      });

      reply.header("X-RateLimit-Plan", plan);

      if (requestCount > maxRequests) {
        const retryAfterSeconds = Math.ceil(windowMs / 1000);
        setRetryAfterHeader(reply, retryAfterSeconds);
        return reply.code(429).send({
          success: false,
          error: {
            code: errorCode,
            message: errorMessage,
            retryAfter: retryAfterSeconds,
            plan,
            limit: maxRequests,
          },
        });
      }
    } catch (error) {
      logger.error("[rate-limit] Plan-based limiter error (allowing request)", { error: error instanceof Error ? error.message : String(error) });
    }
  };
}

// ============================================================================
// Custom Rate Limiter Factory
// ============================================================================

export function createRateLimiter(options: {
  windowMs: number;
  maxRequests: number;
  keyGenerator?: "ip" | "user" | ((req: FastifyRequest) => string);
  errorCode?: string;
  errorMessage?: string;
}): (req: FastifyRequest, reply: FastifyReply) => Promise<void> {
  return createRateLimiterHook({
    windowMs: options.windowMs,
    maxRequests: options.maxRequests,
    keyGenerator: typeof options.keyGenerator === "function" ? "ip" : (options.keyGenerator || "ip"),
    errorCode: options.errorCode || "RATE_LIMIT_EXCEEDED",
    errorMessage: options.errorMessage || "Too many requests, please try again later",
  });
}

// ============================================================================
// Cleanup
// ============================================================================

export async function cleanupRateLimitStores(): Promise<void> {
  await endpointStore.close();
  if (sharedStore) {
    await sharedStore.close();
    sharedStore = null;
  }
  for (const store of factoryStores) {
    await store.close();
  }
  factoryStores.clear();
}

// ============================================================================
// Convenience Exports
// ============================================================================

export {
  getUserBasedKey as getUserBasedKeyGenerator,
  getIpBasedKey as getIpBasedKeyGenerator,
  getUserPlan,
  setRateLimitHeaders,
  setRetryAfterHeader,
};

export type {
  RateLimitErrorResponse,
  RateLimitInfo,
  RateLimitStore,
  PlanLimitConfig,
  UserPlan,
  SlidingWindowEntry,
  CostTrackingEntry,
};
