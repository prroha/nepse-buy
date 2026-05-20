import 'types.dart';

/// Dart port of `core/backend/src/signals/decision.ts`. Pure — no I/O.
///
/// Keep the rationale strings byte-equivalent with the TS version when a
/// signal is later shown side-by-side with a server-rendered one. Adjustments
/// are limited to number formatting (NPR + 1000-separator).
Decision decide(DecisionInput input, EngineConfig cfg) {
  final close = input.close;
  if (!close.isFinite || close <= 0) {
    return Decision(
      action: SignalAction.skip,
      rationale: 'No usable close price for the most recent trading day.',
      suggestedLimit: null,
    );
  }

  if (input.ma20 == null) {
    return Decision(
      action: SignalAction.wait,
      rationale:
          'Only ${input.ma20Window} day(s) of price history — need ≥${cfg.ma20MinSamples} to compute the 20-day MA. Skipping until more data is collected.',
      suggestedLimit: null,
    );
  }

  final ma20 = input.ma20!;
  final pe = input.pe;
  final pb = input.pb;
  final peMed = input.peMedian5y;
  final pbMed = input.pbMedian5y;
  final valuationAttractive = cfg.peGateEnabled &&
      pe != null &&
      peMed != null &&
      pe <= peMed &&
      pb != null &&
      pbMed != null &&
      pb <= pbMed;

  final peNote = !cfg.peGateEnabled
      ? ' (Valuation gate disabled.)'
      : (peMed == null || pbMed == null)
          ? ' (Valuation gate not yet active — NEPSE Alpha median data pending.)'
          : valuationAttractive
              ? ' (Valuation attractive: P/E ${pe.toStringAsFixed(2)} ≤ 5y avg ${peMed.toStringAsFixed(2)}, P/B ${pb.toStringAsFixed(2)} ≤ ${pbMed.toStringAsFixed(2)}.)'
              : ' (Valuation rich vs 5y avg: P/E ${pe?.toStringAsFixed(2) ?? "?"} vs ${peMed.toStringAsFixed(2)}, P/B ${pb?.toStringAsFixed(2) ?? "?"} vs ${pbMed.toStringAsFixed(2)}.)';

  // HARVEST first — exit a winning position regardless of season.
  final pos = input.position;
  if (pos != null && pos.totalShares > 0 && pos.avgCost > 0) {
    final paperPL = (close - pos.avgCost) / pos.avgCost;
    if (paperPL >= cfg.harvestThreshold) {
      final sellShares =
          (pos.totalShares * cfg.harvestSellFraction).floor().clamp(1, pos.totalShares);
      final sellValue = sellShares * close;
      final seasonNote = input.season == Season.strong
          ? ' (Strong-season month — optimal timing for harvest per strategy doc.)'
          : '';
      return Decision(
        action: SignalAction.harvest,
        rationale:
            'Position up ${(paperPL * 100).toStringAsFixed(1)}% — '
            '${pos.totalShares} shares @ avg Rs ${pos.avgCost.toStringAsFixed(2)}, '
            'now Rs ${close.toStringAsFixed(2)}. '
            'Sell $sellShares shares (~${(cfg.harvestSellFraction * 100).toStringAsFixed(0)}% of position, ≈ Rs ${sellValue.toStringAsFixed(0)}) '
            'and route proceeds to OD principal.$seasonNote$peNote',
        suggestedLimit: null,
      );
    }
  }

  if (input.season == Season.strong) {
    var debtLine =
        'Deploy this month\'s surplus to your overdraft-loan principal instead.';
    final debt = input.debt;
    if (debt != null && debt.totalBalance > 0) {
      final dailyInterest =
          (debt.monthlySurplus * debt.weightedAvgRate) / 100 / 365;
      final monthSavings = dailyInterest * 30;
      debtLine = 'Deploy this month\'s Rs ${_fmtIN(debt.monthlySurplus)} surplus to your "${debt.primaryName}" '
          '(outstanding Rs ${_fmtIN(debt.totalBalance)} @ ${debt.weightedAvgRate.toStringAsFixed(2)}% p.a.). '
          'Saves ≈ Rs ${monthSavings.toStringAsFixed(0)} in interest over the next ~30 days.';
    }
    return Decision(
      action: SignalAction.holdFunds,
      rationale:
          'Strong-season month (Jan/Jul/Aug — retail FOMO + Shrawan-Bhadra liquidity). '
          'Pause weekly DCA. $debtLine$peNote',
      suggestedLimit: null,
    );
  }

  final patientLimit = _suggestLimit(close, cfg.limitDiscountPatient);
  final aggressiveLimit = _suggestLimit(close, cfg.limitDiscountAggressive);

  if (input.season == Season.weak) {
    if (close <= ma20) {
      return Decision(
        action: SignalAction.buy,
        rationale:
            'Weak-season month: close Rs ${close.toStringAsFixed(2)} ≤ 20-day MA Rs ${ma20.toStringAsFixed(2)} — dip qualified. '
            'Place a limit order: Rs ${patientLimit.toStringAsFixed(2)} (patient, 1% off) or Rs ${aggressiveLimit.toStringAsFixed(2)} (aggressive, 2% off).$peNote',
        suggestedLimit: patientLimit,
      );
    }
    if (valuationAttractive) {
      return Decision(
        action: SignalAction.buy,
        rationale:
            'Weak-season month: price above MA20 but valuation gate qualifies — current P/E ${pe.toStringAsFixed(2)} ≤ 5y avg ${peMed.toStringAsFixed(2)} '
            'and P/B ${pb.toStringAsFixed(2)} ≤ ${pbMed.toStringAsFixed(2)}. '
            'Limit: Rs ${patientLimit.toStringAsFixed(2)} (1% off) or Rs ${aggressiveLimit.toStringAsFixed(2)} (2% off).',
        suggestedLimit: patientLimit,
      );
    }
    return Decision(
      action: SignalAction.wait,
      rationale:
          'Weak-season month: close Rs ${close.toStringAsFixed(2)} above 20-day MA Rs ${ma20.toStringAsFixed(2)}. '
          'Wait for pullback toward MA before deploying.$peNote',
      suggestedLimit: null,
    );
  }

  // NORMAL season
  return Decision(
    action: SignalAction.buy,
    rationale:
        'Normal-season month — weekly DCA proceeds. '
        'Close Rs ${close.toStringAsFixed(2)}, 20-day MA Rs ${ma20.toStringAsFixed(2)}. '
        'Limit: Rs ${patientLimit.toStringAsFixed(2)} (1% off) or Rs ${aggressiveLimit.toStringAsFixed(2)} (2% off).$peNote',
    suggestedLimit: patientLimit,
  );
}

double _suggestLimit(double close, double discount) {
  return (close * discount * 100).round() / 100;
}

/// Indian-locale thousands separator (e.g., 1,00,000). Mirrors the TS
/// `toLocaleString("en-IN")` formatting used in debt-line rationale.
String _fmtIN(double n) {
  final intPart = n.truncate().toString();
  if (intPart.length <= 3) return intPart;
  final last3 = intPart.substring(intPart.length - 3);
  var rest = intPart.substring(0, intPart.length - 3);
  final chunks = <String>[];
  while (rest.length > 2) {
    chunks.add(rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) chunks.add(rest);
  return '${chunks.reversed.join(',')},$last3';
}
