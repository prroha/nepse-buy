import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'app_database.dart';

/// CRUD over the device-local user-personal tables introduced in schema v2.
/// Domain shapes are plain `Map<String, Object?>` to keep this layer cheap
/// to extend — the backup/restore service round-trips them as JSON without
/// schema coupling.
class UserDataRepository {
  UserDataRepository(this._db);
  final Database _db;

  // ─────────────── watchlist ───────────────

  Future<List<Map<String, Object?>>> listWatchlist() =>
      _db.query('user_watchlist', orderBy: 'added_at ASC');

  Future<void> addWatchlist(String symbol, {bool alertsEnabled = true}) async {
    await _db.insert(
      'user_watchlist',
      {
        'symbol': symbol.toUpperCase(),
        'added_at': DateTime.now().millisecondsSinceEpoch,
        'alerts_enabled': alertsEnabled ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> removeWatchlist(String symbol) =>
      _db.delete('user_watchlist',
          where: 'symbol = ?', whereArgs: [symbol.toUpperCase()]);

  // ─────────────── trades ───────────────

  Future<List<Map<String, Object?>>> listTrades({String? symbol}) {
    if (symbol != null) {
      return _db.query(
        'user_trades',
        where: 'symbol = ?',
        whereArgs: [symbol.toUpperCase()],
        orderBy: 'executed_at ASC',
      );
    }
    return _db.query('user_trades', orderBy: 'executed_at ASC');
  }

  Future<void> upsertTrade(Map<String, Object?> trade) async {
    await _db.insert('user_trades', trade,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteTrade(String id) =>
      _db.delete('user_trades', where: 'id = ?', whereArgs: [id]);

  // ─────────────── debt ───────────────

  Future<List<Map<String, Object?>>> listDebtAccounts({bool activeOnly = false}) {
    if (activeOnly) {
      return _db.query('user_debt_accounts',
          where: 'is_active = 1', orderBy: 'created_at ASC');
    }
    return _db.query('user_debt_accounts', orderBy: 'created_at ASC');
  }

  Future<void> upsertDebtAccount(Map<String, Object?> acc) async {
    await _db.insert('user_debt_accounts', acc,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteDebtAccount(String id) =>
      _db.delete('user_debt_accounts', where: 'id = ?', whereArgs: [id]);

  // ─────────────── fee schedule (singleton) ───────────────

  Future<Map<String, Object?>?> getFeeSchedule() async {
    final rows = await _db.query('user_fee_schedule',
        where: 'id = 1', limit: 1);
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['data'] as String) as Map<String, Object?>;
  }

  Future<void> saveFeeSchedule(Map<String, Object?> schedule) async {
    await _db.insert(
      'user_fee_schedule',
      {
        'id': 1,
        'data': jsonEncode(schedule),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─────────────── settings (KV) ───────────────

  Future<Map<String, String>> getAllSettings() async {
    final rows = await _db.query('user_settings');
    return {for (final r in rows) r['key'] as String: r['value'] as String};
  }

  Future<void> setSetting(String key, String value) async {
    await _db.insert(
      'user_settings',
      {
        'key': key,
        'value': value,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─────────────── bulk for restore ───────────────

  /// Wipe + replace every user-personal table. Wrapped in a single
  /// transaction so a half-finished restore doesn't leave the device in a
  /// torn state.
  Future<void> replaceAll({
    required List<Map<String, Object?>> watchlist,
    required List<Map<String, Object?>> trades,
    required List<Map<String, Object?>> debtAccounts,
    required Map<String, Object?>? feeSchedule,
    required Map<String, String> settings,
  }) async {
    await _db.transaction((txn) async {
      await txn.delete('user_watchlist');
      await txn.delete('user_trades');
      await txn.delete('user_debt_accounts');
      await txn.delete('user_fee_schedule');
      await txn.delete('user_settings');

      final now = DateTime.now().millisecondsSinceEpoch;
      for (final row in watchlist) {
        await txn.insert('user_watchlist', row,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final row in trades) {
        await txn.insert('user_trades', row,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final row in debtAccounts) {
        await txn.insert('user_debt_accounts', row,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      if (feeSchedule != null) {
        await txn.insert(
          'user_fee_schedule',
          {'id': 1, 'data': jsonEncode(feeSchedule), 'updated_at': now},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final entry in settings.entries) {
        await txn.insert(
          'user_settings',
          {'key': entry.key, 'value': entry.value, 'updated_at': now},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}

final userDataRepositoryProvider =
    FutureProvider<UserDataRepository>((ref) async {
  final db = await ref.watch(appDatabaseProvider.future);
  return UserDataRepository(db.raw);
});
