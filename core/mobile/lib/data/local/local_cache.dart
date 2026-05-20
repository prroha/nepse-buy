import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'app_database.dart';

/// Typed access to the `cached_responses` table. Values are JSON-serialized
/// `Object`s (typically `List<Map>` or `Map<String, dynamic>`). Returns null
/// when the key isn't present.
class LocalCache {
  LocalCache(this._db);
  final Database _db;

  Future<CacheEntry?> get(String key) async {
    final rows = await _db.query(
      'cached_responses',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    return CacheEntry(
      value: r['value'] as String,
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(r['fetched_at'] as int),
    );
  }

  Future<dynamic> getJson(String key) async {
    final e = await get(key);
    if (e == null) return null;
    return jsonDecode(e.value);
  }

  Future<DateTime?> fetchedAt(String key) async {
    final e = await get(key);
    return e?.fetchedAt;
  }

  Future<void> set(String key, Object? value) async {
    await _db.insert(
      'cached_responses',
      {
        'key': key,
        'value': jsonEncode(value),
        'fetched_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String key) async {
    await _db.delete('cached_responses', where: 'key = ?', whereArgs: [key]);
  }
}

class CacheEntry {
  final String value;
  final DateTime fetchedAt;
  const CacheEntry({required this.value, required this.fetchedAt});
}

final localCacheProvider = FutureProvider<LocalCache>((ref) async {
  final db = await ref.watch(appDatabaseProvider.future);
  return LocalCache(db.raw);
});
