import { FastifyPluginAsync } from "fastify";
import { stockController } from "../controllers/stock.controller.js";
import { authMiddleware } from "../middleware/auth.middleware.js";

const routePlugin: FastifyPluginAsync = async (fastify) => {
  fastify.addHook("preHandler", authMiddleware);

  /**
   * GET /api/v1/stocks
   * List stocks. Query: q, curated, page, limit.
   */
  fastify.get("/", (req, reply) => stockController.list(req, reply));

  /**
   * GET /api/v1/stocks/:symbol
   * Stock detail incl. latest price + fundamentals + recent observations.
   */
  fastify.get("/:symbol", (req, reply) => stockController.get(req, reply));
};

export default routePlugin;
