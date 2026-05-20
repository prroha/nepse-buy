/**
 * Preview Mode Middleware
 *
 * Detects preview sessions and injects feature configuration into the request.
 * Features can then check req.previewConfig to determine if they're enabled.
 *
 * This file is located in _preview/ directory and is excluded from user downloads.
 * In preview mode (PREVIEW_MODE=true), this middleware is loaded dynamically.
 */

import { FastifyRequest, FastifyReply } from "fastify";
import fs from "fs";
import path from "path";
import { logger } from "../../lib/logger.js";

export interface PreviewConfig {
  isPreview: boolean;
  sessionToken: string | null;
  enabledFeatures: string[];
  tier: string | null;
}

const STUDIO_API_URL = process.env.STUDIO_API_URL || "http://localhost:8001";

// Cache TTL in milliseconds (5 minutes)
const CACHE_TTL_MS = 5 * 60 * 1000;

/**
 * In-memory cache for session configurations
 * Caches Studio API responses to reduce external calls
 */
interface CacheEntry {
  data: PreviewConfig;
  expiresAt: number;
}

const sessionConfigCache = new Map<string, CacheEntry>();

/**
 * Get cached session config if valid
 * @param token Session token (cache key)
 * @returns Cached PreviewConfig or null if not found/expired
 */
function getCachedConfig(token: string): PreviewConfig | null {
  const entry = sessionConfigCache.get(token);

  if (!entry) {
    return null;
  }

  // Check if cache entry has expired
  if (Date.now() > entry.expiresAt) {
    sessionConfigCache.delete(token);
    return null;
  }

  return entry.data;
}

/**
 * Set session config in cache
 * @param token Session token (cache key)
 * @param config PreviewConfig to cache
 */
function setCachedConfig(token: string, config: PreviewConfig): void {
  sessionConfigCache.set(token, {
    data: config,
    expiresAt: Date.now() + CACHE_TTL_MS,
  });
}

/**
 * Invalidate a specific cache entry
 * @param token Session token to invalidate
 */
export function invalidateSessionCache(token: string): void {
  sessionConfigCache.delete(token);
}

/**
 * Clear all expired entries from cache
 * Called periodically to prevent memory leaks
 */
function cleanExpiredCache(): void {
  const now = Date.now();
  for (const [token, entry] of sessionConfigCache.entries()) {
    if (now > entry.expiresAt) {
      sessionConfigCache.delete(token);
    }
  }
}

// Clean expired cache entries every 5 minutes
setInterval(cleanExpiredCache, CACHE_TTL_MS);

/**
 * Response type from Studio API preview session endpoint
 */
interface PreviewSessionResponse {
  success: boolean;
  data?: {
    selectedFeatures: string[];
    tier: string;
  };
}

/**
 * Starter config structure from starter-config.json
 */
interface StarterConfig {
  tier: string;
  template: string | null;
  features: string[];
  license: {
    key: string | null;
    issuedAt: string;
    orderNumber: string;
    customerEmail: string;
  };
  generatedAt: string;
}

// Cache for starter config (loaded once at startup)
let cachedStarterConfig: StarterConfig | null = null;
let configLoaded = false;

/**
 * Load starter-config.json if it exists
 */
function loadStarterConfig(): StarterConfig | null {
  if (configLoaded) {
    return cachedStarterConfig;
  }

  configLoaded = true;

  // Look for starter-config.json in project root (parent of backend)
  const configPaths = [
    path.resolve(process.cwd(), "..", "starter-config.json"),
    path.resolve(process.cwd(), "starter-config.json"),
  ];

  for (const configPath of configPaths) {
    try {
      if (fs.existsSync(configPath)) {
        const content = fs.readFileSync(configPath, "utf-8");
        cachedStarterConfig = JSON.parse(content) as StarterConfig;
        logger.info(`Loaded starter config from ${configPath}`);
        logger.debug(`Enabled features: ${cachedStarterConfig.features.join(", ")}`);
        return cachedStarterConfig;
      }
    } catch (error) {
      logger.warn(`Failed to load starter config from ${configPath}`, { error: String(error) });
    }
  }

  return null;
}

// Pre-load config at module initialization
loadStarterConfig();

/**
 * Middleware that detects preview mode and fetches session configuration
 */
export async function previewMiddleware(
  req: FastifyRequest
): Promise<void> {
  // Check for preview token in header or query
  const previewToken =
    (req.headers["x-preview-session"] as string) ||
    ((req.query as Record<string, string>)?.preview);

  // If preview token exists, check cache first, then fetch from Studio API
  if (previewToken) {
    // Check cache first
    const cachedConfig = getCachedConfig(previewToken);
    if (cachedConfig) {
      req.previewConfig = cachedConfig;
      return;
    }

    // Default config if fetch fails
    req.previewConfig = {
      isPreview: true,
      sessionToken: previewToken,
      enabledFeatures: [],
      tier: null,
    };

    try {
      // Fetch session config from Studio API
      const response = await fetch(
        `${STUDIO_API_URL}/api/preview/sessions/${previewToken}`
      );

      if (response.ok) {
        const data = (await response.json()) as PreviewSessionResponse;

        if (data.success && data.data) {
          req.previewConfig = {
            isPreview: true,
            sessionToken: previewToken,
            enabledFeatures: data.data.selectedFeatures,
            tier: data.data.tier,
          };

          // Cache the successful response
          setCachedConfig(previewToken, req.previewConfig);
        }
      }
    } catch (error) {
      logger.warn("Failed to fetch preview session", { error: String(error) });
    }

    return;
  }

  // Not in preview mode - check for starter-config.json
  const starterConfig = loadStarterConfig();

  if (starterConfig) {
    // Use features from starter-config.json
    req.previewConfig = {
      isPreview: false,
      sessionToken: null,
      enabledFeatures: starterConfig.features,
      tier: starterConfig.tier,
    };
  } else {
    // No config found - allow all features (development mode)
    req.previewConfig = {
      isPreview: false,
      sessionToken: null,
      enabledFeatures: [],
      tier: null,
    };
  }
}

/**
 * Route guard that checks if a feature is enabled
 * Usage: fastify.get("/path", { preHandler: [requireFeature("payments.stripe")] }, handler)
 *
 * Works in both modes:
 * - Preview mode: checks against session features from Studio API
 * - Deployed mode: checks against features from starter-config.json
 * - Development mode (no config): allows all features
 */
export function requireFeature(featureSlug: string) {
  return async (req: FastifyRequest, reply: FastifyReply): Promise<void> => {
    const config = req.previewConfig;
    if (!config) return;

    const { enabledFeatures } = config;

    // If no features are configured, allow all (development mode)
    if (enabledFeatures.length === 0) {
      return;
    }

    // Check if feature is enabled
    if (enabledFeatures.includes(featureSlug)) {
      return;
    }

    // Feature not enabled in this configuration
    reply.code(404).send({
      success: false,
      error: "Feature not available in this configuration",
    });
  };
}

/**
 * Helper to check if a feature is enabled
 *
 * Works in both modes:
 * - Preview mode: checks against session features from Studio API
 * - Deployed mode: checks against features from starter-config.json
 * - Development mode (no config): returns true for all features
 */
export function isFeatureEnabled(req: FastifyRequest, featureSlug: string): boolean {
  const config = req.previewConfig;
  if (!config) return true;

  const { enabledFeatures } = config;

  // If no features are configured, allow all (development mode)
  if (enabledFeatures.length === 0) {
    return true;
  }

  return enabledFeatures.includes(featureSlug);
}

/**
 * Get the loaded starter config (useful for accessing tier, template, etc.)
 */
export function getStarterConfig(): StarterConfig | null {
  return cachedStarterConfig;
}
