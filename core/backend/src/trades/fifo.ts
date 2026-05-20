import type { BuyLot, FifoMatch } from "./types.js";

/**
 * Match a SELL against the oldest BUY lots first. Mutates `lots` in place,
 * decrementing `remainingShares` of consumed lots. Returns the per-lot
 * matches with realized profit + holding-period classification.
 *
 * Throws if there isn't enough remaining BUY inventory to cover the sell
 * — caller (trade service) should validate before recording the trade.
 */
export function fifoMatch(
  lots: BuyLot[],
  sellShares: number,
  sellGrossPricePerShare: number,
  sellExecutedAt: Date,
  longTermDaysThreshold: number,
): FifoMatch[] {
  let remaining = sellShares;
  const matches: FifoMatch[] = [];

  for (const lot of lots) {
    if (remaining <= 0) break;
    if (lot.remainingShares <= 0) continue;

    const take = Math.min(lot.remainingShares, remaining);
    const profitPerShare = sellGrossPricePerShare - lot.netPricePerShare;
    const realizedProfit = take * profitPerShare;
    const holdingDays = daysBetween(lot.executedAt, sellExecutedAt);
    const isLongTerm = holdingDays >= longTermDaysThreshold;

    matches.push({
      buyTradeId: lot.tradeId,
      buyExecutedAt: lot.executedAt,
      buyNetPricePerShare: lot.netPricePerShare,
      matchedShares: take,
      realizedProfit,
      holdingDays,
      isLongTerm,
    });

    lot.remainingShares -= take;
    remaining -= take;
  }

  if (remaining > 0) {
    throw new Error(
      `Insufficient buy inventory: short by ${remaining} share${remaining === 1 ? "" : "s"}`,
    );
  }
  return matches;
}

function daysBetween(a: Date, b: Date): number {
  const ms = b.getTime() - a.getTime();
  return Math.floor(ms / (1000 * 60 * 60 * 24));
}
