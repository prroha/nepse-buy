import { FastifyRequest, FastifyReply } from "fastify";
import { notificationService } from "../services/notification.service.js";
import { successResponse, paginatedResponse, errorResponse, ErrorCodes } from "../utils/response.js";
import { z } from "zod";
import { AuthenticatedRequest } from "../types/index.js";
import { NotificationType } from "@prisma/client";

// ============================================================================
// Validation Schemas
// ============================================================================

const getNotificationsSchema = z.object({
  page: z.coerce.number().min(1).default(1),
  limit: z.coerce.number().min(1).max(100).default(20),
  read: z
    .enum(["true", "false"])
    .optional()
    .transform((val) => (val === undefined ? undefined : val === "true")),
  type: z.nativeEnum(NotificationType).optional(),
});

// ============================================================================
// Controller Class
// ============================================================================

class NotificationController {
  /**
   * Helper to get userId with proper type checking
   */
  private getUserId(req: FastifyRequest, reply: FastifyReply): string | null {
    const authReq = req as AuthenticatedRequest;
    if (!authReq.user?.userId) {
      reply.code(401).send(
        errorResponse(ErrorCodes.AUTH_REQUIRED, "Authentication required")
      );
      return null;
    }
    return authReq.user.userId;
  }

  /**
   * Get all notifications for the authenticated user
   * GET /api/v1/notifications
   */
  async getAll(req: FastifyRequest, reply: FastifyReply) {
    const userId = this.getUserId(req, reply);
    if (!userId) return;

    const params = getNotificationsSchema.parse(req.query);
    const result = await notificationService.getAll({
      userId,
      ...params,
    });

    return reply.send(
      paginatedResponse(
        result.items,
        result.pagination.page,
        result.pagination.limit,
        result.pagination.total
      )
    );
  }

  /**
   * Get unread notification count for the authenticated user
   * GET /api/v1/notifications/unread-count
   */
  async getUnreadCount(req: FastifyRequest, reply: FastifyReply) {
    const userId = this.getUserId(req, reply);
    if (!userId) return;

    const count = await notificationService.getUnreadCount(userId);

    return reply.send(successResponse({ count }));
  }

  /**
   * Get a single notification
   * GET /api/v1/notifications/:id
   */
  async getById(req: FastifyRequest, reply: FastifyReply) {
    const userId = this.getUserId(req, reply);
    if (!userId) return;

    const id = (req.params as Record<string, string>).id;
    const notification = await notificationService.getById(id, userId);

    return reply.send(successResponse({ notification }));
  }

  /**
   * Mark a notification as read
   * PATCH /api/v1/notifications/:id/read
   */
  async markAsRead(req: FastifyRequest, reply: FastifyReply) {
    const userId = this.getUserId(req, reply);
    if (!userId) return;

    const id = (req.params as Record<string, string>).id;
    const notification = await notificationService.markAsRead(id, userId);

    return reply.send(successResponse({ notification }, "Notification marked as read"));
  }

  /**
   * Mark all notifications as read
   * PATCH /api/v1/notifications/read-all
   */
  async markAllAsRead(req: FastifyRequest, reply: FastifyReply) {
    const userId = this.getUserId(req, reply);
    if (!userId) return;

    const result = await notificationService.markAllAsRead(userId);

    return reply.send(successResponse(result, "All notifications marked as read"));
  }

  /**
   * Delete a notification
   * DELETE /api/v1/notifications/:id
   */
  async delete(req: FastifyRequest, reply: FastifyReply) {
    const userId = this.getUserId(req, reply);
    if (!userId) return;

    const id = (req.params as Record<string, string>).id;
    await notificationService.delete(id, userId);

    return reply.send(successResponse(null, "Notification deleted successfully"));
  }

  /**
   * Delete all notifications
   * DELETE /api/v1/notifications
   */
  async deleteAll(req: FastifyRequest, reply: FastifyReply) {
    const userId = this.getUserId(req, reply);
    if (!userId) return;

    const result = await notificationService.deleteAll(userId);

    return reply.send(successResponse(result, "All notifications deleted successfully"));
  }
}

// ============================================================================
// Singleton Export
// ============================================================================

export const notificationController = new NotificationController();
