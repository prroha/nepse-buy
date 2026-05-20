import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/connectivity_service.dart';
import '../local/outbox.dart';
import '../repositories/debt_repository.dart';
import '../repositories/position_repository.dart';
import '../repositories/watchlist_repository.dart';
import '../../presentation/providers/debt_provider.dart';
import '../../presentation/providers/position_provider.dart';
import '../../presentation/providers/watchlist_provider.dart';

/// Drains the outbox to the backend. Triggers on app start + connectivity
/// online events + explicit caller invocation (e.g., right after enqueue).
/// Each op type dispatches to the matching repository method; success removes
/// the row, failure increments retry_count and keeps it for next attempt.
class SyncService {
  SyncService(this._ref);
  final Ref _ref;

  bool _running = false;

  /// Single-flight: if a flush is already running, drop the call. Safe to
  /// invoke from multiple triggers (foreground, connectivity, post-enqueue).
  Future<void> flush() async {
    if (_running) return;
    _running = true;
    try {
      await _drain();
    } finally {
      _running = false;
    }
  }

  Future<void> _drain() async {
    final outbox = await _ref.read(outboxProvider.future);
    final batch = await outbox.pending();
    if (batch.isEmpty) return;

    bool anyTouched = false;
    for (final op in batch) {
      try {
        await _dispatch(op);
        await outbox.remove(op.id);
        anyTouched = true;
      } catch (e) {
        await outbox.recordFailure(op.id, e.toString());
        // Stop on first failure to avoid hammering an offline backend.
        break;
      }
    }
    if (anyTouched) {
      _ref.invalidate(outboxCountProvider);
    }
  }

  Future<void> _dispatch(OutboxEntry op) async {
    switch (op.type) {
      case OutboxOpType.addWatchlist:
        final r = await _ref.read(watchlistRepositoryProvider).add(op.payload['symbol'] as String);
        r.fold((f) => throw Exception(f.message), (_) {});
        _ref.invalidate(watchlistProvider);
        break;
      case OutboxOpType.removeWatchlist:
        final r = await _ref.read(watchlistRepositoryProvider).remove(op.payload['id'] as String);
        r.fold((f) => throw Exception(f.message), (_) {});
        _ref.invalidate(watchlistProvider);
        break;
      case OutboxOpType.logPurchase:
        // v0.7 — payload may include `side` and `grossPricePerShare`. Older
        // queued items (from v0.6) used `pricePerShare` and implied BUY.
        final sideStr = (op.payload['side'] as String?)?.toUpperCase() ?? 'BUY';
        final price = (op.payload['grossPricePerShare'] ?? op.payload['pricePerShare']) as String;
        final executedAtStr = (op.payload['executedAt'] ?? op.payload['purchasedAt']) as String?;
        final input = TradeInput(
          symbol: op.payload['symbol'] as String,
          side: sideStr == 'SELL' ? TradeSide.sell : TradeSide.buy,
          shares: op.payload['shares'] as int,
          grossPricePerShare: price,
          executedAt: executedAtStr != null ? DateTime.parse(executedAtStr) : null,
          note: op.payload['note'] as String?,
        );
        final r = await _ref.read(positionRepositoryProvider).logTrade(input);
        r.fold((f) => throw Exception(f.message), (_) {});
        _ref.invalidate(positionsProvider);
        break;
      case OutboxOpType.createDebt:
        final r = await _ref.read(debtRepositoryProvider).create(DebtAccountInput(
              name: op.payload['name'] as String,
              balance: op.payload['balance'] as String,
              interestRate: op.payload['interestRate'] as String,
            ));
        r.fold((f) => throw Exception(f.message), (_) {});
        _ref.invalidate(debtAccountsProvider);
        break;
      case OutboxOpType.updateDebt:
        final r = await _ref.read(debtRepositoryProvider).update(
              op.payload['id'] as String,
              DebtAccountPatch(
                name: op.payload['name'] as String?,
                balance: op.payload['balance'] as String?,
                interestRate: op.payload['interestRate'] as String?,
                isActive: op.payload['isActive'] as bool?,
              ),
            );
        r.fold((f) => throw Exception(f.message), (_) {});
        _ref.invalidate(debtAccountsProvider);
        break;
      case OutboxOpType.removeDebt:
        final r = await _ref.read(debtRepositoryProvider).remove(op.payload['id'] as String);
        r.fold((f) => throw Exception(f.message), (_) {});
        _ref.invalidate(debtAccountsProvider);
        break;
    }
  }
}

final syncServiceProvider = Provider<SyncService>((ref) => SyncService(ref));

/// Eager bootstrap that subscribes to connectivity changes and flushes the
/// outbox whenever the device comes online. Read once from `main.dart`
/// (e.g., via `ref.read(syncBootstrapProvider)`) to wire the listener.
final syncBootstrapProvider = Provider<void>((ref) {
  // Initial flush attempt — covers the "app launched while online" case.
  Future.microtask(() => ref.read(syncServiceProvider).flush());

  // React to connectivity transitions: only flush on offline → online edges.
  bool? prev;
  final sub = ref.listen<AsyncValue<bool>>(isOnlineProvider, (previous, next) {
    final now = next.valueOrNull;
    if (now == null) return;
    if (prev != true && now) {
      ref.read(syncServiceProvider).flush();
    }
    prev = now;
  });
  ref.onDispose(sub.close);
});
