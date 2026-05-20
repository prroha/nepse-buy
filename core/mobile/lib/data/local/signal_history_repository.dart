import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'app_database.dart';

/// Persists engine evaluations the user has actually looked at, so we can
/// answer: "what was suggested for CHDC last week and did I act on it?"
class SignalHistoryRepository {
  SignalHistoryRepository(this._db);
  final Database _db;

  /// Idempotent record — one row per `(symbol, signalDate)`. Re-evaluating
  /// the same day overwrites rationale + action so a fixed-up engine
  /// doesn't leave a stale entry behind.
  Future<void> record({
    required String symbol,
    required String signalDate, // YYYY-MM-DD
    required String action,
    required String season,
    double? suggestedLimit,
    required String rationale,
    required String engineVersion,
    double? closeAtSignal,
  }) async {
    final id = '$symbol:$signalDate';
    await _db.insert(
      'local_signal_history',
      {
        'id': id,
        'symbol': symbol,
        'signal_date': signalDate,
        'action': action,
        'season': season,
        'suggested_limit': suggestedLimit,
        'rationale': rationale,
        'engine_version': engineVersion,
        'close_at_signal': closeAtSignal,
        'taken': 0,
        'recorded_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> markTaken(String symbol, String signalDate) async {
    await _db.update(
      'local_signal_history',
      {'taken': 1},
      where: 'symbol = ? AND signal_date = ?',
      whereArgs: [symbol, signalDate],
    );
  }

  Future<List<Map<String, Object?>>> recent({int limit = 60}) =>
      _db.query('local_signal_history',
          orderBy: 'recorded_at DESC', limit: limit);

  Future<List<Map<String, Object?>>> forSymbol(String symbol, {int limit = 60}) =>
      _db.query('local_signal_history',
          where: 'symbol = ?',
          whereArgs: [symbol],
          orderBy: 'signal_date DESC',
          limit: limit);
}

final signalHistoryRepositoryProvider =
    FutureProvider<SignalHistoryRepository>((ref) async {
  final db = await ref.watch(appDatabaseProvider.future);
  return SignalHistoryRepository(db.raw);
});
