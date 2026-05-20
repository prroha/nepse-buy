import { FastifyPluginAsync } from "fastify";
import { watchlistController } from "../controllers/watchlist.controller.js";
import { authMiddleware } from "../middleware/auth.middleware.js";

const routePlugin: FastifyPluginAsync = async (fastify) => {
  fastify.addHook("preHandler", authMiddleware);

  fastify.get("/", (req, reply) => watchlistController.list(req, reply));
  fastify.post("/items", (req, reply) => watchlistController.add(req, reply));
  fastify.delete("/items/:id", (req, reply) => watchlistController.remove(req, reply));
};

export default routePlugin;
