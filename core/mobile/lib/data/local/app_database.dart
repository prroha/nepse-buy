import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Tiny local store: one KV cache table for read responses and one queue
/// for write ops that haven't reached the backend yet. Schema kept narrow
/// on purpose — every domain entity is just a JSON blob keyed by a
/// well-known string (e.g., "signals/today", "watchlist", "portfolio").
///
/// Migrations: bump [_schemaVersion] and add a case to [_onUpgrade]. The
/// `cached_responses` and `pending_ops` tables are the only persistent state.
class AppDatabase {
  AppDatabase._(this._db);

  final Database _db;
  Database get raw => _db;

  static const _filename = 'nepse_buy.db';
  // v4 (2026-05): pending_broker_messages gets trade_index + bill_amount so
  // a single SMS can fan out into N inbox rows.
  static const _schemaVersion = 4;

  static Future<AppDatabase> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _filename);
    final db = await openDatabase(
      path,
      version: _schemaVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return AppDatabase._(db);
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cached_responses (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        fetched_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE pending_ops (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        op_type TEXT NOT NULL,
        payload TEXT NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        created_at INTEGER NOT NULL,
        last_attempted_at INTEGER
      )
    ''');
    await db.execute('CREATE INDEX idx_pending_ops_created ON pending_ops(created_at)');
    await _createUserDataTables(db);
    await _createV3Tables(db);
    await _migrateV4(db);
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createUserDataTables(db);
    }
    if (oldVersion < 3) {
      await _createV3Tables(db);
    }
    if (oldVersion < 4) {
      await _migrateV4(db);
    }
  }

  static Future<void> _migrateV4(Database db) async {
    // Drop the v3 dedupe index — we want one row per (sender, body,
    // received_at, trade_index) now.
    await db.execute(
        'DROP INDEX IF EXISTS idx_pending_messages_status');
    await db.execute(
        'ALTER TABLE pending_broker_messages ADD COLUMN trade_index INTEGER NOT NULL DEFAULT 0');
    await db.execute(
        'ALTER TABLE pending_broker_messages ADD COLUMN bill_amount REAL');
    await db.execute(
        'CREATE INDEX idx_pending_messages_status ON pending_broker_messages(status, received_at)');
  }

  static Future<void> _createV3Tables(Database db) async {
    await db.execute('''
      CREATE TABLE local_signal_history (
        id TEXT PRIMARY KEY,
        symbol TEXT NOT NULL,
        signal_date TEXT NOT NULL,
        action TEXT NOT NULL,
        season TEXT NOT NULL,
        suggested_limit REAL,
        rationale TEXT NOT NULL,
        engine_version TEXT NOT NULL,
        close_at_signal REAL,
        taken INTEGER NOT NULL DEFAULT 0,
        recorded_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
        'CREATE UNIQUE INDEX idx_signal_history_unique ON local_signal_history(symbol, signal_date)');
    await db.execute(
        'CREATE INDEX idx_signal_history_recorded ON local_signal_history(recorded_at)');

    // Strict v3 shape — DO NOT add columns here. Column additions for v4+
    // belong in `_migrateV4` so a v2 → v4 upgrade can't try to add the
    // same column twice (which sqflite reports as `duplicate column`).
    await db.execute('''
      CREATE TABLE pending_broker_messages (
        id TEXT PRIMARY KEY,
        sender TEXT NOT NULL,
        body TEXT NOT NULL,
        received_at INTEGER NOT NULL,
        parsed_symbol TEXT,
        parsed_side TEXT,
        parsed_shares INTEGER,
        parsed_gross_price REAL,
        parsed_executed_at INTEGER,
        status TEXT NOT NULL DEFAULT 'PENDING',
        applied_trade_id TEXT,
        notes TEXT,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_pending_messages_status ON pending_broker_messages(status, received_at)');
  }

  static Future<void> _createUserDataTables(Database db) async {
    await db.execute('''
      CREATE TABLE user_watchlist (
        symbol TEXT PRIMARY KEY,
        added_at INTEGER NOT NULL,
        alerts_enabled INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE user_trades (
        id TEXT PRIMARY KEY,
        symbol TEXT NOT NULL,
        side TEXT NOT NULL,
        shares INTEGER NOT NULL,
        gross_price_per_share REAL NOT NULL,
        executed_at INTEGER NOT NULL,
        notes TEXT,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_user_trades_symbol_executed ON user_trades(symbol, executed_at)');
    await db.execute('''
      CREATE TABLE user_debt_accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        outstanding_balance REAL NOT NULL,
        annual_rate_pct REAL NOT NULL,
        monthly_surplus REAL NOT NULL DEFAULT 100000,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE user_fee_schedule (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        data TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE user_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }
}

/// Riverpod provider for the database. Resolved once during app startup.
final appDatabaseProvider = FutureProvider<AppDatabase>((ref) async {
  final db = await AppDatabase.open();
  ref.onDispose(() => db.raw.close());
  return db;
});
