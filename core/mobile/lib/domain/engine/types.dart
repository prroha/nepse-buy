/// Dart port of the backend signal engine's pure types
/// (`core/backend/src/signals/types.ts` + `trades/types.ts`).
///
/// Keep this file and its TS sibling in lock-step — the engine version
/// string is the contract.
library;

enum Season { weak, normal, strong }

enum SignalAction { buy, wait, skip, holdFunds, harvest }

extension SignalActionWire on SignalAction {
  String get wire {
    switch (this) {
      case SignalAction.buy:
        return 'BUY';
      case SignalAction.wait:
        return 'WAIT';
      case SignalAction.skip:
        return 'SKIP';
      case SignalAction.holdFunds:
        return 'HOLD_FUNDS';
      case SignalAction.harvest:
        return 'HARVEST';
    }
  }
}

extension SeasonWire on Season {
  String get wire {
    switch (this) {
      case Season.weak:
        return 'WEAK';
      case Season.normal:
        return 'NORMAL';
      case Season.strong:
        return 'STRONG';
    }
  }
}

class DebtContext {
  DebtContext({
    required this.totalBalance,
    required this.weightedAvgRate,
    required this.primaryName,
    required this.monthlySurplus,
  });

  final double totalBalance;
  final double weightedAvgRate;
  final String primaryName;
  final double monthlySurplus;
}

class PositionContext {
  PositionContext({
    required this.totalShares,
    required this.avgCost,
  });

  final int totalShares;
  final double avgCost;
}

class DecisionInput {
  DecisionInput({
    required this.close,
    required this.ma20,
    required this.ma20Window,
    required this.season,
    this.pe,
    this.pb,
    this.peMedian5y,
    this.pbMedian5y,
    this.debt,
    this.position,
  });

  final double close;
  final double? ma20;
  final int ma20Window;
  final Season season;
  final double? pe;
  final double? pb;
  final double? peMedian5y;
  final double? pbMedian5y;
  final DebtContext? debt;
  final PositionContext? position;
}

class Decision {
  Decision({
    required this.action,
    required this.rationale,
    this.suggestedLimit,
  });

  final SignalAction action;
  final String rationale;
  final double? suggestedLimit;
}

class EngineConfig {
  const EngineConfig({
    this.ma20MinSamples = 20,
    this.limitDiscountPatient = 0.99,
    this.limitDiscountAggressive = 0.98,
    this.peGateEnabled = true,
    this.timezoneOffsetHours = 5.75,
    this.harvestThreshold = 0.30,
    this.harvestSellFraction = 0.25,
  });

  final int ma20MinSamples;
  final double limitDiscountPatient;
  final double limitDiscountAggressive;
  final bool peGateEnabled;

  /// IANA tz strings aren't available without intl-tzdata. Nepal time is
  /// UTC+5:45 = 5.75 hours; we use the offset directly for season
  /// classification (`engine reads only the month`).
  final double timezoneOffsetHours;

  final double harvestThreshold;
  final double harvestSellFraction;

  EngineConfig copyWith({
    int? ma20MinSamples,
    double? limitDiscountPatient,
    double? limitDiscountAggressive,
    bool? peGateEnabled,
    double? timezoneOffsetHours,
    double? harvestThreshold,
    double? harvestSellFraction,
  }) =>
      EngineConfig(
        ma20MinSamples: ma20MinSamples ?? this.ma20MinSamples,
        limitDiscountPatient: limitDiscountPatient ?? this.limitDiscountPatient,
        limitDiscountAggressive:
            limitDiscountAggressive ?? this.limitDiscountAggressive,
        peGateEnabled: peGateEnabled ?? this.peGateEnabled,
        timezoneOffsetHours: timezoneOffsetHours ?? this.timezoneOffsetHours,
        harvestThreshold: harvestThreshold ?? this.harvestThreshold,
        harvestSellFraction: harvestSellFraction ?? this.harvestSellFraction,
      );

  /// Reads the JSON shape produced by `signals-engine.json`. Only known fields
  /// are pulled — unknowns are ignored so older app builds keep working.
  factory EngineConfig.fromExportJson(Map<String, dynamic> json) {
    final cfg = (json['config'] as Map?)?.cast<String, dynamic>() ?? json;
    return EngineConfig(
      ma20MinSamples: (cfg['ma20MinSamples'] as num?)?.toInt() ?? 20,
      limitDiscountPatient:
          (cfg['limitDiscountPatient'] as num?)?.toDouble() ?? 0.99,
      limitDiscountAggressive:
          (cfg['limitDiscountAggressive'] as num?)?.toDouble() ?? 0.98,
      peGateEnabled: cfg['peGateEnabled'] as bool? ?? true,
      harvestThreshold:
          (cfg['harvestThreshold'] as num?)?.toDouble() ?? 0.30,
      harvestSellFraction:
          (cfg['harvestSellFraction'] as num?)?.toDouble() ?? 0.25,
      // tz from the JSON is a string ("Asia/Kathmandu"); we only need the
      // numeric offset on-device, so we keep our default.
    );
  }
}

const String engineVersion = '0.5.0-pe-gate-enabled';
const EngineConfig defaultEngineConfig = EngineConfig();
