import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Thin wrapper over `flutter_local_notifications`. The schedule logic
/// (i.e., what to fire and when) lives in `DailySignalReminder`; this
/// class is just permissions + delivery.
///
/// Platform setup required (write these once when `flutter create --platforms=android`
/// scaffolds the Android tree):
///   • `android/app/src/main/AndroidManifest.xml` —
///     <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
///     <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
///   • An app icon at `mipmap/ic_notification` (or change `_androidIcon`).
class NotificationService {
  NotificationService(this._plugin);
  final FlutterLocalNotificationsPlugin _plugin;

  static const _channelId = 'nepse_buy_signals';
  static const _channelName = 'Signal alerts';
  static const _channelDesc = 'Daily BUY / HARVEST signals from the on-device engine.';
  static const _androidIcon = '@mipmap/ic_launcher';

  bool _initialized = false;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    // Engine fires in NPT — set the local zone accordingly so scheduled
    // notifications respect Asia/Kathmandu when the device is elsewhere.
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kathmandu'));
    } catch (e) {
      // Database load failed (rare; bundled tzdata is bad) — degrade to
      // device tz. Surface to logs instead of silently swallowing so
      // missed-reminder reports are diagnosable.
      debugPrint('NotificationService: Asia/Kathmandu tz lookup failed — '
          'falling back to device tz: $e');
    }
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings(_androidIcon),
      ),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.high,
        ));
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await ensureInitialized();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? true;
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await ensureInitialized();
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          priority: Priority.high,
          importance: Importance.high,
        ),
      ),
      payload: payload,
    );
  }

  /// Schedules a one-shot at `when` (in the configured local tz). Re-call
  /// daily after each evaluation so we always have tomorrow's slot booked.
  Future<void> scheduleAt({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    String? payload,
  }) async {
    await ensureInitialized();
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          priority: Priority.high,
          importance: Importance.high,
        ),
      ),
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelAll() async {
    await ensureInitialized();
    await _plugin.cancelAll();
  }
}

final notificationServiceProvider = Provider<NotificationService>((_) {
  return NotificationService(FlutterLocalNotificationsPlugin());
});
