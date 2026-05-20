import { FastifyRequest, FastifyReply } from "fastify";
import { z } from "zod";
import { screenerService, type ScreenerType } from "../services/screener.service.js";
import { successResponse, errorResponse, ErrorCodes } from "../utils/response.js";

const querySchema = z.object({
  type: z.enum(["dividend", "growth", "safety"]),
  limit: z.coerce.number().int().min(1).max(50).default(10),
});

class ScreenerController {
  async rank(req: FastifyRequest, reply: FastifyReply): Promise<void> {
    const parsed = querySchema.safeParse(req.query);
    if (!parsed.success) {
      reply.code(400).send(errorResponse(ErrorCodes.VALIDATION_ERROR, "Invalid query", parsed.error.issues));
      return;
    }
    const rows = await screenerService.rank(parsed.data.type as ScreenerType, parsed.data.limit);
    reply.send(successResponse({ type: parsed.data.type, items: rows }));
  }
}

export const screenerController = new ScreenerController();
