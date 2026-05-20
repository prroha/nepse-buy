import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/static/static_data_client.dart';
import '../../data/static/static_data_models.dart';
import 'decision.dart';
import 'moving_average.dart';
import 'season.dart';
import 'types.dart';

/// On-device signal engine. Reads prices + fundamentals from the static
/// JSON bundle (`StaticDataClient`), assembles a `DecisionInput`, and runs
/// the pure `decide` function. Position + debt context are supplied by the
/// caller (the UI layer pulls those from local storage / user input).
class SignalEngine {
  SignalEngine(this._client, {EngineConfig? config})
      : _config = config ?? defaultEngineConfig;

  final StaticDataClient _client;
  final EngineConfig _config;

  EngineConfig get config => _config;

  Future<EvaluatedSignal> evaluate({
    required String symbol,
    required DateTime signalDate,
    PositionContext? position,
    DebtContext? debt,
  }) async {
    final pricesAll = await _client.getPrices(symbol);
    // Filter to ≤ signalDate, pick newest fetch per tradeDate, then sort
    // most-recent-first.
    final byDate = <String, StaticPrice>{};
    for (final p in pricesAll) {
      if (p.tradeDate.isAfter(signalDate)) continue;
      final key = _ymd(p.tradeDate);
      // The JSON is already deduped per tradeDate, but be defensive.
      byDate.putIfAbsent(key, () => p);
    }
    final sortedKeys = byDate.keys.toList()..sort((a, b) => b.compareTo(a));
    final recentCloses =
        sortedKeys.map((k) => byDate[k]!.close).toList(growable: false);

    final ma = movingAverage(
      recentCloses,
      windowSize: 20,
      minSamples: _config.ma20MinSamples,
    );
    final close = recentCloses.isEmpty ? 0.0 : recentCloses.first;

    final fund = await _client.getFundamentals(symbol);
    final season =
        classifySeason(signalDate, tzOffsetHours: _config.timezoneOffsetHours);
    // Debt is only relevant on STRONG-season HOLD_FUNDS path; caller-supplied
    // value is forwarded verbatim.
    final effectiveDebt = season == Season.strong ? debt : null;

    final decision = decide(
      DecisionInput(
        close: close,
        ma20: ma.value,
        ma20Window: ma.samplesUsed,
        season: season,
        pe: fund?.pe,
        pb: fund?.pb,
        peMedian5y: fund?.peMedian5y,
        pbMedian5y: fund?.pbMedian5y,
        debt: effectiveDebt,
        position: position,
      ),
      _config,
    );

    return EvaluatedSignal(
      symbol: symbol,
      signalDate: signalDate,
      decision: decision,
      season: season,
      close: close,
      ma20: ma.value,
      ma20Window: ma.samplesUsed,
      pe: fund?.pe,
      pb: fund?.pb,
      peMedian5y: fund?.peMedian5y,
      pbMedian5y: fund?.pbMedian5y,
      engineVersion: engineVersion,
    );
  }

  static String _ymd(DateTime d) {
    final u = d.toUtc();
    return '${u.year.toString().padLeft(4, '0')}-${u.month.toString().padLeft(2, '0')}-${u.day.toString().padLeft(2, '0')}';
  }
}

class EvaluatedSignal {
  EvaluatedSignal({
    required this.symbol,
    required this.signalDate,
    required this.decision,
    required this.season,
    required this.close,
    required this.ma20,
    required this.ma20Window,
    required this.pe,
    required this.pb,
    required this.peMedian5y,
    required this.pbMedian5y,
    required this.engineVersion,
  });

  final String symbol;
  final DateTime signalDate;
  final Decision decision;
  final Season season;
  final double close;
  final double? ma20;
  final int ma20Window;
  final double? pe;
  final double? pb;
  final double? peMedian5y;
  final double? pbMedian5y;
  final String engineVersion;
}

final signalEngineProvider = FutureProvider<SignalEngine>((ref) async {
  final client = await ref.watch(staticDataClientProvider.future);
  // If the bundle ships a `signals-engine.json`, prefer its values so the
  // device matches whatever the exporter produced.
  try {
    final json = await client.getEngineConfig();
    final cfg = EngineConfig.fromExportJson(json);
    return SignalEngine(client, config: cfg);
  } catch (_) {
    return SignalEngine(client);
  }
});
