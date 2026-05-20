import 'dart:convert';

import '../../data/local/user_data_repository.dart';

/// Canonical shape of the JSON file the user shares to Drive / saves locally.
/// Schema is intentionally permissive — restore tolerates missing sections.
/// Bump [currentVersion] when the shape changes; older bundles can still
/// import if `_migrate` knows what to do with them.
class BackupBundle {
  BackupBundle({
    required this.version,
    required this.exportedAt,
    required this.watchlist,
    required this.trades,
    required this.debtAccounts,
    required this.feeSchedule,
    required this.settings,
    this.app = 'nepse-buy',
  });

  static const int currentVersion = 1;
  static const String _kindHeader = 'nepse-buy-user-data';

  final int version;
  final DateTime exportedAt;
  final String app;
  final List<Map<String, Object?>> watchlist;
  final List<Map<String, Object?>> trades;
  final List<Map<String, Object?>> debtAccounts;
  final Map<String, Object?>? feeSchedule;
  final Map<String, String> settings;

  Map<String, Object?> toJson() => {
        'kind': _kindHeader,
        'version': version,
        'app': app,
        'exportedAt': exportedAt.toUtc().toIso8601String(),
        'watchlist': watchlist,
        'trades': trades,
        'debtAccounts': debtAccounts,
        'feeSchedule': feeSchedule,
        'settings': settings,
      };

  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());

  /// Reads + validates a JSON string. Throws [BackupParseException] when the
  /// payload isn't recognisable as our bundle. Unknown sections are dropped
  /// so older app builds can still restore newer bundles best-effort.
  factory BackupBundle.decode(String raw) {
    final dynamic parsed;
    try {
      parsed = jsonDecode(raw);
    } catch (e) {
      throw const BackupParseException('Not valid JSON.');
    }
    if (parsed is! Map) {
      throw const BackupParseException('Expected a JSON object at the root.');
    }
    final json = parsed.cast<String, dynamic>();
    if (json['kind'] != _kindHeader) {
      throw BackupParseException(
        'Not a nepse-buy backup file (kind=${json['kind']}).',
      );
    }
    final version = (json['version'] as num?)?.toInt() ?? currentVersion;
    if (version > currentVersion) {
      throw BackupParseException(
        'Backup version $version is newer than this app supports ($currentVersion).',
      );
    }
    final exportedAt = json['exportedAt'] is String
        ? DateTime.tryParse(json['exportedAt'] as String) ?? DateTime.now()
        : DateTime.now();
    return BackupBundle(
      version: version,
      exportedAt: exportedAt,
      app: (json['app'] as String?) ?? 'nepse-buy',
      watchlist: _list(json['watchlist']),
      trades: _list(json['trades']),
      debtAccounts: _list(json['debtAccounts']),
      feeSchedule: json['feeSchedule'] is Map
          ? (json['feeSchedule'] as Map).cast<String, Object?>()
          : null,
      settings: json['settings'] is Map
          ? (json['settings'] as Map).map(
              (k, v) => MapEntry(k as String, v?.toString() ?? ''))
          : <String, String>{},
    );
  }

  static List<Map<String, Object?>> _list(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => m.cast<String, Object?>())
        .toList(growable: false);
  }

  /// Snapshot the current device state into a bundle, ready to share.
  static Future<BackupBundle> snapshot(UserDataRepository repo) async {
    final results = await Future.wait([
      repo.listWatchlist(),
      repo.listTrades(),
      repo.listDebtAccounts(),
      repo.getFeeSchedule(),
      repo.getAllSettings(),
    ]);
    return BackupBundle(
      version: currentVersion,
      exportedAt: DateTime.now(),
      watchlist: results[0] as List<Map<String, Object?>>,
      trades: results[1] as List<Map<String, Object?>>,
      debtAccounts: results[2] as List<Map<String, Object?>>,
      feeSchedule: results[3] as Map<String, Object?>?,
      settings: results[4] as Map<String, String>,
    );
  }
}

class BackupParseException implements Exception {
  const BackupParseException(this.message);
  final String message;
  @override
  String toString() => 'BackupParseException: $message';
}
