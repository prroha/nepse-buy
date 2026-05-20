import 'package:flutter_test/flutter_test.dart';
import 'package:nepse_buy/core/security/app_lock_service.dart';

void main() {
  group('AppLockService.shouldLockOnResume', () {
    final svc = AppLockService();

    test('cold start (no lastPausedAt) always locks', () {
      expect(
        svc.shouldLockOnResume(
          lastPausedAt: null,
          now: DateTime.utc(2026, 5, 20, 12),
          idleSeconds: 60,
        ),
        isTrue,
      );
    });

    test('resume within idle window stays unlocked', () {
      final now = DateTime.utc(2026, 5, 20, 12, 0, 30);
      final paused = now.subtract(const Duration(seconds: 30));
      expect(
        svc.shouldLockOnResume(
          lastPausedAt: paused,
          now: now,
          idleSeconds: 60,
        ),
        isFalse,
      );
    });

    test('resume past idle window locks', () {
      final now = DateTime.utc(2026, 5, 20, 12, 5);
      final paused = now.subtract(const Duration(minutes: 5));
      expect(
        svc.shouldLockOnResume(
          lastPausedAt: paused,
          now: now,
          idleSeconds: 60,
        ),
        isTrue,
      );
    });

    test('idleSeconds = 0 means lock immediately', () {
      final now = DateTime.utc(2026, 5, 20, 12);
      expect(
        svc.shouldLockOnResume(
          lastPausedAt: now.subtract(const Duration(seconds: 1)),
          now: now,
          idleSeconds: 0,
        ),
        isTrue,
      );
    });
  });
}
