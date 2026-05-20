import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/failures.dart';
import '../../core/services/connectivity_service.dart';
import '../../data/local/local_cache.dart';
import '../../data/local/outbox.dart';
import '../../data/repositories/position_repository.dart';
import '../../data/sync/sync_service.dart';

const _kPositionsKey = 'positions';

final positionsProvider = AsyncNotifierProvider<PositionsNotifier, List<Position>>(
  PositionsNotifier.new,
);

final positionsFreshnessProvider = FutureProvider<DateTime?>((ref) async {
  final cache = await ref.watch(localCacheProvider.future);
  return cache.fetchedAt(_kPositionsKey);
});

class PositionsNotifier extends AsyncNotifier<List<Position>> {
  @override
  Future<List<Position>> build() async {
    final cache = await ref.read(localCacheProvider.future);
    final cached = await _readCache(cache);
    Future.microtask(_refreshFromRemote);
    return cached ?? [];
  }

  Future<List<Position>?> _readCache(LocalCache cache) async {
    final raw = await cache.getJson(_kPositionsKey);
    if (raw is! List) return null;
    return raw
        .whereType<Map<String, dynamic>>()
        .map(Position.fromJson)
        .toList(growable: false);
  }

  Future<void> _refreshFromRemote() async {
    final repo = ref.read(positionRepositoryProvider);
    final result = await repo.list();
    await result.fold<Future<void>>(
      (_) async => null,
      (data) async {
        await _writeCache(data);
        state = AsyncValue.data(data);
      },
    );
  }

  Future<void> _writeCache(List<Position> data) async {
    final cache = await ref.read(localCacheProvider.future);
    await cache.set(_kPositionsKey, data.map(_toJson).toList(growable: false));
    ref.invalidate(positionsFreshnessProvider);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(positionRepositoryProvider);
      final result = await repo.list();
      return result.fold<Future<List<Position>>>(
        (Failure f) => throw Exception(f.message),
        (List<Position> ok) async {
          await _writeCache(ok);
          return ok;
        },
      );
    });
  }

  /// Log a BUY or SELL trade via the outbox. Position aggregates (avg cost,
  /// total shares, realized P/L) are recomputed server-side, so the local
  /// list refreshes after sync rather than trying to mirror the math here.
  Future<bool> logTrade(TradeInput input) async {
    final outbox = await ref.read(outboxProvider.future);
    await outbox.enqueue(OutboxOpType.logPurchase, {
      'symbol': input.symbol.toUpperCase(),
      'side': input.side.wire,
      'shares': input.shares,
      // Backwards-compat key for callers expecting 'pricePerShare'; sync
      // service prefers 'grossPricePerShare' when present.
      'pricePerShare': input.grossPricePerShare,
      'grossPricePerShare': input.grossPricePerShare,
      if (input.executedAt != null) 'purchasedAt': input.executedAt!.toUtc().toIso8601String(),
      if (input.executedAt != null) 'executedAt': input.executedAt!.toUtc().toIso8601String(),
      if (input.note != null) 'note': input.note,
    });
    ref.invalidate(outboxCountProvider);
    final online = await ref.read(connectivityServiceProvider).isOnline();
    if (online) {
      await ref.read(syncServiceProvider).flush();
    }
    return true;
  }

  /// Back-compat: existing callers that used addPurchase still work.
  Future<bool> addPurchase(PurchaseInput input) => logTrade(input);

  Future<bool> remove(String id) async {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncValue.data(current.where((p) => p.id != id).toList(growable: false));
      await _writeCache(state.value!);
    }
    // We don't outbox deletes for positions in v0.6 — deletes mostly happen
    // in-app and a stale row is acceptable until the next refresh.
    final repo = ref.read(positionRepositoryProvider);
    final result = await repo.remove(id);
    return result.fold((_) async {
      await refresh(); // restore on failure
      return false;
    }, (_) => true);
  }
}

Map<String, dynamic> _toJson(Position p) => {
      'id': p.id,
      'stockId': p.stockId,
      'symbol': p.symbol,
      'name': p.name,
      'totalShares': p.totalShares,
      'avgNetCost': p.avgNetCost,
      'realizedPnl': p.realizedPnl,
      'isOpen': p.isOpen,
      'latestClose': p.latestClose,
      'paperPlPct': p.paperPlPct,
    };
