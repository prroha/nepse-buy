import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/local/user_data_repository.dart';
import 'backup_bundle.dart';

/// Writes the user's bundle to a temp file and hands it to the Android
/// share sheet — from there the user picks Drive / Files / email / etc.
/// Restore goes the other way: file_picker → JSON → repo.replaceAll.
///
/// Why this approach: no Google-Drive API key, no OAuth, works for any
/// "destination app" the user has installed.
class BackupService {
  BackupService(this._repo);
  final UserDataRepository _repo;

  /// Returns the path of the temp file that was shared, mostly for tests.
  Future<String> exportAndShare({String? subject}) async {
    final bundle = await BackupBundle.snapshot(_repo);
    final dir = await getTemporaryDirectory();
    final stamp = bundle.exportedAt
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final filename = 'nepse-buy-backup-$stamp.json';
    final file = File(p.join(dir.path, filename));
    await file.writeAsString(bundle.encode(), flush: true);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json', name: filename)],
      subject: subject ?? 'nepse-buy backup',
    );
    return file.path;
  }

  /// Opens the system file picker; returns null when the user cancels.
  /// Validates + applies the bundle atomically via `replaceAll`.
  /// Throws [BackupParseException] for malformed files.
  Future<RestoreOutcome?> pickAndRestore() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      // Fall back to reading the path — some Android paths give us no bytes.
      final path = file.path;
      if (path == null) {
        throw const BackupParseException('Could not read the selected file.');
      }
      final raw = await File(path).readAsString();
      return _applyRestore(raw);
    }
    final raw = String.fromCharCodes(bytes);
    return _applyRestore(raw);
  }

  Future<RestoreOutcome> _applyRestore(String raw) async {
    final bundle = BackupBundle.decode(raw);
    await _repo.replaceAll(
      watchlist: bundle.watchlist,
      trades: bundle.trades,
      debtAccounts: bundle.debtAccounts,
      feeSchedule: bundle.feeSchedule,
      settings: bundle.settings,
    );
    return RestoreOutcome(
      exportedAt: bundle.exportedAt,
      watchlistCount: bundle.watchlist.length,
      tradeCount: bundle.trades.length,
      debtAccountCount: bundle.debtAccounts.length,
      hadFeeSchedule: bundle.feeSchedule != null,
      settingsCount: bundle.settings.length,
    );
  }
}

class RestoreOutcome {
  RestoreOutcome({
    required this.exportedAt,
    required this.watchlistCount,
    required this.tradeCount,
    required this.debtAccountCount,
    required this.hadFeeSchedule,
    required this.settingsCount,
  });
  final DateTime exportedAt;
  final int watchlistCount;
  final int tradeCount;
  final int debtAccountCount;
  final bool hadFeeSchedule;
  final int settingsCount;

  String summary() => 'Restored from backup of '
      '${exportedAt.toLocal().toString().split(".").first} — '
      '$watchlistCount watchlist, $tradeCount trades, '
      '$debtAccountCount debt accounts'
      '${hadFeeSchedule ? ', fee schedule' : ''}'
      '${settingsCount > 0 ? ', $settingsCount settings' : ''}.';
}

final backupServiceProvider = FutureProvider<BackupService>((ref) async {
  final repo = await ref.watch(userDataRepositoryProvider.future);
  return BackupService(repo);
});
