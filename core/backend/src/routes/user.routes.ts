import { FastifyPluginAsync } from "fastify";
import { userController } from "../controllers/user.controller.js";
import { authMiddleware } from "../middleware/auth.middleware.js";

const routePlugin: FastifyPluginAsync = async (fastify) => {
  // All user routes are protected
  fastify.addHook("preHandler", authMiddleware);

  // GET /api/v1/users/me - Get current user profile
  fastify.get("/me", (req, reply) => userController.getProfile(req, reply));

  // PATCH /api/v1/users/me - Update current user profile
  fastify.patch("/me", (req, reply) => userController.updateProfile(req, reply));

  // GET /api/v1/users/me/avatar - Get current user avatar
  fastify.get("/me/avatar", (req, reply) => userController.getAvatar(req, reply));

  // POST /api/v1/users/me/avatar - Upload avatar
  fastify.post("/me/avatar", (req, reply) => userController.uploadAvatar(req, reply));

  // DELETE /api/v1/users/me/avatar - Delete avatar
  fastify.delete("/me/avatar", (req, reply) => userController.deleteAvatar(req, reply));

  // GET /api/v1/users/me/export - Export current user's data (GDPR)
  fastify.get("/me/export", (req, reply) => userController.exportMyData(req, reply));
};

export default routePlugin;
