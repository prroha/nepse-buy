import { FastifyPluginAsync } from "fastify";
import { adminController } from "../controllers/admin.controller.js";
import { authMiddleware, adminMiddleware } from "../middleware/auth.middleware.js";

const routePlugin: FastifyPluginAsync = async (fastify) => {
  fastify.addHook("preHandler", authMiddleware);
  fastify.addHook("preHandler", adminMiddleware);

  fastify.get("/settings", (req, reply) => adminController.getSettings(req, reply));
  fastify.patch("/settings", (req, reply) => adminController.updateSettings(req, reply));
  fastify.post("/scrape-dividends", (req, reply) => adminController.scrapeDividends(req, reply));
};

export default routePlugin;
