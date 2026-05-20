import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../router/routes.dart';
import '../../widgets/layout/auth_scaffold.dart';
import '../../widgets/layout/status_screen.dart';
import '../../widgets/molecules/app_snackbar.dart';

/// Email verification screen that verifies a token from deep link
class VerifyEmailScreen extends ConsumerStatefulWidget {
  final String? token;

  const VerifyEmailScreen({
    super.key,
    this.token,
  });

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _isVerifying = true;
  bool _isSuccess = false;
  String? _error;
  String? _verifiedEmail;

  @override
  void initState() {
    super.initState();
    _verifyEmail();
  }

  Future<void> _verifyEmail() async {
    if (widget.token == null || widget.token!.isEmpty) {
      setState(() {
        _isVerifying = false;
        _error = 'No verification token provided';
      });
      return;
    }

    final authRepository = ref.read(authRepositoryProvider);
    final result = await authRepository.verifyEmail(widget.token!);

    result.fold(
      (failure) {
        setState(() {
          _isVerifying = false;
          _error = failure.message;
        });
      },
      (response) {
        setState(() {
          _isVerifying = false;
          _isSuccess = response.verified;
          _verifiedEmail = response.email;
        });

        if (response.verified && mounted) {
          AppSnackbar.success(
            context,
            'Email verified!',
            description: 'Your email has been verified successfully.',
          );

          // Navigate to home after a delay
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              context.go(Routes.home);
            }
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isVerifying) {
      return const StatusScreen.loading(
        title: 'Verifying your email...',
        message: 'Please wait while we verify your email address.',
      );
    }

    if (_isSuccess) {
      return StatusScreen.success(
        title: 'Email verified!',
        message: _verifiedEmail != null
            ? 'Your email $_verifiedEmail has been verified successfully.\n\nRedirecting you to the dashboard...'
            : 'Your email has been verified successfully.\n\nRedirecting you to the dashboard...',
        secondaryActionLabel: 'Go to dashboard now',
        onSecondaryAction: () => context.go(Routes.home),
      );
    }

    return StatusScreen.error(
      title: 'Verification failed',
      message: _error ?? 'Unable to verify your email. The link may be invalid or expired.',
      primaryActionLabel: 'Go to sign in',
      onPrimaryAction: () => context.go(Routes.login),
      bottomWidget: InfoBanner(
        message: 'Need a new verification link? Sign in and request a new one from your profile.',
      ),
    );
  }
}
