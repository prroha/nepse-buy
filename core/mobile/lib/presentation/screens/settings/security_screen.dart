import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/security/app_lock_controller.dart';

/// "Settings → Security". Toggle lock on/off, change PIN, biometric toggle,
/// idle timeout. Personal-use feature — no analytics, no remote telemetry.
class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  static const _idleChoices = [0, 30, 60, 300, 900]; // seconds

  @override
  Widget build(BuildContext context) {
    final lock = ref.watch(appLockControllerProvider);
    final enabled = lock.status != AppLockStatus.disabled;

    return Scaffold(
      appBar: AppBar(title: const Text('Security')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('App lock'),
            subtitle: Text(enabled
                ? 'PIN required to open the app.'
                : 'Anyone with this phone can open the app.'),
            value: enabled,
            onChanged: (v) => _toggleLock(v),
          ),
          if (enabled) ...[
            ListTile(
              title: const Text('Change PIN'),
              leading: const Icon(Icons.pin),
              onTap: _changePin,
            ),
            SwitchListTile(
              title: const Text('Biometric unlock'),
              subtitle: Text(
                lock.biometricAvailable
                    ? 'Use fingerprint / face in place of the PIN.'
                    : 'This device doesn\'t expose a biometric.',
              ),
              value: lock.biometricEnabled,
              onChanged: lock.biometricAvailable
                  ? (v) => ref
                      .read(appLockControllerProvider.notifier)
                      .setBiometricEnabled(v)
                  : null,
            ),
            ListTile(
              title: const Text('Auto-lock'),
              subtitle: Text(_idleLabel(lock.idleSeconds)),
              leading: const Icon(Icons.timer_outlined),
              onTap: _pickIdle,
            ),
            ListTile(
              title: const Text('Lock now'),
              leading: const Icon(Icons.lock_clock),
              onTap: () => ref
                  .read(appLockControllerProvider.notifier)
                  .lockNow(),
            ),
          ],
        ],
      ),
    );
  }

  String _idleLabel(int seconds) {
    if (seconds == 0) return 'Lock immediately on background';
    if (seconds < 60) return 'After ${seconds}s in background';
    final mins = seconds ~/ 60;
    return 'After ${mins}m in background';
  }

  Future<void> _toggleLock(bool enable) async {
    if (enable) {
      await _setupPinFlow();
    } else {
      final ok = await _confirmWithPin(
          'Enter your PIN to disable the app lock.');
      if (ok) {
        await ref.read(appLockControllerProvider.notifier).disable();
      }
    }
  }

  Future<void> _setupPinFlow() async {
    final pin1 = await _pinDialog(title: 'Choose a 4–8 digit PIN');
    if (pin1 == null) return;
    final pin2 = await _pinDialog(title: 'Re-enter PIN to confirm');
    if (pin2 == null) return;
    if (pin1 != pin2) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PINs don\'t match. Try again.')),
      );
      return;
    }
    try {
      await ref.read(appLockControllerProvider.notifier).setPin(pin1);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('App lock enabled.')),
      );
    } on ArgumentError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message.toString())),
      );
    }
  }

  Future<void> _changePin() async {
    final ok = await _confirmWithPin('Enter your current PIN.');
    if (!ok) return;
    await _setupPinFlow();
  }

  Future<bool> _confirmWithPin(String prompt) async {
    final pin = await _pinDialog(title: prompt);
    if (pin == null) return false;
    final svc = ref.read(appLockControllerProvider.notifier);
    final verified = await svc.tryUnlockWithPin(pin);
    if (!verified && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wrong PIN.')),
      );
    }
    return verified;
  }

  Future<String?> _pinDialog({required String title}) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 8,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            counterText: '',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(ctrl.text),
              child: const Text('OK')),
        ],
      ),
    );
    if (result == null || result.isEmpty) return null;
    return result;
  }

  Future<void> _pickIdle() async {
    final current = ref.read(appLockControllerProvider).idleSeconds;
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Lock after…'),
        children: [
          for (final s in _idleChoices)
            ListTile(
              leading: Icon(s == current
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked),
              title: Text(_idleLabel(s)),
              onTap: () => Navigator.of(ctx).pop(s),
            ),
        ],
      ),
    );
    if (picked != null) {
      await ref
          .read(appLockControllerProvider.notifier)
          .setIdleSeconds(picked);
    }
  }
}
