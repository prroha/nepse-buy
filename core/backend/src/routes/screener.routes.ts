import { FastifyPluginAsync } from "fastify";
import { screenerController } from "../controllers/screener.controller.js";

const routePlugin: FastifyPluginAsync = async (fastify) => {
  // Screener is public — no authMiddleware. Discover should work pre-login,
  // matching the anonymous-by-default UX.
  fastify.get("/", (req, reply) => screenerController.rank(req, reply));
};

export default routePlugin;
