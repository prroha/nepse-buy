import { FastifyPluginAsync } from "fastify";
import { signalController } from "../controllers/signal.controller.js";
import { authMiddleware } from "../middleware/auth.middleware.js";

const routePlugin: FastifyPluginAsync = async (fastify) => {
  fastify.addHook("preHandler", authMiddleware);

  fastify.get("/today", (req, reply) => signalController.today(req, reply));
  fastify.get("/history", (req, reply) => signalController.history(req, reply));
};

export default routePlugin;
