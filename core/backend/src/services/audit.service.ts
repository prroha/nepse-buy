import { FastifyRequest } from "fastify";
import { AuditAction, Prisma } from "@prisma/client";
import { db } from "../lib/db.js";
import { logger } from "../lib/logger.js";

/**
 * Sensitive fields that should never be logged
 */
const SENSITIVE_FIELDS = new Set([
  "password",
  "passwordHash",
  "password_hash",
  "token",
  "refreshToken",
  "accessToken",
  "secret",
  "apiKey",
  "creditCard",
  "ssn",
  "pin",
]);

/**
 * Audit log input
 */
interface AuditLogInput {
  action: AuditAction;
  entity: string;
  entityId?: string;
  changes?: Record<string, unknown>;
  userId?: string;
  req?: FastifyRequest;
  metadata?: Record<string, unknown>;
}

/**
 * Audit log filters for querying
 */
interface AuditLogFilters {
  page?: number;
  limit?: number;
  userId?: string;
  action?: AuditAction;
  entity?: string;
  entityId?: string;
  startDate?: Date;
  endDate?: Date;
  search?: string;
}

/**
 * Audit log with user info
 */
interface AuditLogWithUser {
  id: string;
  userId: string | null;
  action: AuditAction;
  entity: string;
  entityId: string | null;
  changes: Prisma.JsonValue;
  ipAddress: string | null;
  userAgent: string | null;
  metadata: Prisma.JsonValue;
  createdAt: Date;
  user: {
    id: string;
    email: string;
    name: string | null;
  } | null;
}

class AuditService {
  /**
   * Extract IP address from request
   * Handles proxied requests (X-Forwarded-For header)
   */
  private getIpAddress(req?: FastifyRequest): string | undefined {
    if (!req) return undefined;

    // Check for proxied requests
    const forwardedFor = req.headers["x-forwarded-for"];
    if (forwardedFor) {
      // X-Forwarded-For can contain multiple IPs, take the first one
      const ips = Array.isArray(forwardedFor)
        ? forwardedFor[0]
        : forwardedFor.split(",")[0];
      return ips.trim();
    }

    // Check for real IP header (some proxies use this)
    const realIp = req.headers["x-real-ip"];
    if (realIp) {
      return Array.isArray(realIp) ? realIp[0] : realIp;
    }

    // Fall back to socket remote address
    return req.socket?.remoteAddress || req.ip;
  }

  /**
   * Extract user agent from request
   */
  private getUserAgent(req?: FastifyRequest): string | undefined {
    if (!req) return undefined;
    const userAgent = req.headers["user-agent"];
    // Truncate long user agents
    return userAgent ? userAgent.substring(0, 500) : undefined;
  }

  /**
   * Sanitize changes object by removing sensitive fields
   */
  private sanitizeChanges(
    changes?: Record<string, unknown>
  ): Record<string, unknown> | undefined {
    if (!changes) return undefined;

    const sanitized: Record<string, unknown> = {};

    for (const [key, value] of Object.entries(changes)) {
      // Check if key contains sensitive field names
      const lowerKey = key.toLowerCase();
      if (SENSITIVE_FIELDS.has(lowerKey) ||
          Array.from(SENSITIVE_FIELDS).some(field => lowerKey.includes(field))) {
        sanitized[key] = "[REDACTED]";
      } else if (typeof value === "object" && value !== null) {
        // Recursively sanitize nested objects
        sanitized[key] = this.sanitizeChanges(value as Record<string, unknown>);
      } else {
        sanitized[key] = value;
      }
    }

    return sanitized;
  }

  /**
   * Log an audit event
   * Non-blocking - errors are logged but don't throw
   */
  async log(input: AuditLogInput): Promise<void> {
    try {
      const { action, entity, entityId, changes, userId, req, metadata } = input;

      const sanitizedChanges = this.sanitizeChanges(changes);
      const sanitizedMetadata = this.sanitizeChanges(metadata);

      await db.auditLog.create({
        data: {
          userId,
          action,
          entity,
          entityId,
          changes: sanitizedChanges as Prisma.InputJsonValue,
          ipAddress: this.getIpAddress(req),
          userAgent: this.getUserAgent(req),
          metadata: sanitizedMetadata as Prisma.InputJsonValue,
        },
      });

      // Also log to application logger for immediate visibility
      logger.audit(`${action} on ${entity}`, {
        userId,
        entityId,
        ipAddress: this.getIpAddress(req),
      });
    } catch (error) {
      // Log error but don't throw - audit logging should never break the main flow
      logger.error("Failed to create audit log", {
        error: error instanceof Error ? error.message : "Unknown error",
        action: input.action,
        entity: input.entity,
      });
    }
  }

  /**
   * Get paginated audit logs with filters
   */
  async getLogs(filters: AuditLogFilters = {}): Promise<{
    logs: AuditLogWithUser[];
    total: number;
    page: number;
    limit: number;
  }> {
    const {
      page = 1,
      limit = 20,
      userId,
      action,
      entity,
      entityId,
      startDate,
      endDate,
      search,
    } = filters;

    // Build where clause
    const where: Prisma.AuditLogWhereInput = {};

    if (userId) {
      where.userId = userId;
    }

    if (action) {
      where.action = action;
    }

    if (entity) {
      where.entity = entity;
    }

    if (entityId) {
      where.entityId = entityId;
    }

    if (startDate || endDate) {
      where.createdAt = {};
      if (startDate) {
        where.createdAt.gte = startDate;
      }
      if (endDate) {
        where.createdAt.lte = endDate;
      }
    }

    // Search in entity and user email
    if (search) {
      where.OR = [
        { entity: { contains: search, mode: "insensitive" } },
        { entityId: { contains: search, mode: "insensitive" } },
        { user: { email: { contains: search, mode: "insensitive" } } },
        { user: { name: { contains: search, mode: "insensitive" } } },
      ];
    }

    // Get total count and logs in parallel
    const [total, logs] = await Promise.all([
      db.auditLog.count({ where }),
      db.auditLog.findMany({
        where,
        select: {
          id: true,
          userId: true,
          action: true,
          entity: true,
          entityId: true,
          changes: true,
          ipAddress: true,
          userAgent: true,
          metadata: true,
          createdAt: true,
          user: {
            select: {
              id: true,
              email: true,
              name: true,
            },
          },
        },
        orderBy: { createdAt: "desc" },
        skip: (page - 1) * limit,
        take: limit,
      }),
    ]);

    return {
      logs,
      total,
      page,
      limit,
    };
  }

  /**
   * Get a single audit log by ID
   */
  async getLogById(id: string): Promise<AuditLogWithUser | null> {
    return db.auditLog.findUnique({
      where: { id },
      select: {
        id: true,
        userId: true,
        action: true,
        entity: true,
        entityId: true,
        changes: true,
        ipAddress: true,
        userAgent: true,
        metadata: true,
        createdAt: true,
        user: {
          select: {
            id: true,
            email: true,
            name: true,
          },
        },
      },
    });
  }

  /**
   * Get distinct entity types for filtering
   */
  async getEntityTypes(): Promise<string[]> {
    const results = await db.auditLog.findMany({
      select: { entity: true },
      distinct: ["entity"],
      orderBy: { entity: "asc" },
    });
    return results.map((r) => r.entity);
  }

  /**
   * Delete old audit logs (for cleanup/GDPR compliance)
   * Should be run as a scheduled job
   */
  async deleteOldLogs(olderThanDays: number): Promise<number> {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - olderThanDays);

    const result = await db.auditLog.deleteMany({
      where: {
        createdAt: {
          lt: cutoffDate,
        },
      },
    });

    logger.info("Deleted old audit logs", {
      count: result.count,
      olderThanDays,
    });

    return result.count;
  }
}

export const auditService = new AuditService();

// Export types for use in other services
export { AuditLogInput, AuditLogFilters, AuditLogWithUser };
