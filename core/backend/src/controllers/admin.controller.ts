import { FastifyRequest, FastifyReply } from "fastify";
import { z } from "zod";
import { systemSettingsService } from "../services/system-settings.service.js";
import { dividendScrapeService } from "../services/dividend-scrape.service.js";
import { successResponse, errorResponse, ErrorCodes } from "../utils/response.js";

const updateSettingsSchema = z.object({
  requireRegistration: z.boolean().optional(),
  showClaimBanner: z.boolean().optional(),
});

const scrapeDividendsSchema = z
  .object({
    symbol: z.string().min(1).max(20).regex(/^[A-Za-z0-9]+$/).optional(),
    symbols: z.array(z.string().min(1).max(20).regex(/^[A-Za-z0-9]+$/)).optional(),
    scope: z.enum(["curated", "watchlisted", "all"]).optional(),
    /** Bypass the staleness gate — re-scrape even if recently successful. */
    force: z.boolean().optional(),
    /** Override the per-scope default staleness threshold (days). */
    maxStaleDays: z.number().int().min(0).max(3650).optional(),
  })
  .refine((d) => d.symbol || (d.symbols && d.symbols.length > 0) || d.scope, {
    message: "Provide one of: symbol, symbols, or scope",
  });

class AdminController {
  async getSettings(_req: FastifyRequest, reply: FastifyReply): Promise<void> {
    const settings = await systemSettingsService.get();
    reply.send(successResponse(settings));
  }

  async updateSettings(req: FastifyRequest, reply: FastifyReply): Promise<void> {
    const parsed = updateSettingsSchema.safeParse(req.body);
    if (!parsed.success) {
      reply.code(400).send(errorResponse(ErrorCodes.VALIDATION_ERROR, "Invalid body", parsed.error.issues));
      return;
    }
    const updated = await systemSettingsService.update(parsed.data);
    reply.send(successResponse(updated, "Settings updated"));
  }

  /**
   * POST /api/v1/admin/scrape-dividends
   * Accepts { symbol } | { symbols: [] } | { scope: "curated"|"watchlisted"|"all" }.
   * Persists each FY's cash + bonus declarations as CorporateAction rows
   * (idempotent via unique constraint). Returns per-symbol counts.
   */
  async scrapeDividends(req: FastifyRequest, reply: FastifyReply): Promise<void> {
    const parsed = scrapeDividendsSchema.safeParse(req.body ?? {});
    if (!parsed.success) {
      reply.code(400).send(errorResponse(ErrorCodes.VALIDATION_ERROR, "Invalid body", parsed.error.issues));
      return;
    }
    let symbols: string[];
    if (parsed.data.symbol) {
      symbols = [parsed.data.symbol.toUpperCase()];
    } else if (parsed.data.symbols) {
      symbols = parsed.data.symbols.map((s) => s.toUpperCase());
    } else {
      symbols = await dividendScrapeService.symbolsForScope(parsed.data.scope!);
    }
    const results = await dividendScrapeService.scrapeMany(symbols, {
      force: parsed.data.force,
      maxStaleDays: parsed.data.maxStaleDays,
    });
    const okCount = results.filter((r) => r.ok).length;
    const skippedByGate = results.filter((r) => r.skippedByGate).length;
    reply.send(successResponse(
      {
        requested: symbols.length,
        ok: okCount,
        failed: symbols.length - okCount,
        skippedByGate,
        results,
      },
      `Scraped ${okCount - skippedByGate}/${symbols.length} symbols (${skippedByGate} skipped — recently scraped)`,
    ));
  }
}

export const adminController = new AdminController();
