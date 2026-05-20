import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/failures.dart';
import '../../core/services/connectivity_service.dart';
import '../../data/local/local_cache.dart';
import '../../data/local/outbox.dart';
import '../../data/repositories/watchlist_repository.dart';
import '../../data/sync/sync_service.dart';

const _kWatchlistKey = 'watchlist';

final watchlistProvider = AsyncNotifierProvider<WatchlistNotifier, List<WatchlistItem>>(
  WatchlistNotifier.new,
);

final watchlistFreshnessProvider = FutureProvider<DateTime?>((ref) async {
  final cache = await ref.watch(localCacheProvider.future);
  return cache.fetchedAt(_kWatchlistKey);
});

class WatchlistNotifier extends AsyncNotifier<List<WatchlistItem>> {
  @override
  Future<List<WatchlistItem>> build() async {
    final cache = await ref.read(localCacheProvider.future);
    final cached = await _readCache(cache);
    Future.microtask(_refreshFromRemote);
    return cached ?? [];
  }

  Future<List<WatchlistItem>?> _readCache(LocalCache cache) async {
    final raw = await cache.getJson(_kWatchlistKey);
    if (raw is! List) return null;
    return raw
        .whereType<Map<String, dynamic>>()
        .map(WatchlistItem.fromJson)
        .toList(growable: false);
  }

  Future<void> _refreshFromRemote() async {
    final repo = ref.read(watchlistRepositoryProvider);
    final result = await repo.list();
    await result.fold<Future<void>>(
      (_) async => null,
      (data) async {
        await _writeCache(data);
        state = AsyncValue.data(data);
      },
    );
  }

  Future<void> _writeCache(List<WatchlistItem> data) async {
    final cache = await ref.read(localCacheProvider.future);
    await cache.set(_kWatchlistKey, data.map(_toJson).toList(growable: false));
    ref.invalidate(watchlistFreshnessProvider);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(watchlistRepositoryProvider);
      final result = await repo.list();
      return result.fold<Future<List<WatchlistItem>>>(
        (Failure f) => throw Exception(f.message),
        (List<WatchlistItem> ok) async {
          await _writeCache(ok);
          return ok;
        },
      );
    });
  }

  /// Adds a symbol via the outbox so it works offline; UI updates immediately.
  /// The optimistic row is a stub (no stockId yet) — sync replaces it.
  Future<bool> add(String symbol) async {
    final outbox = await ref.read(outboxProvider.future);
    await outbox.enqueue(OutboxOpType.addWatchlist, {'symbol': symbol.toUpperCase()});
    ref.invalidate(outboxCountProvider);
    // Try to flush right away; otherwise the sync service picks it up later.
    final online = await ref.read(connectivityServiceProvider).isOnline();
    if (online) {
      await ref.read(syncServiceProvider).flush();
    }
    return true;
  }

  Future<bool> remove(String id) async {
    // Optimistic: pull from local cache + state right away.
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncValue.data(current.where((w) => w.id != id).toList(growable: false));
      await _writeCache(state.value!);
    }
    final outbox = await ref.read(outboxProvider.future);
    await outbox.enqueue(OutboxOpType.removeWatchlist, {'id': id});
    ref.invalidate(outboxCountProvider);
    final online = await ref.read(connectivityServiceProvider).isOnline();
    if (online) {
      await ref.read(syncServiceProvider).flush();
    }
    return true;
  }
}

Map<String, dynamic> _toJson(WatchlistItem w) => {
      'id': w.id,
      'rank': w.rank,
      'alertsEnabled': w.alertsEnabled,
      'stock': {
        'id': w.stock.id,
        'symbol': w.stock.symbol,
        'name': w.stock.name,
        'sector': w.stock.sector,
        'latestClose': w.stock.latestClose,
        'latestPriceDate': w.stock.latestPriceDate,
        'latestPe': w.stock.latestPe,
        'latestPb': w.stock.latestPb,
      },
      'latestSignal': w.latestSignal == null
          ? null
          : {
              'action': w.latestSignal!.action,
              'season': w.latestSignal!.season,
              'signalDate': w.latestSignal!.signalDate,
              'suggestedLimit': w.latestSignal!.suggestedLimit,
            },
    };
