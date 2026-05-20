import { FastifyRequest, FastifyReply } from "fastify";
import { z } from "zod";
import { positionService } from "../services/position.service.js";
import { tradeService } from "../services/trade.service.js";
import { successResponse, errorResponse, ErrorCodes } from "../utils/response.js";
import { AuthenticatedRequest } from "../types/index.js";

const decimalString = z.string().regex(/^\d+(\.\d{1,4})?$/, "must be a decimal value");

const addPurchaseBodySchema = z
  .object({
    stockId: z.string().uuid().optional(),
    symbol: z.string().min(1).max(20).regex(/^[A-Za-z0-9]+$/).optional(),
    shares: z.coerce.number().int().min(1),
    pricePerShare: decimalString,
    purchasedAt: z.string().datetime().optional(),
    note: z.string().max(500).optional(),
  })
  .refine((d) => d.stockId || d.symbol, { message: "stockId or symbol required" });

const idParam = z.object({ id: z.string().uuid("invalid id") });

class PositionController {
  private getUserId(req: FastifyRequest, reply: FastifyReply): string | null {
    const auth = req as AuthenticatedRequest;
    if (!auth.user?.userId) {
      reply.code(401).send(errorResponse(ErrorCodes.AUTH_REQUIRED, "Authentication required"));
      return null;
    }
    return auth.user.userId;
  }

  async list(req: FastifyRequest, reply: FastifyReply): Promise<void> {
    const userId = this.getUserId(req, reply);
    if (!userId) return;
    const rows = await positionService.list(userId);
    reply.send(successResponse(rows));
  }

  async addPurchase(req: FastifyRequest, reply: FastifyReply): Promise<void> {
    const userId = this.getUserId(req, reply);
    if (!userId) return;
    const parsed = addPurchaseBodySchema.safeParse(req.body);
    if (!parsed.success) {
      reply.code(400).send(errorResponse(ErrorCodes.VALIDATION_ERROR, "Invalid body", parsed.error.issues));
      return;
    }
    // v0.7 — purchase endpoint is now a thin wrapper that records a BUY trade.
    // Fees are auto-computed from the user's FeeSchedule; the mobile log-buy
    // outbox op continues to hit this URL without change.
    const result = await tradeService.logTrade(userId, {
      stockId: parsed.data.stockId,
      symbol: parsed.data.symbol,
      side: "BUY",
      shares: parsed.data.shares,
      grossPricePerShare: parsed.data.pricePerShare,
      executedAt: parsed.data.purchasedAt ? new Date(parsed.data.purchasedAt) : new Date(),
      note: parsed.data.note,
    });
    reply.code(201).send(successResponse(result, "Purchase logged"));
  }

  async remove(req: FastifyRequest, reply: FastifyReply): Promise<void> {
    const userId = this.getUserId(req, reply);
    if (!userId) return;
    const idCheck = idParam.safeParse(req.params);
    if (!idCheck.success) {
      reply.code(400).send(errorResponse(ErrorCodes.VALIDATION_ERROR, "Invalid id", idCheck.error.issues));
      return;
    }
    await positionService.remove(userId, idCheck.data.id);
    reply.code(204).send();
  }
}

export const positionController = new PositionController();
