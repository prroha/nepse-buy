import { FastifyPluginAsync } from "fastify";
import { debtController } from "../controllers/debt.controller.js";
import { authMiddleware } from "../middleware/auth.middleware.js";

const routePlugin: FastifyPluginAsync = async (fastify) => {
  fastify.addHook("preHandler", authMiddleware);

  fastify.get("/", (req, reply) => debtController.list(req, reply));
  fastify.post("/", (req, reply) => debtController.create(req, reply));
  fastify.patch("/:id", (req, reply) => debtController.update(req, reply));
  fastify.delete("/:id", (req, reply) => debtController.remove(req, reply));
};

export default routePlugin;
