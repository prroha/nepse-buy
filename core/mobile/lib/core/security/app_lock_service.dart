import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import 'pin_hasher.dart';

/// Local-only app lock. PIN is hashed and kept in flutter_secure_storage
/// (KeyStore-backed on Android); biometric is a convenience layer on top.
/// Whether the user must enter the PIN is decided by [shouldLockOnResume]
/// using the idle-timeout setting + last-active timestamp.
class AppLockService {
  AppLockService({
    FlutterSecureStorage? storage,
    LocalAuthentication? localAuth,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _localAuth = localAuth ?? LocalAuthentication();

  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuth;

  static const _kPinHash = 'app_lock.pin_hash';
  static const _kPinSalt = 'app_lock.pin_salt';
  static const _kBiometricEnabled = 'app_lock.biometric_enabled';
  static const _kIdleSeconds = 'app_lock.idle_seconds';
  // Default: lock on resume only when the app has been backgrounded ≥60s.
  static const int defaultIdleSeconds = 60;

  Future<bool> isEnabled() async =>
      (await _storage.read(key: _kPinHash)) != null;

  Future<void> setPin(String pin) async {
    _validatePin(pin);
    final salt = PinHasher.generateSalt();
    final hash = PinHasher.hash(pin, salt);
    await _storage.write(key: _kPinSalt, value: salt);
    await _storage.write(key: _kPinHash, value: hash);
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: _kPinHash);
    final salt = await _storage.read(key: _kPinSalt);
    if (stored == null || salt == null) return false;
    final candidate = PinHasher.hash(pin, salt);
    return PinHasher.constantTimeEquals(candidate, stored);
  }

  /// Changes the PIN only if [currentPin] verifies. Returns false on bad PIN.
  Future<bool> changePin(String currentPin, String newPin) async {
    if (!await verifyPin(currentPin)) return false;
    await setPin(newPin);
    return true;
  }

  /// Disables the lock entirely. Caller must have verified the PIN first.
  Future<void> disable() async {
    await _storage.delete(key: _kPinHash);
    await _storage.delete(key: _kPinSalt);
    await _storage.delete(key: _kBiometricEnabled);
  }

  // ─────────────── biometric ───────────────

  Future<bool> isBiometricAvailable() async {
    final canCheck = await _localAuth.canCheckBiometrics;
    final supported = await _localAuth.isDeviceSupported();
    if (!canCheck || !supported) return false;
    final available = await _localAuth.getAvailableBiometrics();
    return available.isNotEmpty;
  }

  Future<bool> isBiometricEnabled() async {
    final v = await _storage.read(key: _kBiometricEnabled);
    return v == '1';
  }

  Future<void> setBiometricEnabled(bool enabled) =>
      _storage.write(key: _kBiometricEnabled, value: enabled ? '1' : '0');

  /// Prompts the OS biometric sheet. Returns true only on a confirmed match.
  Future<bool> authenticateWithBiometric({
    String reason = 'Unlock nepse-buy',
  }) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (_) {
      // Hardware unavailable / cancelled / lockout — treat as failure.
      return false;
    }
  }

  // ─────────────── idle policy ───────────────

  Future<int> getIdleSeconds() async {
    final raw = await _storage.read(key: _kIdleSeconds);
    final parsed = raw == null ? null : int.tryParse(raw);
    return parsed ?? defaultIdleSeconds;
  }

  Future<void> setIdleSeconds(int seconds) async {
    if (seconds < 0) throw ArgumentError('idleSeconds must be ≥ 0');
    await _storage.write(key: _kIdleSeconds, value: seconds.toString());
  }

  /// Pure helper exposed for testing — given when the app last paused and
  /// the current time, decide whether the user must re-authenticate.
  bool shouldLockOnResume({
    required DateTime? lastPausedAt,
    required DateTime now,
    required int idleSeconds,
  }) {
    if (lastPausedAt == null) return true; // cold start
    final elapsed = now.difference(lastPausedAt).inSeconds;
    return elapsed >= idleSeconds;
  }

  // ─────────────── validation ───────────────

  static void _validatePin(String pin) {
    if (pin.length < 4 || pin.length > 8) {
      throw ArgumentError('PIN must be 4–8 digits');
    }
    if (!RegExp(r'^\d+$').hasMatch(pin)) {
      throw ArgumentError('PIN must be digits only');
    }
  }
}

final appLockServiceProvider =
    Provider<AppLockService>((_) => AppLockService());
