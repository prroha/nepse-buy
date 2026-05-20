import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/security/app_lock_controller.dart';

/// Full-screen lock overlay. Numeric PIN entry; biometric button when
/// enabled. Auto-prompts biometric on first show so a fingerprint resume
/// requires zero taps.
class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;
  bool _biometricPrompted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePromptBiometric());
  }

  Future<void> _maybePromptBiometric() async {
    if (_biometricPrompted) return;
    final state = ref.read(appLockControllerProvider);
    if (!state.biometricEnabled || !state.biometricAvailable) return;
    _biometricPrompted = true;
    await ref.read(appLockControllerProvider.notifier).tryUnlockWithBiometric();
  }

  Future<void> _submitPin() async {
    final pin = _controller.text;
    if (pin.length < 4) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await ref
        .read(appLockControllerProvider.notifier)
        .tryUnlockWithPin(pin);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _busy = false;
        _error = 'Wrong PIN. Try again.';
        _controller.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lock = ref.watch(appLockControllerProvider);
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline,
                      size: 56, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text('Enter PIN',
                      style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    enabled: !_busy,
                    maxLength: 8,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      counterText: '',
                      errorText: _error,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _submitPin(),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _busy ? null : _submitPin,
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Unlock'),
                  ),
                  if (lock.biometricEnabled && lock.biometricAvailable) ...[
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _busy
                          ? null
                          : () => ref
                              .read(appLockControllerProvider.notifier)
                              .tryUnlockWithBiometric(),
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Use biometric'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Wrap the router output in this gate to enforce the lock everywhere.
/// While [AppLockStatus.unknown] we show a tiny splash; on [locked] we
/// overlay the PIN screen; on [unlocked] or [disabled] we render [child].
class AppLockGate extends ConsumerWidget {
  const AppLockGate({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(appLockControllerProvider).status;
    switch (status) {
      case AppLockStatus.unknown:
        return const Scaffold(
            body: Center(child: CircularProgressIndicator()));
      case AppLockStatus.locked:
        return const AppLockScreen();
      case AppLockStatus.disabled:
      case AppLockStatus.unlocked:
        return child;
    }
  }
}
