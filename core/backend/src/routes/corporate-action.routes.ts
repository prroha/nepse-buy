import { FastifyPluginAsync } from "fastify";
import { corporateActionController } from "../controllers/corporate-action.controller.js";
import { authMiddleware } from "../middleware/auth.middleware.js";

const routePlugin: FastifyPluginAsync = async (fastify) => {
  // Reads are public so the stock detail screen works pre-login.
  fastify.get("/", (req, reply) => corporateActionController.list(req, reply));

  // Writes require auth — manual logging only (until we scrape automatically).
  fastify.register(async (authed) => {
    authed.addHook("preHandler", authMiddleware);
    authed.post("/", (req, reply) => corporateActionController.create(req, reply));
    authed.delete("/:id", (req, reply) => corporateActionController.remove(req, reply));
  });
};

export default routePlugin;
