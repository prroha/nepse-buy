import 'package:another_telephony/telephony.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/local/broker_inbox_repository.dart';
import '../../data/local/user_data_repository.dart';
import 'broker_sms_parser.dart';

/// Pulls SMS from the Android inbox, runs each through the parser, and
/// drops any plausibly-trade-related message into `pending_broker_messages`
/// for the user to approve in the queue UI.
///
/// READ_SMS is a sensitive Android permission. We ask for it explicitly,
/// only scan on demand (no background listener), and never send the body
/// off the device.
class SmsScannerService {
  SmsScannerService({
    required this.parser,
    required this.inbox,
    required this.userData,
    Telephony? telephony,
  }) : _telephony = telephony ?? Telephony.instance;

  final BrokerSmsParser parser;
  final BrokerInboxRepository inbox;
  final UserDataRepository userData;
  final Telephony _telephony;

  static const _lastScanKey = 'sms_scanner.last_scan_at';

  Future<bool> ensurePermission() async {
    final granted = await _telephony.requestSmsPermissions ?? false;
    if (granted) return true;
    // Fallback via permission_handler — covers the "permanently denied"
    // path so we can deep-link the user to settings.
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  /// Scans every inbox message newer than the last successful run and
  /// queues anything that looks like a buy/sell confirmation.
  /// Returns the number of new pending rows created.
  Future<int> scan({bool sinceLastRun = true}) async {
    final granted = await ensurePermission();
    if (!granted) {
      throw const SmsPermissionDenied();
    }

    final settings = await userData.getAllSettings();
    final since = sinceLastRun
        ? int.tryParse(settings[_lastScanKey] ?? '0') ?? 0
        : 0;

    final filter = SmsFilter.where(SmsColumn.DATE).greaterThan(since.toString());
    final messages = await _telephony.getInboxSms(
      columns: const [
        SmsColumn.ADDRESS,
        SmsColumn.BODY,
        SmsColumn.DATE,
      ],
      filter: filter,
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
    );

    var queued = 0;
    var maxSeen = since;
    for (final m in messages) {
      final body = m.body ?? '';
      final sender = m.address ?? 'UNKNOWN';
      final receivedMs = m.date ?? DateTime.now().millisecondsSinceEpoch;
      if (receivedMs > maxSeen) maxSeen = receivedMs;
      if (body.isEmpty) continue;

      queued += await _ingestOneSms(
        sender: sender,
        body: body,
        receivedMs: receivedMs,
      );
    }

    await userData.setSetting(_lastScanKey, maxSeen.toString());
    return queued;
  }

  /// Parses one SMS and fans the result into the inbox — one row per
  /// trade tuple so the user can approve/dismiss legs of a multi-stock
  /// SELL independently. Returns the number of new rows inserted (0 if
  /// the SMS didn't look like a trade or every row deduped).
  Future<int> _ingestOneSms({
    required String sender,
    required String body,
    required int receivedMs,
  }) async {
    final parsed = parser.tryParse(body);
    if (parsed == null || !parsed.hasMinimumFields) return 0;

    final receivedAt = DateTime.fromMillisecondsSinceEpoch(receivedMs);
    final legSuffix =
        parsed.trades.length > 1 ? ', leg %i/${parsed.trades.length}' : '';
    var inserted = 0;
    for (var i = 0; i < parsed.trades.length; i++) {
      final t = parsed.trades[i];
      final id = await inbox.upsertIncoming(
        sender: sender,
        body: body,
        receivedAt: receivedAt,
        tradeIndex: i,
        parsedSymbol: t.symbol,
        parsedSide: parsed.side?.name.toUpperCase(),
        parsedShares: t.shares,
        parsedGrossPrice: t.grossPricePerShare,
        parsedExecutedAt: parsed.executedAt,
        // Bill amount is gross + fees totalled across the whole SMS;
        // attach only to the first row to avoid double-counting in the
        // approval cross-check.
        billAmount: i == 0 ? parsed.billAmount : null,
        notes: 'confidence=${parsed.confidence}'
            '${legSuffix.replaceAll('%i', '${i + 1}')}',
      );
      if (id != null) inserted += 1;
    }
    return inserted;
  }
}

class SmsPermissionDenied implements Exception {
  const SmsPermissionDenied();
  @override
  String toString() =>
      'SMS permission is required to read broker confirmations.';
}

final smsScannerServiceProvider =
    FutureProvider<SmsScannerService>((ref) async {
  return SmsScannerService(
    parser: BrokerSmsParser(),
    inbox: await ref.watch(brokerInboxRepositoryProvider.future),
    userData: await ref.watch(userDataRepositoryProvider.future),
  );
});
