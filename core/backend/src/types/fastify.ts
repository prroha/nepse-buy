/**
 * Fastify Type Definitions
 *
 * Module augmentation for Fastify to add custom request properties
 * that were previously on Express Request.
 */

import { FastifyRequest, FastifyReply } from "fastify";
import type { AuthUser } from "./index.js";
import { JwtPayload } from "../utils/jwt.js";

// Module augmentation for Fastify
declare module "fastify" {
  interface FastifyRequest {
    /** JWT payload (set by auth middleware after token verification) */
    user?: JwtPayload;
    /** Database user (auth middleware select projection — never includes passwordHash) */
    dbUser?: AuthUser;
    /** Device ID from X-Device-Id header */
    deviceId?: string;
    /** CSRF token for this request */
    csrfToken?: string;
    /** Preview configuration */
    previewConfig?: import("../middleware/preview.middleware.js").PreviewConfig;
  }
}

/**
 * Base application request type (alias for FastifyRequest)
 */
export type AppRequest = FastifyRequest;

/**
 * Authenticated request with guaranteed user info.
 * Use this type after authMiddleware has run.
 */
export interface AuthenticatedRequest extends FastifyRequest {
  user: JwtPayload;
  dbUser: AuthUser;
}

/**
 * Application reply type (alias for FastifyReply)
 */
export type AppReply = FastifyReply;
