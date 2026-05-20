import { FastifyPluginAsync } from "fastify";
import { notificationController } from "../controllers/notification.controller.js";
import { authMiddleware } from "../middleware/auth.middleware.js";
import { requireFeature } from "../middleware/preview.middleware.js";

const routePlugin: FastifyPluginAsync = async (fastify) => {
  // Feature Gate: Notifications require comms.push or comms.email feature
  fastify.addHook("preHandler", requireFeature("comms.email"));

  // All notification routes require authentication
  fastify.addHook("preHandler", authMiddleware);

  /**
   * GET /api/v1/notifications
   * Get all notifications for the authenticated user (paginated)
   * Query params: page, limit, read (true/false), type
   */
  fastify.get("/", (req, reply) => notificationController.getAll(req, reply));

  /**
   * GET /api/v1/notifications/unread-count
   * Get the count of unread notifications
   */
  fastify.get("/unread-count", (req, reply) => notificationController.getUnreadCount(req, reply));

  /**
   * PATCH /api/v1/notifications/read-all
   * Mark all notifications as read
   */
  fastify.patch("/read-all", (req, reply) => notificationController.markAllAsRead(req, reply));

  /**
   * GET /api/v1/notifications/:id
   * Get a single notification
   */
  fastify.get("/:id", (req, reply) => notificationController.getById(req, reply));

  /**
   * PATCH /api/v1/notifications/:id/read
   * Mark a notification as read
   */
  fastify.patch("/:id/read", (req, reply) => notificationController.markAsRead(req, reply));

  /**
   * DELETE /api/v1/notifications/:id
   * Delete a single notification
   */
  fastify.delete("/:id", (req, reply) => notificationController.delete(req, reply));

  /**
   * DELETE /api/v1/notifications
   * Delete all notifications for the authenticated user
   */
  fastify.delete("/", (req, reply) => notificationController.deleteAll(req, reply));
};

export default routePlugin;
