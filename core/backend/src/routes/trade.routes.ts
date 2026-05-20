import { FastifyPluginAsync } from "fastify";
import { tradeController } from "../controllers/trade.controller.js";
import { authMiddleware } from "../middleware/auth.middleware.js";

const routePlugin: FastifyPluginAsync = async (fastify) => {
  fastify.addHook("preHandler", authMiddleware);

  fastify.get("/", (req, reply) => tradeController.list(req, reply));
  fastify.post("/", (req, reply) => tradeController.logTrade(req, reply));
  fastify.delete("/:id", (req, reply) => tradeController.remove(req, reply));
};

export default routePlugin;
