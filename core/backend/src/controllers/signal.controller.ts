import { FastifyRequest, FastifyReply } from "fastify";
import { z } from "zod";
import { signalService } from "../services/signal.service.js";
import { successResponse, errorResponse, ErrorCodes } from "../utils/response.js";
import { AuthenticatedRequest } from "../types/index.js";

const todayQuerySchema = z.object({
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, "date must be YYYY-MM-DD").optional(),
});

const historyQuerySchema = z.object({
  stockId: z.string().uuid("stockId must be a UUID"),
  limit: z.coerce.number().int().min(1).max(365).default(60),
});

class SignalController {
  private getUserId(req: FastifyRequest, reply: FastifyReply): string | null {
    const authReq = req as AuthenticatedRequest;
    if (!authReq.user?.userId) {
      reply.code(401).send(errorResponse(ErrorCodes.AUTH_REQUIRED, "Authentication required"));
      return null;
    }
    return authReq.user.userId;
  }

  async today(req: FastifyRequest, reply: FastifyReply): Promise<void> {
    const userId = this.getUserId(req, reply);
    if (!userId) return;
    const parsed = todayQuerySchema.safeParse(req.query);
    if (!parsed.success) {
      reply.code(400).send(errorResponse(ErrorCodes.VALIDATION_ERROR, "Invalid query", parsed.error.issues));
      return;
    }
    const signalDate = parsed.data.date ? new Date(`${parsed.data.date}T00:00:00Z`) : new Date();
    const rows = await signalService.getToday(userId, signalDate);
    reply.send(successResponse(rows));
  }

  async history(req: FastifyRequest, reply: FastifyReply): Promise<void> {
    const userId = this.getUserId(req, reply);
    if (!userId) return;
    const parsed = historyQuerySchema.safeParse(req.query);
    if (!parsed.success) {
      reply.code(400).send(errorResponse(ErrorCodes.VALIDATION_ERROR, "Invalid query", parsed.error.issues));
      return;
    }
    const rows = await signalService.getHistory(userId, parsed.data.stockId, parsed.data.limit);
    reply.send(successResponse(rows));
  }
}

export const signalController = new SignalController();
