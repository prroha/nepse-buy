import { FastifyRequest, FastifyReply } from "fastify";

/**
 * Request ID Header name
 * Used for correlating requests across services
 */
export const REQUEST_ID_HEADER = "x-request-id";

/**
 * Request ID Hook
 *
 * Sets the x-request-id response header for client-side tracking.
 * Fastify already generates req.id via requestIdHeader config.
 */
export async function requestIdHook(
  req: FastifyRequest,
  reply: FastifyReply
): Promise<void> {
  reply.header(REQUEST_ID_HEADER, req.id);
}
