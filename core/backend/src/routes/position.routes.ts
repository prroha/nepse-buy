import { FastifyPluginAsync } from "fastify";
import { positionController } from "../controllers/position.controller.js";
import { authMiddleware } from "../middleware/auth.middleware.js";

const routePlugin: FastifyPluginAsync = async (fastify) => {
  fastify.addHook("preHandler", authMiddleware);

  fastify.get("/", (req, reply) => positionController.list(req, reply));
  fastify.post("/purchases", (req, reply) => positionController.addPurchase(req, reply));
  fastify.delete("/:id", (req, reply) => positionController.remove(req, reply));
};

export default routePlugin;
