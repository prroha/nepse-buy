/**
 * Config Routes
 *
 * Exposes application configuration to the frontend.
 * In deployed mode, reads from starter-config.json to provide
 * feature flags and tier information.
 */

import { FastifyPluginAsync } from "fastify";
import { getStarterConfig } from "../middleware/preview.middleware.js";

const routePlugin: FastifyPluginAsync = async (fastify) => {
  /**
   * GET /api/config
   *
   * Returns the application configuration including enabled features.
   * This is used by the frontend to determine which features are available.
   */
  fastify.get("/", (_req, reply) => {
    const starterConfig = getStarterConfig();

    if (starterConfig) {
      // Return config from starter-config.json
      reply.send({
        success: true,
        data: {
          tier: starterConfig.tier,
          template: starterConfig.template,
          features: starterConfig.features,
          generatedAt: starterConfig.generatedAt,
        },
      });
    } else {
      // No starter config - development mode
      reply.send({
        success: true,
        data: {
          tier: null,
          template: null,
          features: [], // Empty means all features enabled
          generatedAt: null,
        },
      });
    }
  });

  /**
   * GET /api/config/features
   *
   * Returns just the list of enabled features.
   */
  fastify.get("/features", (_req, reply) => {
    const starterConfig = getStarterConfig();

    reply.send({
      success: true,
      data: starterConfig?.features || [],
    });
  });

  /**
   * GET /api/config/features/:slug
   *
   * Check if a specific feature is enabled.
   */
  fastify.get("/features/:slug", (req, reply) => {
    const { slug } = req.params as { slug: string };
    const starterConfig = getStarterConfig();

    // If no config, all features are enabled (development mode)
    const isEnabled = starterConfig
      ? starterConfig.features.includes(slug)
      : true;

    reply.send({
      success: true,
      data: {
        slug,
        enabled: isEnabled,
      },
    });
  });
};

export default routePlugin;
