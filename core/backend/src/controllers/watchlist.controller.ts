import { FastifyRequest, FastifyReply } from "fastify";
import { z } from "zod";
import { watchlistService } from "../services/watchlist.service.js";
import { successResponse, errorResponse, ErrorCodes } from "../utils/response.js";
import { AuthenticatedRequest } from "../types/index.js";

const addBodySchema = z.object({
  symbol: z
    .string()
    .min(1)
    .max(20)
    .regex(/^[A-Za-z0-9]+$/, "symbol must be alphanumeric")
    .transform((s) => s.toUpperCase()),
});

const idParamSchema = z.object({
  id: z.string().uuid("invalid item id"),
});

class WatchlistController {
  private getUserId(req: FastifyRequest, reply: FastifyReply): string | null {
    const authReq = req as AuthenticatedRequest;
    if (!authReq.user?.userId) {
      reply.code(401).send(errorResponse(ErrorCodes.AUTH_REQUIRED, "Authentication required"));
      return null;
    }
    return authReq.user.userId;
  }

  async list(req: FastifyRequest, reply: FastifyReply): Promise<void> {
    const userId = this.getUserId(req, reply);
    if (!userId) return;
    const items = await watchlistService.listForUser(userId);
    reply.send(successResponse(items));
  }

  async add(req: FastifyRequest, reply: FastifyReply): Promise<void> {
    const userId = this.getUserId(req, reply);
    if (!userId) return;
    const parsed = addBodySchema.safeParse(req.body);
    if (!parsed.success) {
      reply.code(400).send(errorResponse(ErrorCodes.VALIDATION_ERROR, "Invalid body", parsed.error.issues));
      return;
    }
    const result = await watchlistService.addBySymbol(userId, parsed.data.symbol);
    reply.code(201).send(successResponse(result, "Added to watchlist"));
  }

  async remove(req: FastifyRequest, reply: FastifyReply): Promise<void> {
    const userId = this.getUserId(req, reply);
    if (!userId) return;
    const parsed = idParamSchema.safeParse(req.params);
    if (!parsed.success) {
      reply.code(400).send(errorResponse(ErrorCodes.VALIDATION_ERROR, "Invalid item id", parsed.error.issues));
      return;
    }
    await watchlistService.remove(userId, parsed.data.id);
    reply.code(204).send();
  }
}

export const watchlistController = new WatchlistController();
