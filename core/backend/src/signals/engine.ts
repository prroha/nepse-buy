import type { PrismaClient } from "@prisma/client";
import { db } from "../lib/db.js";
import { logger } from "../lib/logger.js";
import { decide } from "./decision.js";
import { movingAverage } from "./moving-average.js";
import { classifySeason } from "./season.js";
import { DEFAULT_ENGINE_CONFIG, ENGINE_VERSION, type EngineConfig } from "./types.js";
import { debtService } from "../services/debt.service.js";
import { positionService } from "../services/position.service.js";

export interface EvaluateRequest {
  userId: string;
  stockId: string;
  signalDate: Date;
}

export class SignalEngine {
  constructor(
    private readonly prisma: PrismaClient = db,
    private readonly cfg: EngineConfig = DEFAULT_ENGINE_CONFIG,
  ) {}

  /**
   * Evaluate one (user, stock, date) and upsert the result into DailySignal.
   * Returns the signal id.
   */
  async evaluate(req: EvaluateRequest): Promise<{ signalId: string; action: string }> {
    // Most recent close ≤ signalDate, picking the latest observation across sources
    // (we don't dedupe across sources here — that's a read concern, and append-only
    // means most-recent-by-fetched_at wins for a given trade_date).
    const closeRows = await this.prisma.priceObservation.findMany({
      where: { stockId: req.stockId, tradeDate: { lte: req.signalDate } },
      orderBy: [{ tradeDate: "desc" }, { fetchedAt: "desc" }],
      take: 30,
      select: { tradeDate: true, close: true, source: true, fetchedAt: true },
    });

    // Pick one close per tradeDate (newest fetch wins) for the MA window.
    const closesByDate = new Map<string, string>();
    for (const r of closeRows) {
      const k = r.tradeDate.toISOString().slice(0, 10);
      if (!closesByDate.has(k)) closesByDate.set(k, r.close.toString());
    }
    const sortedKeys = [...closesByDate.keys()].sort().reverse();
    const recentCloses = sortedKeys.map((k) => closesByDate.get(k)!);

    const ma = movingAverage(recentCloses, 20, this.cfg.ma20MinSamples);
    const close = recentCloses[0] ?? "0";

    // Current fundamentals come from the freshest observation (Mero Lagani daily).
    // 3-5yr medians come from the most recent observation that HAS them set
    // (NEPSE Alpha — scraped weekly).
    const [fund, fundWithMedian] = await Promise.all([
      this.prisma.fundamentalsObservation.findFirst({
        where: { stockId: req.stockId, observedAt: { lte: req.signalDate } },
        orderBy: [{ observedAt: "desc" }, { fetchedAt: "desc" }],
        select: { pe: true, pb: true, observedAt: true },
      }),
      this.prisma.fundamentalsObservation.findFirst({
        where: {
          stockId: req.stockId,
          observedAt: { lte: req.signalDate },
          peMedian5y: { not: null },
        },
        orderBy: [{ observedAt: "desc" }, { fetchedAt: "desc" }],
        select: { peMedian5y: true, pbMedian5y: true },
      }),
    ]);

    const season = classifySeason(req.signalDate, this.cfg.timezone);
    // Position fetched every evaluation — harvest can fire in any season.
    const position = await positionService.getPositionContext(req.userId, req.stockId);
    // Debt only relevant on STRONG-season HOLD_FUNDS path.
    const debt = season === "STRONG" ? await debtService.getDebtContext(req.userId) : null;
    const decision = decide(
      {
        close,
        ma20: ma.value,
        ma20Window: ma.samplesUsed,
        season,
        pe: fund?.pe?.toString() ?? null,
        pb: fund?.pb?.toString() ?? null,
        peMedian5y: fundWithMedian?.peMedian5y?.toString() ?? null,
        pbMedian5y: fundWithMedian?.pbMedian5y?.toString() ?? null,
        debt,
        position,
      },
      this.cfg,
    );

    const inputsSnapshot = {
      close,
      ma20: ma.value,
      ma20_window_used: ma.samplesUsed,
      season,
      pe: fund?.pe?.toString() ?? null,
      pb: fund?.pb?.toString() ?? null,
      pe_median_5y: fundWithMedian?.peMedian5y?.toString() ?? null,
      pb_median_5y: fundWithMedian?.pbMedian5y?.toString() ?? null,
      pe_gate_enabled: this.cfg.peGateEnabled,
      observation_count: closesByDate.size,
    };

    const result = await this.prisma.dailySignal.upsert({
      where: {
        userId_stockId_signalDate: {
          userId: req.userId,
          stockId: req.stockId,
          signalDate: req.signalDate,
        },
      },
      create: {
        userId: req.userId,
        stockId: req.stockId,
        signalDate: req.signalDate,
        action: decision.action,
        season,
        suggestedLimit: decision.suggestedLimit,
        rationale: decision.rationale,
        inputsSnapshot,
        engineVersion: ENGINE_VERSION,
      },
      update: {
        action: decision.action,
        season,
        suggestedLimit: decision.suggestedLimit,
        rationale: decision.rationale,
        inputsSnapshot,
        engineVersion: ENGINE_VERSION,
      },
      select: { id: true, action: true },
    });

    logger.info("Signal evaluated", {
      userId: req.userId,
      stockId: req.stockId,
      action: result.action,
      season,
      close,
      ma20: ma.value,
    });

    return { signalId: result.id, action: result.action };
  }

  /**
   * Convenience: evaluate every stock in a user's watchlist for a given date.
   */
  async evaluateWatchlist(userId: string, signalDate: Date): Promise<Array<{ stockId: string; action: string }>> {
    const items = await this.prisma.watchlistItem.findMany({
      where: { userId, alertsEnabled: true },
      select: { stockId: true },
    });
    const results: Array<{ stockId: string; action: string }> = [];
    for (const it of items) {
      const r = await this.evaluate({ userId, stockId: it.stockId, signalDate });
      results.push({ stockId: it.stockId, action: r.action });
    }
    return results;
  }
}
