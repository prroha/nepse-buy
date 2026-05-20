import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/broker_inbox_repository.dart';
import '../../data/local/user_data_repository.dart';
import 'broker_sms_parser.dart';

/// SMS auto-scanning is disabled in v0.10.1: the READ_SMS permission
/// triggers Google Play Protect warnings on sideload (and the Play Store
/// outright disallows it for apps that aren't a default-SMS handler).
///
/// The parser + inbox table are intact — a future iteration could surface
/// a "paste broker SMS here" text field on the inbox screen and route the
/// parsed result through `BrokerInboxRepository.upsertIncoming` directly,
/// which doesn't need any platform permission.
///
/// `scan()` throws [SmsScanningDisabled] so the UI can show a clear
/// explanation and the call site doesn't have to special-case the build
/// configuration.
class SmsScannerService {
  SmsScannerService({
    required this.parser,
    required this.inbox,
    required this.userData,
  });

  final BrokerSmsParser parser;
  final BrokerInboxRepository inbox;
  final UserDataRepository userData;

  /// Always false in this build. Kept as a getter so the broker-inbox UI
  /// can decide whether to render the "Sync SMS" button at all.
  bool get isAvailable => false;

  Future<bool> ensurePermission() async => false;

  Future<int> scan({bool sinceLastRun = true}) async {
    throw const SmsScanningDisabled();
  }
}

/// Thrown when the caller asks for an SMS scan in a build that doesn't
/// ship the platform plumbing. The broker-inbox screen catches this and
/// renders the explanatory copy.
class SmsScanningDisabled implements Exception {
  const SmsScanningDisabled();
  @override
  String toString() =>
      'SMS auto-scan is disabled in this build. Trades can still be '
      'logged manually from Portfolio → Log purchase.';
}

/// Kept for source-compat with code that catches the old exception name.
class SmsPermissionDenied extends SmsScanningDisabled {
  const SmsPermissionDenied();
}

final smsScannerServiceProvider =
    FutureProvider<SmsScannerService>((ref) async {
  return SmsScannerService(
    parser: BrokerSmsParser(),
    inbox: await ref.watch(brokerInboxRepositoryProvider.future),
    userData: await ref.watch(userDataRepositoryProvider.future),
  );
});
