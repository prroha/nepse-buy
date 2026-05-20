import { FastifyRequest, FastifyReply } from "fastify";
import { z } from "zod";
import { feeScheduleService } from "../services/fee-schedule.service.js";
import { successResponse, errorResponse, ErrorCodes } from "../utils/response.js";
import { AuthenticatedRequest } from "../types/index.js";

const brokerageSlabSchema = z.object({
  upTo: z.number().nullable(),
  ratePct: z.number().min(0).max(100),
});

const patchSchema = z.object({
  brokerageSlabs: z.array(brokerageSlabSchema).min(1).optional(),
  sebonRatePct: z.number().min(0).max(100).optional(),
  dpFlatFee: z.number().min(0).max(100000).optional(),
  cgtShortTermPct: z.number().min(0).max(100).optional(),
  cgtLongTermPct: z.number().min(0).max(100).optional(),
  longTermDaysThreshold: z.number().int().min(1).max(3650).optional(),
});

class FeeScheduleController {
  private getUserId(req: FastifyRequest, reply: FastifyReply): string | null {
    const auth = req as AuthenticatedRequest;
    if (!auth.user?.userId) {
      reply.code(401).send(errorResponse(ErrorCodes.AUTH_REQUIRED, "Authentication required"));
      return null;
    }
    return auth.user.userId;
  }

  async get(req: FastifyRequest, reply: FastifyReply): Promise<void> {
    const userId = this.getUserId(req, reply);
    if (!userId) return;
    const row = await feeScheduleService.get(userId);
    reply.send(successResponse(row));
  }

  async update(req: FastifyRequest, reply: FastifyReply): Promise<void> {
    const userId = this.getUserId(req, reply);
    if (!userId) return;
    const parsed = patchSchema.safeParse(req.body);
    if (!parsed.success) {
      reply.code(400).send(errorResponse(ErrorCodes.VALIDATION_ERROR, "Invalid body", parsed.error.issues));
      return;
    }
    const row = await feeScheduleService.update(userId, parsed.data);
    reply.send(successResponse(row, "Fee schedule updated"));
  }
}

export const feeScheduleController = new FeeScheduleController();
