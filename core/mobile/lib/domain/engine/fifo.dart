// Dart port of `core/backend/src/trades/fifo.ts` + the BuyLot/FifoMatch
// types from `trades/types.ts`. Pure — no I/O.

class BuyLot {
  BuyLot({
    required this.tradeId,
    required this.executedAt,
    required this.netPricePerShare,
    required this.remainingShares,
  });

  final String tradeId;
  final DateTime executedAt;
  final double netPricePerShare;
  int remainingShares;
}

class FifoMatch {
  FifoMatch({
    required this.buyTradeId,
    required this.buyExecutedAt,
    required this.buyNetPricePerShare,
    required this.matchedShares,
    required this.realizedProfit,
    required this.holdingDays,
    required this.isLongTerm,
  });

  final String buyTradeId;
  final DateTime buyExecutedAt;
  final double buyNetPricePerShare;
  final int matchedShares;
  final double realizedProfit;
  final int holdingDays;
  final bool isLongTerm;
}

class InsufficientInventoryException implements Exception {
  InsufficientInventoryException(this.shortBy);
  final int shortBy;
  @override
  String toString() =>
      'Insufficient buy inventory: short by $shortBy share${shortBy == 1 ? '' : 's'}';
}

/// Matches a SELL against the oldest BUY lots first. Mutates `lots` in
/// place, decrementing `remainingShares` of consumed lots.
List<FifoMatch> fifoMatch({
  required List<BuyLot> lots,
  required int sellShares,
  required double sellGrossPricePerShare,
  required DateTime sellExecutedAt,
  required int longTermDaysThreshold,
}) {
  var remaining = sellShares;
  final matches = <FifoMatch>[];

  for (final lot in lots) {
    if (remaining <= 0) break;
    if (lot.remainingShares <= 0) continue;

    final take =
        lot.remainingShares < remaining ? lot.remainingShares : remaining;
    final profitPerShare = sellGrossPricePerShare - lot.netPricePerShare;
    final realizedProfit = take * profitPerShare;
    final holdingDays = _daysBetween(lot.executedAt, sellExecutedAt);
    final isLongTerm = holdingDays >= longTermDaysThreshold;

    matches.add(FifoMatch(
      buyTradeId: lot.tradeId,
      buyExecutedAt: lot.executedAt,
      buyNetPricePerShare: lot.netPricePerShare,
      matchedShares: take,
      realizedProfit: realizedProfit,
      holdingDays: holdingDays,
      isLongTerm: isLongTerm,
    ));

    lot.remainingShares -= take;
    remaining -= take;
  }

  if (remaining > 0) {
    throw InsufficientInventoryException(remaining);
  }
  return matches;
}

int _daysBetween(DateTime a, DateTime b) {
  final ms = b.difference(a).inMilliseconds;
  return ms ~/ Duration.millisecondsPerDay;
}
