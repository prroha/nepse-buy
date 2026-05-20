import { db } from "../lib/db.js";
import { NotificationType, Prisma } from "@prisma/client";
import { ApiError } from "../middleware/error.middleware.js";
import { logger } from "../lib/logger.js";

// ============================================================================
// Types
// ============================================================================

export interface CreateNotificationInput {
  userId: string;
  type?: NotificationType;
  title: string;
  message: string;
  data?: Record<string, unknown>;
}

export interface GetNotificationsParams {
  userId: string;
  page?: number;
  limit?: number;
  read?: boolean;
  type?: NotificationType;
}

// ============================================================================
// Service Class
// ============================================================================

class NotificationService {
  /**
   * Create a new notification for a user
   * This method is designed to be called from other services
   */
  async create(input: CreateNotificationInput) {
    const notification = await db.notification.create({
      data: {
        userId: input.userId,
        type: input.type ?? NotificationType.INFO,
        title: input.title,
        message: input.message,
        data: input.data as Prisma.InputJsonValue | undefined,
      },
    });

    logger.info("Notification created", {
      notificationId: notification.id,
      userId: notification.userId,
      type: notification.type,
    });

    return notification;
  }

  /**
   * Create multiple notifications (e.g., broadcast to multiple users)
   */
  async createMany(inputs: CreateNotificationInput[]) {
    const notifications = await db.notification.createMany({
      data: inputs.map((input) => ({
        userId: input.userId,
        type: input.type ?? NotificationType.INFO,
        title: input.title,
        message: input.message,
        data: input.data as Prisma.InputJsonValue | undefined,
      })),
    });

    logger.info("Bulk notifications created", {
      count: notifications.count,
    });

    return notifications;
  }

  /**
   * Get all notifications for a user with pagination
   */
  async getAll(params: GetNotificationsParams) {
    const {
      userId,
      page = 1,
      limit = 20,
      read,
      type,
    } = params;

    const skip = (page - 1) * limit;

    // Build where clause
    const where: {
      userId: string;
      read?: boolean;
      type?: NotificationType;
    } = { userId };

    if (read !== undefined) {
      where.read = read;
    }

    if (type) {
      where.type = type;
    }

    // Execute queries in parallel
    const [notifications, total] = await Promise.all([
      db.notification.findMany({
        where,
        orderBy: { createdAt: "desc" },
        skip,
        take: limit,
      }),
      db.notification.count({ where }),
    ]);

    return {
      items: notifications,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
        hasNext: page < Math.ceil(total / limit),
        hasPrev: page > 1,
      },
    };
  }

  /**
   * Get a single notification by ID
   */
  async getById(id: string, userId: string) {
    const notification = await db.notification.findFirst({
      where: { id, userId },
    });

    if (!notification) {
      throw ApiError.notFound("Notification not found");
    }

    return notification;
  }

  /**
   * Get unread notification count for a user
   */
  async getUnreadCount(userId: string) {
    return db.notification.count({
      where: { userId, read: false },
    });
  }

  /**
   * Mark a notification as read
   */
  async markAsRead(id: string, userId: string) {
    // Check if notification exists and belongs to user
    const existing = await db.notification.findFirst({
      where: { id, userId },
    });

    if (!existing) {
      throw ApiError.notFound("Notification not found");
    }

    const notification = await db.notification.update({
      where: { id },
      data: { read: true },
    });

    logger.info("Notification marked as read", {
      notificationId: notification.id,
      userId: notification.userId,
    });

    return notification;
  }

  /**
   * Mark all notifications as read for a user
   */
  async markAllAsRead(userId: string) {
    const result = await db.notification.updateMany({
      where: { userId, read: false },
      data: { read: true },
    });

    logger.info("All notifications marked as read", {
      userId,
      count: result.count,
    });

    return { count: result.count };
  }

  /**
   * Delete a notification
   */
  async delete(id: string, userId: string) {
    // Check if notification exists and belongs to user
    const existing = await db.notification.findFirst({
      where: { id, userId },
    });

    if (!existing) {
      throw ApiError.notFound("Notification not found");
    }

    await db.notification.delete({
      where: { id },
    });

    logger.info("Notification deleted", {
      notificationId: id,
      userId,
    });
  }

  /**
   * Delete all notifications for a user
   */
  async deleteAll(userId: string) {
    const result = await db.notification.deleteMany({
      where: { userId },
    });

    logger.info("All notifications deleted", {
      userId,
      count: result.count,
    });

    return { count: result.count };
  }

  /**
   * Delete old read notifications (for cleanup jobs)
   * Deletes notifications older than specified days
   */
  async deleteOldReadNotifications(daysOld: number = 30) {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - daysOld);

    const result = await db.notification.deleteMany({
      where: {
        read: true,
        createdAt: { lt: cutoffDate },
      },
    });

    logger.info("Old read notifications cleaned up", {
      count: result.count,
      olderThanDays: daysOld,
    });

    return { count: result.count };
  }

  // ============================================================================
  // Helper Methods for Other Services
  // ============================================================================

  /**
   * Send a system notification to a user
   */
  async sendSystemNotification(
    userId: string,
    title: string,
    message: string,
    data?: Record<string, unknown>
  ) {
    return this.create({
      userId,
      type: NotificationType.SYSTEM,
      title,
      message,
      data,
    });
  }

  /**
   * Send a success notification to a user
   */
  async sendSuccessNotification(
    userId: string,
    title: string,
    message: string,
    data?: Record<string, unknown>
  ) {
    return this.create({
      userId,
      type: NotificationType.SUCCESS,
      title,
      message,
      data,
    });
  }

  /**
   * Send a warning notification to a user
   */
  async sendWarningNotification(
    userId: string,
    title: string,
    message: string,
    data?: Record<string, unknown>
  ) {
    return this.create({
      userId,
      type: NotificationType.WARNING,
      title,
      message,
      data,
    });
  }

  /**
   * Send an error notification to a user
   */
  async sendErrorNotification(
    userId: string,
    title: string,
    message: string,
    data?: Record<string, unknown>
  ) {
    return this.create({
      userId,
      type: NotificationType.ERROR,
      title,
      message,
      data,
    });
  }

  /**
   * Send a notification to all users (admin broadcast)
   */
  async broadcastToAllUsers(
    title: string,
    message: string,
    type: NotificationType = NotificationType.SYSTEM,
    data?: Record<string, unknown>
  ) {
    const users = await db.user.findMany({
      where: { isActive: true },
      select: { id: true },
    });

    return this.createMany(
      users.map((user) => ({
        userId: user.id,
        type,
        title,
        message,
        data,
      }))
    );
  }
}

// ============================================================================
// Singleton Export
// ============================================================================

export const notificationService = new NotificationService();
