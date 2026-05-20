import { db } from "../lib/db.js";
import { ApiError } from "../middleware/error.middleware.js";
import { ErrorCodes } from "../utils/response.js";
import { Readable } from "stream";

/**
 * Column definition for CSV export
 */
export interface CsvColumn<T> {
  header: string;
  accessor: keyof T | ((item: T) => string | number | boolean | null | undefined);
}

/**
 * Export format types
 */
export type ExportFormat = "json" | "csv";

/**
 * User export data structure (GDPR compliant)
 */
interface UserExportData {
  profile: {
    id: string;
    email: string;
    name: string | null;
    role: string;
    isActive: boolean;
    emailVerified: boolean;
    createdAt: string;
    updatedAt: string;
  };
  accountInfo: {
    authProvider: string;
    hasGoogleLinked: boolean;
  };
}

/**
 * Admin user export row
 */
interface AdminUserExportRow {
  id: string;
  email: string;
  name: string | null;
  role: string;
  isActive: boolean;
  emailVerified: boolean;
  createdAt: Date;
  updatedAt: Date;
}

/**
 * Audit log export row
 */
interface AuditLogExportRow {
  id: string;
  action: string;
  entity: string;
  entityId: string | null;
  userId: string | null;
  userEmail: string | null;
  ipAddress: string | null;
  userAgent: string | null;
  changes: string | null;
  metadata: string | null;
  createdAt: Date;
}

class ExportService {
  /**
   * Generate CSV string from data array
   * Uses simple CSV generation without external dependencies (MIT-safe)
   */
  exportToCsv<T>(data: T[], columns: CsvColumn<T>[]): string {
    if (!data.length) {
      // Return just headers for empty data
      return columns.map(col => this.escapeCsvValue(col.header)).join(",") + "\n";
    }

    // Build header row
    const headerRow = columns.map(col => this.escapeCsvValue(col.header)).join(",");

    // Build data rows
    const dataRows = data.map(item => {
      return columns
        .map(col => {
          const value = typeof col.accessor === "function"
            ? col.accessor(item)
            : item[col.accessor];
          return this.escapeCsvValue(this.formatCsvValue(value));
        })
        .join(",");
    });

    return [headerRow, ...dataRows].join("\n") + "\n";
  }

  /**
   * Generate CSV as a readable stream for large datasets
   * Useful for streaming large exports without loading everything in memory
   */
  exportToCsvStream<T>(
    dataStream: AsyncIterable<T>,
    columns: CsvColumn<T>[]
  ): Readable {
    const readable = new Readable({
      read() {},
    });

    // Write header immediately
    const headerRow = columns.map(col => this.escapeCsvValue(col.header)).join(",") + "\n";
    readable.push(headerRow);

    // Process data asynchronously
    (async () => {
      try {
        for await (const item of dataStream) {
          const row = columns
            .map(col => {
              const value = typeof col.accessor === "function"
                ? col.accessor(item)
                : item[col.accessor];
              return this.escapeCsvValue(this.formatCsvValue(value));
            })
            .join(",") + "\n";
          readable.push(row);
        }
        readable.push(null); // Signal end of stream
      } catch (error) {
        readable.destroy(error instanceof Error ? error : new Error(String(error)));
      }
    })();

    return readable;
  }

  /**
   * Export user's personal data (GDPR compliant data export)
   */
  async exportUserData(userId: string, format: ExportFormat = "json"): Promise<string> {
    const user = await db.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        isActive: true,
        emailVerified: true,
        authProvider: true,
        googleId: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    if (!user) {
      throw ApiError.notFound("User not found", ErrorCodes.USER_NOT_FOUND);
    }

    const exportData: UserExportData = {
      profile: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        isActive: user.isActive,
        emailVerified: user.emailVerified,
        createdAt: user.createdAt.toISOString(),
        updatedAt: user.updatedAt.toISOString(),
      },
      accountInfo: {
        authProvider: user.authProvider,
        hasGoogleLinked: !!user.googleId,
      },
    };

    if (format === "csv") {
      // Flatten the data for CSV
      const flatData = [{
        id: exportData.profile.id,
        email: exportData.profile.email,
        name: exportData.profile.name,
        role: exportData.profile.role,
        isActive: exportData.profile.isActive,
        emailVerified: exportData.profile.emailVerified,
        authProvider: exportData.accountInfo.authProvider,
        hasGoogleLinked: exportData.accountInfo.hasGoogleLinked,
        createdAt: exportData.profile.createdAt,
        updatedAt: exportData.profile.updatedAt,
      }];

      return this.exportToCsv(flatData, [
        { header: "ID", accessor: "id" },
        { header: "Email", accessor: "email" },
        { header: "Name", accessor: "name" },
        { header: "Role", accessor: "role" },
        { header: "Active", accessor: "isActive" },
        { header: "Email Verified", accessor: "emailVerified" },
        { header: "Auth Provider", accessor: "authProvider" },
        { header: "Google Linked", accessor: "hasGoogleLinked" },
        { header: "Created At", accessor: "createdAt" },
        { header: "Updated At", accessor: "updatedAt" },
      ]);
    }

    return JSON.stringify(exportData, null, 2);
  }

  /**
   * Export all users (admin only)
   * Returns CSV string for direct download
   */
  async exportAllUsers(): Promise<string> {
    const users = await db.user.findMany({
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        isActive: true,
        emailVerified: true,
        createdAt: true,
        updatedAt: true,
      },
      orderBy: { createdAt: "desc" },
    });

    const columns: CsvColumn<AdminUserExportRow>[] = [
      { header: "ID", accessor: "id" },
      { header: "Email", accessor: "email" },
      { header: "Name", accessor: "name" },
      { header: "Role", accessor: "role" },
      { header: "Active", accessor: "isActive" },
      { header: "Email Verified", accessor: "emailVerified" },
      { header: "Created At", accessor: (item) => item.createdAt.toISOString() },
      { header: "Updated At", accessor: (item) => item.updatedAt.toISOString() },
    ];

    return this.exportToCsv(users, columns);
  }

  /**
   * Stream export all users for large datasets
   * Uses cursor-based pagination for memory efficiency
   */
  async *streamAllUsers(batchSize = 1000): AsyncGenerator<AdminUserExportRow> {
    let cursor: string | undefined;
    let hasMore = true;

    while (hasMore) {
      const users = await db.user.findMany({
        take: batchSize,
        skip: cursor ? 1 : 0,
        cursor: cursor ? { id: cursor } : undefined,
        select: {
          id: true,
          email: true,
          name: true,
          role: true,
          isActive: true,
          emailVerified: true,
          createdAt: true,
          updatedAt: true,
        },
        orderBy: { id: "asc" },
      });

      for (const user of users) {
        yield user;
      }

      if (users.length < batchSize) {
        hasMore = false;
      } else {
        cursor = users[users.length - 1].id;
      }
    }
  }

  /**
   * Export audit logs (admin only)
   */
  async exportAuditLogs(options?: {
    startDate?: Date;
    endDate?: Date;
    action?: string;
    userId?: string;
  }): Promise<string> {
    // Build where clause
    const where: Record<string, unknown> = {};

    if (options?.startDate || options?.endDate) {
      where.createdAt = {};
      if (options.startDate) {
        (where.createdAt as Record<string, unknown>).gte = options.startDate;
      }
      if (options.endDate) {
        (where.createdAt as Record<string, unknown>).lte = options.endDate;
      }
    }

    if (options?.action) {
      where.action = options.action;
    }

    if (options?.userId) {
      where.userId = options.userId;
    }

    const auditLogs = await db.auditLog.findMany({
      where,
      include: {
        user: {
          select: {
            email: true,
          },
        },
      },
      orderBy: { createdAt: "desc" },
      take: 10000, // Limit to prevent memory issues
    });

    const columns: CsvColumn<AuditLogExportRow>[] = [
      { header: "ID", accessor: "id" },
      { header: "Action", accessor: "action" },
      { header: "Entity", accessor: "entity" },
      { header: "Entity ID", accessor: "entityId" },
      { header: "User ID", accessor: "userId" },
      { header: "User Email", accessor: "userEmail" },
      { header: "IP Address", accessor: "ipAddress" },
      { header: "User Agent", accessor: "userAgent" },
      { header: "Changes", accessor: "changes" },
      { header: "Metadata", accessor: "metadata" },
      { header: "Created At", accessor: (item) => item.createdAt.toISOString() },
    ];

    // Transform to include user email
    const transformedLogs: AuditLogExportRow[] = auditLogs.map((log) => ({
      id: log.id,
      action: log.action,
      entity: log.entity,
      entityId: log.entityId,
      userId: log.userId,
      userEmail: log.user?.email || null,
      ipAddress: log.ipAddress,
      userAgent: log.userAgent,
      changes: log.changes ? JSON.stringify(log.changes) : null,
      metadata: log.metadata ? JSON.stringify(log.metadata) : null,
      createdAt: log.createdAt,
    }));

    return this.exportToCsv(transformedLogs, columns);
  }

  /**
   * Escape a value for CSV format
   * Handles quotes, commas, and newlines
   */
  private escapeCsvValue(value: string): string {
    if (value.includes(",") || value.includes('"') || value.includes("\n") || value.includes("\r")) {
      // Escape double quotes by doubling them
      const escaped = value.replace(/"/g, '""');
      return `"${escaped}"`;
    }
    return value;
  }

  /**
   * Format a value for CSV output
   */
  private formatCsvValue(value: unknown): string {
    if (value === null || value === undefined) {
      return "";
    }
    if (typeof value === "boolean") {
      return value ? "true" : "false";
    }
    if (typeof value === "number") {
      return value.toString();
    }
    if (value instanceof Date) {
      return value.toISOString();
    }
    if (typeof value === "object") {
      return JSON.stringify(value);
    }
    return String(value);
  }

  /**
   * Get user export columns for streaming
   */
  getUserExportColumns(): CsvColumn<AdminUserExportRow>[] {
    return [
      { header: "ID", accessor: "id" },
      { header: "Email", accessor: "email" },
      { header: "Name", accessor: "name" },
      { header: "Role", accessor: "role" },
      { header: "Active", accessor: "isActive" },
      { header: "Email Verified", accessor: "emailVerified" },
      { header: "Created At", accessor: (item) => item.createdAt.toISOString() },
      { header: "Updated At", accessor: (item) => item.updatedAt.toISOString() },
    ];
  }
}

export const exportService = new ExportService();
