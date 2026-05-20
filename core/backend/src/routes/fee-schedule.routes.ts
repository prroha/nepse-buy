import { FastifyPluginAsync } from "fastify";
import { feeScheduleController } from "../controllers/fee-schedule.controller.js";
import { authMiddleware } from "../middleware/auth.middleware.js";

const routePlugin: FastifyPluginAsync = async (fastify) => {
  fastify.addHook("preHandler", authMiddleware);

  fastify.get("/", (req, reply) => feeScheduleController.get(req, reply));
  fastify.patch("/", (req, reply) => feeScheduleController.update(req, reply));
};

export default routePlugin;
