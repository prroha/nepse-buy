import { FastifyRequest, FastifyReply } from "fastify";
import { z } from "zod";
import { CorporateActionType } from "@prisma/client";
import { corporateActionService } from "../services/corporate-action.service.js";
import { successResponse, errorResponse, ErrorCodes } from "../utils/response.js";

const listQuerySchema = z.object({
  symbol: z.string().min(1).max(20).regex(/^[A-Za-z0-9]+$/).optional(),
  stockId: z.string().uuid().optional(),
}).refine((d) => d.symbol || d.stockId, { message: "symbol or stockId required" });

const createBodySchema = z
  .object({
    stockId: z.string().uuid().optional(),
    symbol: z.string().min(1).max(20).regex(/^[A-Za-z0-9]+$/).optional(),
    type: z.nativeEnum(CorporateActionType),
    pct: z.number().positive().max(1000).optional(),
    rightRatio: z.string().regex(/^\d+:\d+$/).optional(),
    fiscalYear: z.string().regex(/^\d{3}-\d{3}$/).optional(),
    recordDate: z.string().datetime().optional(),
    announcedAt: z.string().datetime().optional(),
  })
  .refine((d) => d.stockId || d.symbol, { message: "stockId or symbol required" });

const idParam = z.object({ id: z.string().uuid("invalid id") });

class CorporateActionController {
  async list(req: FastifyRequest, reply: FastifyReply): Promise<void> {
    const parsed = listQuerySchema.safeParse(req.query);
    if (!parsed.success) {
      reply.code(400).send(errorResponse(ErrorCodes.VALIDATION_ERROR, "Invalid query", parsed.error.issues));
      return;
    }
    const rows = parsed.data.symbol
      ? await corporateActionService.listBySymbol(parsed.data.symbol)
      : await corporateActionService.list(parsed.data.stockId!);
    reply.send(successResponse(rows));
  }

  async create(req: FastifyRequest, reply: FastifyReply): Promise<void> {
    const parsed = createBodySchema.safeParse(req.body);
    if (!parsed.success) {
      reply.code(400).send(errorResponse(ErrorCodes.VALIDATION_ERROR, "Invalid body", parsed.error.issues));
      return;
    }
    const row = await corporateActionService.create({
      stockId: parsed.data.stockId,
      symbol: parsed.data.symbol,
      type: parsed.data.type,
      pct: parsed.data.pct,
      rightRatio: parsed.data.rightRatio,
      fiscalYear: parsed.data.fiscalYear,
      recordDate: parsed.data.recordDate ? new Date(parsed.data.recordDate) : undefined,
      announcedAt: parsed.data.announcedAt ? new Date(parsed.data.announcedAt) : undefined,
    });
    reply.code(201).send(successResponse(row, "Corporate action logged"));
  }

  async remove(req: FastifyRequest, reply: FastifyReply): Promise<void> {
    const parsed = idParam.safeParse(req.params);
    if (!parsed.success) {
      reply.code(400).send(errorResponse(ErrorCodes.VALIDATION_ERROR, "Invalid id", parsed.error.issues));
      return;
    }
    await corporateActionService.remove(parsed.data.id);
    reply.code(204).send();
  }
}

export const corporateActionController = new CorporateActionController();
