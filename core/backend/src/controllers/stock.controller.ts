import { FastifyRequest, FastifyReply } from "fastify";
import { z } from "zod";
import { stockService } from "../services/stock.service.js";
import { successResponse, paginatedResponse, errorResponse, ErrorCodes } from "../utils/response.js";

const listQuerySchema = z.object({
  q: z.string().trim().min(1).max(50).optional(),
  curated: z.enum(["true", "false"]).optional().transform((v) => v === "true"),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

const symbolParamSchema = z.object({
  symbol: z
    .string()
    .min(1)
    .max(20)
    .regex(/^[A-Za-z0-9]+$/, "symbol must be alphanumeric")
    .transform((s) => s.toUpperCase()),
});

class StockController {
  async list(req: FastifyRequest, reply: FastifyReply): Promise<void> {
    const parsed = listQuerySchema.safeParse(req.query);
    if (!parsed.success) {
      reply.code(400).send(errorResponse(ErrorCodes.VALIDATION_ERROR, "Invalid query parameters", parsed.error.issues));
      return;
    }
    const { q, curated, page, limit } = parsed.data;
    const { items, total } = await stockService.list({
      q,
      curatedOnly: !!curated,
      page,
      limit,
    });
    reply.send(paginatedResponse(items, page, limit, total));
  }

  async get(req: FastifyRequest, reply: FastifyReply): Promise<void> {
    const parsed = symbolParamSchema.safeParse(req.params);
    if (!parsed.success) {
      reply.code(400).send(errorResponse(ErrorCodes.VALIDATION_ERROR, "Invalid symbol", parsed.error.issues));
      return;
    }
    const stock = await stockService.getBySymbol(parsed.data.symbol);
    reply.send(successResponse(stock));
  }
}

export const stockController = new StockController();
