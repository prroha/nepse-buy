import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/repositories/auth_repository.dart';
import '../atoms/app_button.dart';
import 'app_snackbar.dart';

/// Email verification banner shown when user's email is not verified
class EmailVerificationBanner extends ConsumerStatefulWidget {
  final String? email;
  final VoidCallback? onDismiss;

  const EmailVerificationBanner({
    super.key,
    this.email,
    this.onDismiss,
  });

  @override
  ConsumerState<EmailVerificationBanner> createState() => _EmailVerificationBannerState();
}

class _EmailVerificationBannerState extends ConsumerState<EmailVerificationBanner> {
  bool _isSending = false;
  bool _isDismissed = false;

  Future<void> _handleResendVerification() async {
    setState(() {
      _isSending = true;
    });

    final authRepository = ref.read(authRepositoryProvider);
    final result = await authRepository.sendVerificationEmail();

    result.fold(
      (failure) {
        if (mounted) {
          AppSnackbar.error(
            context,
            'Failed to send verification email',
            description: failure.message,
          );
        }
      },
      (_) {
        if (mounted) {
          AppSnackbar.success(
            context,
            'Verification email sent',
            description: 'Please check your inbox for the verification link.',
          );
        }
      },
    );

    if (mounted) {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _handleDismiss() {
    setState(() {
      _isDismissed = true;
    });
    widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      // Tighter padding
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border(
          bottom: BorderSide(
            color: Colors.amber.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.email_outlined,
            color: Colors.amber.shade700,
            size: 18, // Smaller
          ),
          AppSpacing.gapHXs, // Tighter gap
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Verify your email address',
                  style: TextStyle(
                    fontSize: 13, // Smaller
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade900,
                  ),
                ),
                if (widget.email != null)
                  Text(
                    'Sent to ${widget.email}',
                    style: TextStyle(
                      fontSize: 11, // Smaller
                      color: Colors.amber.shade700,
                    ),
                  ),
              ],
            ),
          ),
          AppSpacing.gapHXs, // Tighter gap
          SizedBox(
            height: 28, // Smaller button
            child: AppButton(
              label: 'Resend',
              onPressed: _isSending ? null : _handleResendVerification,
              isLoading: _isSending,
              variant: AppButtonVariant.outline,
              size: AppButtonSize.small,
            ),
          ),
          const SizedBox(width: 2),
          IconButton(
            onPressed: _handleDismiss,
            icon: Icon(
              Icons.close,
              size: 16, // Smaller
              color: Colors.amber.shade700,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 24,
              minHeight: 24,
            ),
          ),
        ],
      ),
    );
  }
}
