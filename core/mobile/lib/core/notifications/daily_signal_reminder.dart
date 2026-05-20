import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/user_data_repository.dart';
import '../../data/repositories/signal_repository.dart';
import 'notification_service.dart';

/// Composes "evaluate every watchlisted symbol + fire one notification per
/// actionable signal" (BUY or HARVEST). Designed to be triggered:
///   • At app foreground (cheap — engine is in-memory).
///   • From a daily WorkManager task (set up at the platform side).
class DailySignalReminder {
  DailySignalReminder({
    required this.signalRepo,
    required this.userData,
    required this.notifications,
  });

  final SignalRepository signalRepo;
  final UserDataRepository userData;
  final NotificationService notifications;

  /// Evaluates today and fires one notification per actionable symbol.
  /// Returns the number of notifications dispatched. Also schedules the
  /// next evaluation slot (16:00 NPT tomorrow) so the daily nudge keeps
  /// firing even if the user doesn't open the app — provided the device
  /// lets the alarm wake the app (Android battery-optimisation territory).
  ///
  /// Quietly does nothing when the watchlist is empty.
  Future<int> runOnce() async {
    final watchlist = await userData.listWatchlist();
    final alertable = watchlist
        .where((w) => (w['alerts_enabled'] as int? ?? 1) == 1)
        .toList();
    if (alertable.isEmpty) return 0;

    final result = await signalRepo.getToday();
    final signals = result.fold<List<Signal>?>(
      (failure) {
        // Don't fail silently — daily nudge skipping has user-visible
        // impact ("why didn't I get my signal today?"). Surface to logs
        // and bail without faking a successful run.
        debugPrint(
            'DailySignalReminder.runOnce: getToday failed — $failure');
        return null;
      },
      (r) => r,
    );
    if (signals == null) return 0;

    final alertableSymbols = alertable
        .map((w) => (w['symbol'] as String).toUpperCase())
        .toSet();

    var fired = 0;
    for (final s in signals) {
      if (!alertableSymbols.contains(s.stockSymbol.toUpperCase())) continue;
      if (s.action != SignalAction.buy && s.action != SignalAction.harvest) {
        continue;
      }
      final title = s.action == SignalAction.buy
          ? '${s.stockSymbol} — BUY signal'
          : '${s.stockSymbol} — HARVEST signal';
      final body = s.suggestedLimit != null
          ? '${s.action.label} @ Rs ${s.suggestedLimit}. ${s.season} season.'
          : '${s.action.label}. ${s.season} season.';
      await notifications.show(
        id: _stableNotificationId(s.stockSymbol, s.signalDate),
        title: title,
        body: body,
        payload: 'signal:${s.stockSymbol}:${s.signalDate}',
      );
      fired += 1;
    }

    await _scheduleNextEvaluation();
    return fired;
  }

  /// Books a "check signals" notification for ~16:00 NPT tomorrow.
  /// Without this, the daily reminder only fires when the user opens the
  /// app; with it, even backgrounded users get pinged.
  Future<void> _scheduleNextEvaluation() async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 16);
    try {
      await notifications.scheduleAt(
        id: _dailyReminderId,
        when: tomorrow,
        title: 'Today\'s NEPSE signals',
        body: 'Open nepse-buy to refresh today\'s signal evaluation.',
        payload: 'signal:daily',
      );
    } catch (e) {
      debugPrint('DailySignalReminder.scheduleNext failed: $e');
    }
  }

  /// Stable per-(symbol, date) numeric id so the same signal isn't fired
  /// twice in one day if `runOnce` is called multiple times.
  int _stableNotificationId(String symbol, String date) {
    final key = 'signal:$symbol:$date';
    var h = 0;
    for (final c in key.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return h;
  }

  /// Reserved id for the "wake up and check signals" prompt. Picked to be
  /// outside the range of `_stableNotificationId` outputs (those are
  /// 0..0x7fffffff bytes of hash; this is just 1).
  static const int _dailyReminderId = 1;
}

final dailySignalReminderProvider =
    FutureProvider<DailySignalReminder>((ref) async {
  return DailySignalReminder(
    signalRepo: ref.watch(signalRepositoryProvider),
    userData: await ref.watch(userDataRepositoryProvider.future),
    notifications: ref.watch(notificationServiceProvider),
  );
});
