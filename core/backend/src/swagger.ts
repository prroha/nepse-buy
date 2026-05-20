import { FastifyDynamicSwaggerOptions } from "@fastify/swagger";
import { config } from "./config/index.js";

const sharedSchemas = {
  UserRole: {
    type: "string" as const,
    enum: ["USER", "ADMIN", "SUPER_ADMIN"],
    description: "User role in the system",
  },
  NotificationType: {
    type: "string" as const,
    enum: ["INFO", "SUCCESS", "WARNING", "ERROR", "SYSTEM", "SIGNAL"],
    description: "Notification type",
  },
  AuditAction: {
    type: "string" as const,
    enum: [
      "CREATE", "READ", "UPDATE", "DELETE", "LOGIN", "LOGOUT",
      "LOGIN_FAILED", "PASSWORD_CHANGE", "PASSWORD_RESET", "EMAIL_VERIFY", "ADMIN_ACTION",
    ],
    description: "Audit log action type",
  },
  SignalAction: {
    type: "string" as const,
    enum: ["BUY", "WAIT", "SKIP"],
    description: "Signal engine output action",
  },
  Season: {
    type: "string" as const,
    enum: ["WEAK", "NORMAL", "STRONG"],
    description: "Seasonal classification for a NEPSE month",
  },
  DataSource: {
    type: "string" as const,
    enum: ["NEPALSTOCK", "NEPSE_ALPHA", "MEROLAGANI", "SHARESANSAR", "MANUAL"],
    description: "Origin of an observation row",
  },
};

export const swaggerOptions: FastifyDynamicSwaggerOptions = {
  openapi: {
    openapi: "3.0.0",
    info: {
      title: "nepse-buy API",
      description: "NEPSE DCA signal app — auth, watchlists, signals, notifications",
      version: "0.1.0",
      contact: { name: "API Support" },
    },
    servers: [
      { url: `http://localhost:${config.port}/api/v1`, description: "Development server" },
      { url: "/api/v1", description: "Production server (relative)" },
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: "http",
          scheme: "bearer",
          bearerFormat: "JWT",
          description: "JWT access token",
        },
      },
      schemas: sharedSchemas,
    },
    security: [{ bearerAuth: [] }],
  },
};

export const schemas = sharedSchemas;
