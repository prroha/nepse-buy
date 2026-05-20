import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_lock_service.dart';

enum AppLockStatus {
  /// Lock state hasn't been resolved yet — show a splash, not the lock screen.
  unknown,

  /// No PIN configured — app is fully open.
  disabled,

  /// PIN configured, current session has not unlocked.
  locked,

  /// PIN configured, user has authenticated this session.
  unlocked,
}

class AppLockState {
  AppLockState({
    required this.status,
    this.idleSeconds = AppLockService.defaultIdleSeconds,
    this.biometricEnabled = false,
    this.biometricAvailable = false,
    this.lastPausedAt,
  });

  final AppLockStatus status;
  final int idleSeconds;
  final bool biometricEnabled;
  final bool biometricAvailable;
  final DateTime? lastPausedAt;

  AppLockState copyWith({
    AppLockStatus? status,
    int? idleSeconds,
    bool? biometricEnabled,
    bool? biometricAvailable,
    DateTime? lastPausedAt,
    bool clearLastPaused = false,
  }) =>
      AppLockState(
        status: status ?? this.status,
        idleSeconds: idleSeconds ?? this.idleSeconds,
        biometricEnabled: biometricEnabled ?? this.biometricEnabled,
        biometricAvailable: biometricAvailable ?? this.biometricAvailable,
        lastPausedAt: clearLastPaused
            ? null
            : (lastPausedAt ?? this.lastPausedAt),
      );
}

/// Owns lock state for the whole app. Hooks the widget lifecycle so we can
/// stamp `lastPausedAt` on backgrounding and re-evaluate on resume.
class AppLockController extends StateNotifier<AppLockState>
    with WidgetsBindingObserver {
  AppLockController(this._svc)
      : super(AppLockState(status: AppLockStatus.unknown)) {
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  final AppLockService _svc;

  Future<void> _bootstrap() async {
    final enabled = await _svc.isEnabled();
    final idle = await _svc.getIdleSeconds();
    final bioAvailable = await _svc.isBiometricAvailable();
    final bioEnabled = await _svc.isBiometricEnabled();
    state = state.copyWith(
      status: enabled ? AppLockStatus.locked : AppLockStatus.disabled,
      idleSeconds: idle,
      biometricEnabled: bioEnabled,
      biometricAvailable: bioAvailable,
    );
  }

  @override
  // ignore: avoid_renaming_method_parameters
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    switch (lifecycle) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        state = state.copyWith(lastPausedAt: DateTime.now());
        break;
      case AppLifecycleState.resumed:
        _maybeRelockOnResume();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  void _maybeRelockOnResume() {
    if (state.status == AppLockStatus.disabled) return;
    final shouldLock = _svc.shouldLockOnResume(
      lastPausedAt: state.lastPausedAt,
      now: DateTime.now(),
      idleSeconds: state.idleSeconds,
    );
    if (shouldLock && state.status == AppLockStatus.unlocked) {
      state = state.copyWith(status: AppLockStatus.locked);
    }
  }

  Future<bool> tryUnlockWithPin(String pin) async {
    final ok = await _svc.verifyPin(pin);
    if (ok) {
      state = state.copyWith(
        status: AppLockStatus.unlocked,
        clearLastPaused: true,
      );
    }
    return ok;
  }

  Future<bool> tryUnlockWithBiometric() async {
    if (!state.biometricEnabled || !state.biometricAvailable) return false;
    final ok = await _svc.authenticateWithBiometric();
    if (ok) {
      state = state.copyWith(
        status: AppLockStatus.unlocked,
        clearLastPaused: true,
      );
    }
    return ok;
  }

  Future<void> setPin(String pin) async {
    await _svc.setPin(pin);
    state = state.copyWith(status: AppLockStatus.unlocked);
  }

  /// Disable the lock. Caller is responsible for verifying the current PIN
  /// before invoking — exposed for the Security screen.
  Future<void> disable() async {
    await _svc.disable();
    state = state.copyWith(
      status: AppLockStatus.disabled,
      biometricEnabled: false,
    );
  }

  Future<void> setIdleSeconds(int seconds) async {
    await _svc.setIdleSeconds(seconds);
    state = state.copyWith(idleSeconds: seconds);
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _svc.setBiometricEnabled(enabled);
    state = state.copyWith(biometricEnabled: enabled);
  }

  /// Force-lock — used by Settings → "Lock now".
  void lockNow() {
    if (state.status == AppLockStatus.disabled) return;
    state = state.copyWith(status: AppLockStatus.locked);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

final appLockControllerProvider =
    StateNotifierProvider<AppLockController, AppLockState>(
  (ref) => AppLockController(ref.watch(appLockServiceProvider)),
);
