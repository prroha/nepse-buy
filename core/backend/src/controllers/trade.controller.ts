import { FastifyRequest, FastifyReply } from "fastify";
import { z } from "zod";
import { tradeService } from "../services/trade.service.js";
import { successResponse, errorResponse, ErrorCodes } from "../utils/response.js";
import { AuthenticatedRequest } from "../types/index.js";

const decimalString = z.string().regex(/^\d+(\.\d{1,4})?$/, "must be a decimal value");

const logTradeBodySchema = z
  .object({
    stockId: z.string().uuid().optional(),
    symbol: z.string().min(1).max(20).regex(/^[A-Za-z0-9]+$/).optional(),
    side: z.enum(["BUY", "SELL"]),
    shares: z.coerce.number().int().min(1),
    grossPricePerShare: decimalString,
    executedAt: z.string().datetime().optional(),
    note: z.string().max(500).optional(),
  })
  .refine((d) => d.stockId || d.symbol, { message: "stockId or symbol required" });

const idParam = z.object({ id: z.string().uuid("invalid id") });
const positionIdQuery = z.object({ positionId: z.string().uuid("positionId is required") });

class TradeController {
  private getUserId(req: FastifyRequest, reply: FastifyReply): string | null {
    const auth = req as AuthenticatedRequest;
    if (!auth.user?.userId) {
      reply.code(401).send(errorResponse(ErrorCodes.AUTH_REQUIRED, "Authentication required"));
      return null;
    }
    return auth.user.userId;
  }

  async logTrade(req: FastifyRequest, reply: FastifyReply): Promise<void> {
    const userId = this.getUserId(req, reply);
    if (!userId) return;
    const parsed = logTradeBodySchema.safeParse(req.body);
    if (!parsed.success) {
      reply.code(400).send(errorResponse(ErrorCodes.VALIDATION_ERROR, "Invalid body", parsed.error.issues));
      return;
    }
    const result = await tradeService.logTrade(userId, {
      stockId: parsed.data.stockId,
      symbol: parsed.data.symbol,
      side: parsed.data.side,
      shares: parsed.data.shares,
      grossPricePerShare: parsed.data.grossPricePerShare,
      executedAt: parsed.data.executedAt ? new Date(parsed.data.executedAt) : new Date(),
      note: parsed.data.note,
    });
    reply.code(201).send(successResponse(result, "Trade logged"));
  }

  async list(req: FastifyRequest, reply: FastifyReply): Promise<void> {
    const userId = this.getUserId(req, reply);
    if (!userId) return;
    const parsed = positionIdQuery.safeParse(req.query);
    if (!parsed.success) {
      reply.code(400).send(errorResponse(ErrorCodes.VALIDATION_ERROR, "Invalid query", parsed.error.issues));
      return;
    }
    const rows = await tradeService.list(userId, parsed.data.positionId);
    reply.send(successResponse(rows));
  }

  async remove(req: FastifyRequest, reply: FastifyReply): Promise<void> {
    const userId = this.getUserId(req, reply);
    if (!userId) return;
    const idCheck = idParam.safeParse(req.params);
    if (!idCheck.success) {
      reply.code(400).send(errorResponse(ErrorCodes.VALIDATION_ERROR, "Invalid id", idCheck.error.issues));
      return;
    }
    await tradeService.remove(userId, idCheck.data.id);
    reply.code(204).send();
  }
}

export const tradeController = new TradeController();
