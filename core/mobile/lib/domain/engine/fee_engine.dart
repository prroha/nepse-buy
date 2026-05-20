import 'fifo.dart';

/// Dart port of `core/backend/src/trades/fee-engine.ts` + FeeSchedule from
/// `trades/types.ts`. Pure — no I/O.

class BrokerageSlab {
  const BrokerageSlab({required this.upTo, required this.ratePct});
  final double? upTo;
  final double ratePct;
}

class FeeSchedule {
  const FeeSchedule({
    required this.brokerageSlabs,
    required this.sebonRatePct,
    required this.dpFlatFee,
    required this.cgtShortTermPct,
    required this.cgtLongTermPct,
    required this.longTermDaysThreshold,
  });

  final List<BrokerageSlab> brokerageSlabs;
  final double sebonRatePct;
  final double dpFlatFee;
  final double cgtShortTermPct;
  final double cgtLongTermPct;
  final int longTermDaysThreshold;

  FeeSchedule copyWith({
    List<BrokerageSlab>? brokerageSlabs,
    double? sebonRatePct,
    double? dpFlatFee,
    double? cgtShortTermPct,
    double? cgtLongTermPct,
    int? longTermDaysThreshold,
  }) =>
      FeeSchedule(
        brokerageSlabs: brokerageSlabs ?? this.brokerageSlabs,
        sebonRatePct: sebonRatePct ?? this.sebonRatePct,
        dpFlatFee: dpFlatFee ?? this.dpFlatFee,
        cgtShortTermPct: cgtShortTermPct ?? this.cgtShortTermPct,
        cgtLongTermPct: cgtLongTermPct ?? this.cgtLongTermPct,
        longTermDaysThreshold:
            longTermDaysThreshold ?? this.longTermDaysThreshold,
      );
}

/// NEPSE 2024+ defaults. Mirrors `DEFAULT_FEE_SCHEDULE` in TS.
const FeeSchedule defaultFeeSchedule = FeeSchedule(
  brokerageSlabs: [
    BrokerageSlab(upTo: 50000, ratePct: 0.36),
    BrokerageSlab(upTo: 500000, ratePct: 0.33),
    BrokerageSlab(upTo: 2000000, ratePct: 0.31),
    BrokerageSlab(upTo: 10000000, ratePct: 0.27),
    BrokerageSlab(upTo: null, ratePct: 0.24),
  ],
  sebonRatePct: 0.015,
  dpFlatFee: 25,
  cgtShortTermPct: 7.5,
  cgtLongTermPct: 5,
  longTermDaysThreshold: 365,
);

class CgtMatch {
  CgtMatch({
    required this.buyTradeId,
    required this.matchedShares,
    required this.profit,
    required this.cgtPct,
    required this.cgtAmount,
  });
  final String buyTradeId;
  final int matchedShares;
  final double profit;
  final double cgtPct;
  final double cgtAmount;
}

class BuyFees {
  BuyFees({
    required this.brokerCommission,
    required this.sebonFee,
    required this.dpFee,
    required this.totalFees,
    required this.netPricePerShare,
  });
  final double brokerCommission;
  final double sebonFee;
  final double dpFee;
  final double totalFees;
  final double netPricePerShare;
}

class SellFees {
  SellFees({
    required this.brokerCommission,
    required this.sebonFee,
    required this.dpFee,
    required this.totalFees,
    required this.cgtBreakdown,
    required this.cgt,
    required this.netProceedsPerShare,
  });
  final double brokerCommission;
  final double sebonFee;
  final double dpFee;
  final double totalFees;
  final List<CgtMatch> cgtBreakdown;
  final double cgt;
  final double netProceedsPerShare;
}

double computeBrokerage(double transactionValue, FeeSchedule schedule) {
  for (final slab in schedule.brokerageSlabs) {
    if (slab.upTo == null || transactionValue <= slab.upTo!) {
      return _roundCurrency(transactionValue * (slab.ratePct / 100));
    }
  }
  final last = schedule.brokerageSlabs.last;
  return _roundCurrency(transactionValue * (last.ratePct / 100));
}

BuyFees computeBuyFees(
  int shares,
  double grossPricePerShare,
  FeeSchedule schedule,
) {
  final transactionValue = shares * grossPricePerShare;
  final brokerCommission = computeBrokerage(transactionValue, schedule);
  final sebonFee =
      _roundCurrency(transactionValue * (schedule.sebonRatePct / 100));
  final dpFee = schedule.dpFlatFee;
  final totalFees = brokerCommission + sebonFee + dpFee;
  final netPricePerShare = _round4((transactionValue + totalFees) / shares);
  return BuyFees(
    brokerCommission: brokerCommission,
    sebonFee: sebonFee,
    dpFee: dpFee,
    totalFees: totalFees,
    netPricePerShare: netPricePerShare,
  );
}

SellFees computeSellFees(
  int shares,
  double grossPricePerShare,
  List<FifoMatch> matches,
  FeeSchedule schedule,
) {
  final transactionValue = shares * grossPricePerShare;
  final brokerCommission = computeBrokerage(transactionValue, schedule);
  final sebonFee =
      _roundCurrency(transactionValue * (schedule.sebonRatePct / 100));
  final dpFee = schedule.dpFlatFee;
  final totalFees = brokerCommission + sebonFee + dpFee;

  final breakdown = <CgtMatch>[];
  var cgt = 0.0;
  for (final m in matches) {
    if (m.realizedProfit <= 0) continue;
    final ratePct =
        m.isLongTerm ? schedule.cgtLongTermPct : schedule.cgtShortTermPct;
    final cgtAmount = _roundCurrency(m.realizedProfit * (ratePct / 100));
    cgt += cgtAmount;
    breakdown.add(CgtMatch(
      buyTradeId: m.buyTradeId,
      matchedShares: m.matchedShares,
      profit: _roundCurrency(m.realizedProfit),
      cgtPct: ratePct,
      cgtAmount: cgtAmount,
    ));
  }
  cgt = _roundCurrency(cgt);
  final netProceedsPerShare =
      _round4((transactionValue - totalFees - cgt) / shares);
  return SellFees(
    brokerCommission: brokerCommission,
    sebonFee: sebonFee,
    dpFee: dpFee,
    totalFees: totalFees,
    cgtBreakdown: breakdown,
    cgt: cgt,
    netProceedsPerShare: netProceedsPerShare,
  );
}

double _roundCurrency(double n) => (n * 100).round() / 100;
double _round4(double n) => (n * 10000).round() / 10000;
