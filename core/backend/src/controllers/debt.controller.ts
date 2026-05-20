import { FastifyRequest, FastifyReply } from "fastify";
import { z } from "zod";
import { debtService } from "../services/debt.service.js";
import { successResponse, errorResponse, ErrorCodes } from "../utils/response.js";
import { AuthenticatedRequest } from "../types/index.js";

const decimalString = z.string().regex(/^\d+(\.\d{1,4})?$/, "must be a decimal value");

const createBodySchema = z.object({
  name: z.string().trim().min(1).max(100),
  balance: decimalString,
  interestRate: decimalString,
});

const updateBodySchema = z.object({
  name: z.string().trim().min(1).max(100).optional(),
  balance: decimalString.optional(),
  interestRate: decimalString.optional(),
  isActive: z.boolean().optional(),
});

const idParam = z.object({ id: z.string().uuid("invalid id") });

class DebtController {
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
    const rows = await debtService.list(userId);
    reply.send(successResponse(rows));
  }

  async create(req: FastifyRequest, reply: FastifyReply): Promise<void> {
    const userId = this.getUserId(req, reply);
    if (!userId) return;
    const parsed = createBodySchema.safeParse(req.body);
    if (!parsed.success) {
      reply.code(400).send(errorResponse(ErrorCodes.VALIDATION_ERROR, "Invalid body", parsed.error.issues));
      return;
    }
    const row = await debtService.create(userId, parsed.data);
    reply.code(201).send(successResponse(row));
  }

  async update(req: FastifyRequest, reply: FastifyReply): Promise<void> {
    const userId = this.getUserId(req, reply);
    if (!userId) return;
    const idCheck = idParam.safeParse(req.params);
    if (!idCheck.success) {
      reply.code(400).send(errorResponse(ErrorCodes.VALIDATION_ERROR, "Invalid id", idCheck.error.issues));
      return;
    }
    const parsed = updateBodySchema.safeParse(req.body);
    if (!parsed.success) {
      reply.code(400).send(errorResponse(ErrorCodes.VALIDATION_ERROR, "Invalid body", parsed.error.issues));
      return;
    }
    const row = await debtService.update(userId, idCheck.data.id, parsed.data);
    reply.send(successResponse(row));
  }

  async remove(req: FastifyRequest, reply: FastifyReply): Promise<void> {
    const userId = this.getUserId(req, reply);
    if (!userId) return;
    const idCheck = idParam.safeParse(req.params);
    if (!idCheck.success) {
      reply.code(400).send(errorResponse(ErrorCodes.VALIDATION_ERROR, "Invalid id", idCheck.error.issues));
      return;
    }
    await debtService.remove(userId, idCheck.data.id);
    reply.code(204).send();
  }
}

export const debtController = new DebtController();
