import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/failures.dart';
import '../../domain/engine/signal_engine.dart';
import '../../domain/engine/types.dart' as engine_types;
import '../local/signal_history_repository.dart';
import '../local/user_data_repository.dart';
import '../static/static_data_client.dart';
import '../static/static_data_models.dart';
import 'base_repository.dart';

enum SignalAction { buy, wait, skip, holdFunds, harvest }

extension SignalActionExt on SignalAction {
  String get label => switch (this) {
        SignalAction.buy => 'BUY',
        SignalAction.wait => 'WAIT',
        SignalAction.skip => 'SKIP',
        SignalAction.holdFunds => 'HOLD',
        SignalAction.harvest => 'HARVEST',
      };
}

SignalAction signalActionFrom(String s) => switch (s.toUpperCase()) {
      'BUY' => SignalAction.buy,
      'WAIT' => SignalAction.wait,
      'HOLD_FUNDS' => SignalAction.holdFunds,
      'HARVEST' => SignalAction.harvest,
      _ => SignalAction.skip,
    };

class Signal {
  final String id;
  final String signalDate;
  final SignalAction action;
  final String season;
  final String? suggestedLimit;
  final String rationale;
  final String engineVersion;
  final String stockId;
  final String stockSymbol;
  final String stockName;

  const Signal({
    required this.id,
    required this.signalDate,
    required this.action,
    required this.season,
    required this.suggestedLimit,
    required this.rationale,
    required this.engineVersion,
    required this.stockId,
    required this.stockSymbol,
    required this.stockName,
  });

  factory Signal.fromJson(Map<String, dynamic> json) {
    final stock = (json['stock'] as Map<String, dynamic>);
    return Signal(
      id: json['id'] as String,
      signalDate: json['signalDate'] as String,
      action: signalActionFrom(json['action'] as String),
      season: json['season'] as String,
      suggestedLimit: json['suggestedLimit'] as String?,
      rationale: json['rationale'] as String,
      engineVersion: json['engineVersion'] as String,
      stockId: stock['id'] as String,
      stockSymbol: stock['symbol'] as String,
      stockName: stock['name'] as String,
    );
  }
}

final signalRepositoryProvider = Provider<SignalRepository>((ref) {
  return SignalRepositoryImpl(ref: ref);
});

abstract class SignalRepository {
  Future<Either<Failure, List<Signal>>> getToday({String? date});
  Future<Either<Failure, List<Signal>>> getHistory({
    required String stockId,
    int limit = 60,
  });
}

/// Today's signals are computed on-device for every watchlisted symbol via
/// the ported [SignalEngine]. Historical signals aren't persisted yet — the
/// engine has no DB on-device. Each call to `getHistory` replays the engine
/// across the most recent `limit` trading days using the cached price
/// series; this keeps the screens working without a server while keeping
/// the API stable.
class SignalRepositoryImpl with BaseRepository implements SignalRepository {
  SignalRepositoryImpl({required this.ref});
  final Ref ref;

  Future<UserDataRepository> get _userData =>
      ref.read(userDataRepositoryProvider.future);
  Future<StaticDataClient> get _staticClient =>
      ref.read(staticDataClientProvider.future);
  Future<SignalEngine> get _engine =>
      ref.read(signalEngineProvider.future);
  Future<SignalHistoryRepository> get _history =>
      ref.read(signalHistoryRepositoryProvider.future);

  static String _ymd(DateTime d) {
    final u = d.toUtc();
    return '${u.year.toString().padLeft(4, '0')}-${u.month.toString().padLeft(2, '0')}-${u.day.toString().padLeft(2, '0')}';
  }

  Signal _toSignal({
    required String symbol,
    required String name,
    required EvaluatedSignal evaluated,
  }) {
    return Signal(
      id: '$symbol:${_ymd(evaluated.signalDate)}',
      signalDate: _ymd(evaluated.signalDate),
      action: signalActionFrom(
          engine_types.SignalActionWire(evaluated.decision.action).wire),
      season: engine_types.SeasonWire(evaluated.season).wire,
      suggestedLimit: evaluated.decision.suggestedLimit?.toStringAsFixed(2),
      rationale: evaluated.decision.rationale,
      engineVersion: evaluated.engineVersion,
      stockId: symbol,
      stockSymbol: symbol,
      stockName: name,
    );
  }

  @override
  Future<Either<Failure, List<Signal>>> getToday({String? date}) {
    return safeCall(() async {
      final userData = await _userData;
      final staticClient = await _staticClient;
      final engineInstance = await _engine;
      final watchlist = await userData.listWatchlist();
      if (watchlist.isEmpty) return const <Signal>[];

      final signalDate =
          date != null ? DateTime.parse('${date}T00:00:00Z') : DateTime.now();
      final stocks = await staticClient.getStocks();
      final byKey = {for (final s in stocks) s.symbol.toUpperCase(): s};

      final history = await _history;
      final results = <Signal>[];
      for (final row in watchlist) {
        final symbol = (row['symbol'] as String).toUpperCase();
        final evaluated = await engineInstance.evaluate(
          symbol: symbol,
          signalDate: signalDate,
        );
        await history.record(
          symbol: symbol,
          signalDate: _ymd(evaluated.signalDate),
          action: engine_types.SignalActionWire(evaluated.decision.action).wire,
          season: engine_types.SeasonWire(evaluated.season).wire,
          suggestedLimit: evaluated.decision.suggestedLimit,
          rationale: evaluated.decision.rationale,
          engineVersion: evaluated.engineVersion,
          closeAtSignal: evaluated.close,
        );
        results.add(_toSignal(
          symbol: symbol,
          name: byKey[symbol]?.name ?? symbol,
          evaluated: evaluated,
        ));
      }
      return results;
    });
  }

  @override
  Future<Either<Failure, List<Signal>>> getHistory({
    required String stockId,
    int limit = 60,
  }) {
    return safeCall(() async {
      final staticClient = await _staticClient;
      final engineInstance = await _engine;
      final stocks = await staticClient.getStocks();
      final meta = stocks.firstWhere(
        (s) => s.symbol.toUpperCase() == stockId.toUpperCase(),
        orElse: () => StaticStock(
          symbol: stockId.toUpperCase(),
          name: stockId.toUpperCase(),
          sector: null,
          status: 'ACTIVE',
          tier: 'STANDARD',
          isCurated: false,
        ),
      );
      final prices = await staticClient.getPrices(stockId);
      if (prices.isEmpty) return const <Signal>[];

      // Each unique tradeDate in the price series produces one back-test
      // signal — capped to `limit`.
      final dates = prices
          .map((p) => p.tradeDate)
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a));
      final picked = dates.take(limit);

      final out = <Signal>[];
      for (final d in picked) {
        final evaluated =
            await engineInstance.evaluate(symbol: stockId, signalDate: d);
        out.add(_toSignal(
          symbol: stockId.toUpperCase(),
          name: meta.name,
          evaluated: evaluated,
        ));
      }
      return out;
    });
  }
}

