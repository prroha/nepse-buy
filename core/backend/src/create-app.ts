import Fastify, { FastifyInstance } from "fastify";
import fastifyCors from "@fastify/cors";
import fastifyHelmet from "@fastify/helmet";
import fastifyCookie from "@fastify/cookie";
import fastifyFormbody from "@fastify/formbody";
import fastifyCompress from "@fastify/compress";
import fastifyMultipart from "@fastify/multipart";
import fastifyStatic from "@fastify/static";
import fastifySwagger from "@fastify/swagger";
import fastifySwaggerUi from "@fastify/swagger-ui";
import path from "path";

import { config } from "./config/index.js";
import { requestIdHook } from "./middleware/request-id.middleware.js";
import { sanitizeInput } from "./middleware/sanitize.middleware.js";
import { csrfProtection } from "./middleware/csrf.middleware.js";
import { registerRateLimiter } from "./middleware/rate-limit.middleware.js";
import { previewMiddleware } from "./middleware/preview.middleware.js";
import { errorHandler } from "./middleware/error.middleware.js";
import { requestContext } from "./lib/logger.js";
import { db } from "./lib/db.js";
import routes from "./routes/index.js";
import { swaggerOptions } from "./swagger.js";

/**
 * Create and configure the Fastify application.
 * Does NOT start listening — use app.listen() separately.
 */
export async function createApp(): Promise<FastifyInstance> {
  const app = Fastify({
    logger: config.isTest()
      ? false
      : {
          level: config.isProduction() ? "warn" : "info",
          transport: config.isDevelopment()
            ? { target: "pino-pretty", options: { colorize: true, translateTime: "HH:MM:ss Z", ignore: "pid,hostname" } }
            : undefined,
        },
    trustProxy: config.trustProxy,
    requestIdHeader: "x-request-id",
    genReqId: () => crypto.randomUUID(),
    bodyLimit: 1_048_576, // 1MB default; override per-route for uploads
  });

  // Security headers
  await app.register(fastifyHelmet, {
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        scriptSrc: ["'self'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        imgSrc: ["'self'", "data:", "https:"],
        connectSrc: ["'self'"],
        fontSrc: ["'self'"],
        objectSrc: ["'none'"],
        mediaSrc: ["'self'"],
        frameSrc: ["'none'"],
      },
    },
    crossOriginEmbedderPolicy: false,
  });

  // CORS
  await app.register(fastifyCors, {
    origin: config.corsOrigin,
    credentials: true,
    methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allowedHeaders: [
      "Content-Type",
      "Authorization",
      "X-Device-Id",
      "X-CSRF-Token",
      "X-XSRF-Token",
      "X-API-Key",
      "X-Preview-Session",
      "x-request-id",
    ],
    exposedHeaders: [
      "X-RateLimit-Limit",
      "X-RateLimit-Remaining",
      "X-RateLimit-Reset",
      "x-request-id",
    ],
  });

  // Cookie parsing
  await app.register(fastifyCookie);

  // Body parsing (URL-encoded)
  await app.register(fastifyFormbody);

  // Response compression (gzip/brotli)
  await app.register(fastifyCompress, {
    global: true,
    threshold: 1024, // Only compress responses > 1KB
  });

  // Multipart file uploads (available globally, routes opt-in via req.file())
  await app.register(fastifyMultipart, {
    limits: {
      fileSize: 10 * 1024 * 1024, // 10MB max file size
      files: 5,
    },
  });

  // Request ID hook (sets req.id and response header)
  app.addHook("onRequest", requestIdHook);

  // Wrap all requests in AsyncLocalStorage for request-scoped logging
  // Using .run() instead of .enterWith() to create a proper scope and prevent context leakage
  app.addHook("onRequest", (req, _reply, done) => {
    requestContext.run({ requestId: req.id }, done);
  });

  // Input sanitization (XSS prevention) - after body parsing
  app.addHook("preHandler", sanitizeInput);

  // Preview/Feature flag middleware
  app.addHook("preHandler", previewMiddleware);

  // General rate limiting
  await registerRateLimiter(app);

  // Health check (before CSRF to allow monitoring)
  app.get("/health", async (_req, reply) => {
    try {
      await db.$queryRaw`SELECT 1`;
      return reply.send({ status: "ok", timestamp: new Date().toISOString() });
    } catch {
      return reply.code(503).send({ status: "error", timestamp: new Date().toISOString() });
    }
  });

  // Swagger API documentation
  await app.register(fastifySwagger, swaggerOptions);
  await app.register(fastifySwaggerUi, {
    routePrefix: "/api-docs",
    uiConfig: {
      docExpansion: "list",
      deepLinking: true,
    },
    staticCSP: true,
  });

  // CSRF protection for state-changing requests
  app.addHook("onRequest", csrfProtection);

  // Serve uploaded files (static) — intentionally public (avatars, public assets).
  // TODO: Add auth middleware for non-public uploads if private file storage is needed.
  await app.register(fastifyStatic, {
    root: path.join(process.cwd(), "uploads"),
    prefix: "/uploads/",
    decorateReply: false,
    maxAge: "1d",
  });

  // Error handler (catches all thrown errors) — must be set before routes
  app.setErrorHandler(errorHandler);

  // 404 handler
  app.setNotFoundHandler((_req, reply) => {
    return reply.code(404).send({
      success: false,
      error: {
        code: "NOT_FOUND",
        message: "Endpoint not found",
      },
    });
  });

  // API routes
  await app.register(routes, { prefix: "/api" });

  return app;
}
