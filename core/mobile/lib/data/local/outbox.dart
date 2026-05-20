import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'app_database.dart';

/// Ops queued by Phase-2 mutation methods when the device is offline or
/// when we want to apply optimistic updates instantly. Each op has a
/// stable `opType` discriminator that the SyncService dispatches on.
enum OutboxOpType {
  addWatchlist,
  removeWatchlist,
  logPurchase,
  createDebt,
  updateDebt,
  removeDebt,
}

extension OutboxOpTypeExt on OutboxOpType {
  String get wire => switch (this) {
        OutboxOpType.addWatchlist => 'add_watchlist',
        OutboxOpType.removeWatchlist => 'remove_watchlist',
        OutboxOpType.logPurchase => 'log_purchase',
        OutboxOpType.createDebt => 'create_debt',
        OutboxOpType.updateDebt => 'update_debt',
        OutboxOpType.removeDebt => 'remove_debt',
      };
}

OutboxOpType outboxOpTypeFromWire(String s) => switch (s) {
      'add_watchlist' => OutboxOpType.addWatchlist,
      'remove_watchlist' => OutboxOpType.removeWatchlist,
      'log_purchase' => OutboxOpType.logPurchase,
      'create_debt' => OutboxOpType.createDebt,
      'update_debt' => OutboxOpType.updateDebt,
      'remove_debt' => OutboxOpType.removeDebt,
      _ => throw ArgumentError('Unknown outbox op type: $s'),
    };

class OutboxEntry {
  final int id;
  final OutboxOpType type;
  final Map<String, dynamic> payload;
  final int retryCount;
  final String? lastError;
  final DateTime createdAt;
  final DateTime? lastAttemptedAt;

  const OutboxEntry({
    required this.id,
    required this.type,
    required this.payload,
    required this.retryCount,
    required this.lastError,
    required this.createdAt,
    required this.lastAttemptedAt,
  });
}

class Outbox {
  Outbox(this._db);
  final Database _db;

  Future<int> enqueue(OutboxOpType type, Map<String, dynamic> payload) async {
    return await _db.insert('pending_ops', {
      'op_type': type.wire,
      'payload': jsonEncode(payload),
      'retry_count': 0,
      'last_error': null,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'last_attempted_at': null,
    });
  }

  Future<List<OutboxEntry>> pending({int limit = 50}) async {
    final rows = await _db.query(
      'pending_ops',
      orderBy: 'created_at ASC',
      limit: limit,
    );
    return rows.map((r) => OutboxEntry(
          id: r['id'] as int,
          type: outboxOpTypeFromWire(r['op_type'] as String),
          payload: jsonDecode(r['payload'] as String) as Map<String, dynamic>,
          retryCount: r['retry_count'] as int,
          lastError: r['last_error'] as String?,
          createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
          lastAttemptedAt: r['last_attempted_at'] != null
              ? DateTime.fromMillisecondsSinceEpoch(r['last_attempted_at'] as int)
              : null,
        )).toList(growable: false);
  }

  Future<int> countPending() async {
    final res = await _db.rawQuery('SELECT COUNT(*) AS c FROM pending_ops');
    return (res.first['c'] as int?) ?? 0;
  }

  Future<void> remove(int id) async {
    await _db.delete('pending_ops', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> recordFailure(int id, String error) async {
    await _db.rawUpdate(
      'UPDATE pending_ops SET retry_count = retry_count + 1, last_error = ?, last_attempted_at = ? WHERE id = ?',
      [error, DateTime.now().millisecondsSinceEpoch, id],
    );
  }
}

final outboxProvider = FutureProvider<Outbox>((ref) async {
  final db = await ref.watch(appDatabaseProvider.future);
  return Outbox(db.raw);
});

/// Stream that emits the current pending count whenever it changes — used
/// by UI badges. Re-reads on every invalidation.
final outboxCountProvider = FutureProvider<int>((ref) async {
  final outbox = await ref.watch(outboxProvider.future);
  return outbox.countPending();
});
