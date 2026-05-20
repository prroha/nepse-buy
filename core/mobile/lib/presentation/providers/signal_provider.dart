import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/failures.dart';
import '../../data/local/local_cache.dart';
import '../../data/repositories/signal_repository.dart';

/// Cache key for today's signals — write-through on every successful refresh,
/// read on Notifier.build so the screen has data within ms of opening.
const _kSignalsTodayKey = 'signals/today';

/// Today's signals — cache-first, with a background refresh kicked off when
/// the provider mounts. On a clean cache + no network, the AsyncValue
/// finishes with `[]` (empty), letting the UI render its empty state.
final todaySignalsProvider = AsyncNotifierProvider<TodaySignalsNotifier, List<Signal>>(
  TodaySignalsNotifier.new,
);

/// Exposes the timestamp on the cached row so screens can show "Last updated".
final todaySignalsFreshnessProvider = FutureProvider<DateTime?>((ref) async {
  final cache = await ref.watch(localCacheProvider.future);
  return cache.fetchedAt(_kSignalsTodayKey);
});

class TodaySignalsNotifier extends AsyncNotifier<List<Signal>> {
  @override
  Future<List<Signal>> build() async {
    final cache = await ref.read(localCacheProvider.future);
    final cached = await _readCache(cache);
    // Trigger background refresh — non-blocking. Errors don't unseat the
    // cached state.
    Future.microtask(_refreshFromRemote);
    return cached ?? [];
  }

  Future<List<Signal>?> _readCache(LocalCache cache) async {
    final raw = await cache.getJson(_kSignalsTodayKey);
    if (raw is! List) return null;
    return raw
        .whereType<Map<String, dynamic>>()
        .map(Signal.fromJson)
        .toList(growable: false);
  }

  Future<void> _refreshFromRemote() async {
    final repo = ref.read(signalRepositoryProvider);
    final result = await repo.getToday();
    await result.fold<Future<void>>(
      (_) async => null, // keep cache on failure
      (data) async {
        final cache = await ref.read(localCacheProvider.future);
        await cache.set(
          _kSignalsTodayKey,
          data.map((s) => _signalToJson(s)).toList(growable: false),
        );
        ref.invalidate(todaySignalsFreshnessProvider);
        state = AsyncValue.data(data);
      },
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(signalRepositoryProvider);
      final result = await repo.getToday();
      return result.fold<Future<List<Signal>>>(
        (Failure f) => throw Exception(f.message),
        (List<Signal> ok) async {
          final cache = await ref.read(localCacheProvider.future);
          await cache.set(
            _kSignalsTodayKey,
            ok.map((s) => _signalToJson(s)).toList(growable: false),
          );
          ref.invalidate(todaySignalsFreshnessProvider);
          return ok;
        },
      );
    });
  }
}

/// Per-stock signal history — not cached for now (rarely accessed offline).
final signalHistoryProvider =
    FutureProvider.family<List<Signal>, String>((ref, stockId) async {
  final repo = ref.read(signalRepositoryProvider);
  final result = await repo.getHistory(stockId: stockId);
  return result.fold(
    (f) => throw Exception(f.message),
    (ok) => ok,
  );
});

Map<String, dynamic> _signalToJson(Signal s) => {
      'id': s.id,
      'signalDate': s.signalDate,
      'action': s.action.label,
      'season': s.season,
      'suggestedLimit': s.suggestedLimit,
      'rationale': s.rationale,
      'engineVersion': s.engineVersion,
      'stock': {
        'id': s.stockId,
        'symbol': s.stockSymbol,
        'name': s.stockName,
      },
    };
