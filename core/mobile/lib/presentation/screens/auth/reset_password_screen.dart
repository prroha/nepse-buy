import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../router/routes.dart';
import '../../widgets/atoms/app_button.dart';
import '../../widgets/layout/auth_scaffold.dart';
import '../../widgets/layout/status_screen.dart';
import '../../widgets/molecules/app_text_field.dart';

/// Reset password screen for setting a new password with a reset token
/// Note: Deep link handling is TODO - this screen expects a token query parameter
class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String? token;

  const ResetPasswordScreen({super.key, this.token});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isVerifying = true;
  bool _isValidToken = false;
  bool _success = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _tokenEmail;
  String? _error;

  @override
  void initState() {
    super.initState();
    _verifyToken();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _verifyToken() async {
    if (widget.token == null || widget.token!.isEmpty) {
      setState(() {
        _isVerifying = false;
        _isValidToken = false;
      });
      return;
    }

    final authRepo = ref.read(authRepositoryProvider);
    final result = await authRepo.verifyResetToken(widget.token!);

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isVerifying = false;
          _isValidToken = false;
        });
      },
      (response) {
        setState(() {
          _isVerifying = false;
          _isValidToken = response.valid;
          _tokenEmail = response.email;
        });
      },
    );
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
      return 'Password must contain uppercase, lowercase, and a number';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final authRepo = ref.read(authRepositoryProvider);
    final result = await authRepo.resetPassword(
      token: widget.token!,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _error = failure.message;
        });
      },
      (_) {
        setState(() {
          _isLoading = false;
          _success = true;
        });
        // Redirect to login after delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            context.go(Routes.login);
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_isVerifying) {
      return const StatusScreen.loading(
        title: 'Verifying Reset Link...',
        message: 'Please wait while we verify your request.',
      );
    }

    // Invalid or missing token
    if (!_isValidToken) {
      return StatusScreen.error(
        title: 'Invalid or Expired Link',
        message: 'This password reset link is invalid or has expired. Please request a new one.',
        primaryActionLabel: 'Request New Reset Link',
        onPrimaryAction: () => context.go(Routes.forgotPassword),
        secondaryActionLabel: 'Back to Sign In',
        onSecondaryAction: () => context.go(Routes.login),
      );
    }

    // Success state
    if (_success) {
      return StatusScreen.success(
        title: 'Password Reset Successful!',
        message: 'Your password has been reset. Redirecting you to sign in...',
        secondaryActionLabel: "Click here if you're not redirected",
        onSecondaryAction: () => context.go(Routes.login),
      );
    }

    // Reset form
    return _buildResetForm();
  }

  Widget _buildResetForm() {
    final colorScheme = Theme.of(context).colorScheme;

    return AuthScaffold(
      showBackButton: true,
      onBack: () => context.go(Routes.login),
      bottomWidget: AuthNavLink(
        prompt: 'Remember your password?',
        actionLabel: 'Sign In',
        onAction: () => context.go(Routes.login),
        isLoading: _isLoading,
      ),
      child: AuthCard(
        title: 'Reset Your Password',
        subtitle: _tokenEmail != null
            ? 'Enter a new password for $_tokenEmail'
            : 'Enter your new password below',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Error message
            if (_error != null && _error!.isNotEmpty) ...[
              ErrorBanner(
                message: _error!,
                onDismiss: () => setState(() => _error = null),
              ),
              AppSpacing.gapMd,
            ],

            // Password field
            AppTextField(
              controller: _passwordController,
              label: 'New Password',
              hint: 'Enter your new password',
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              validator: _validatePassword,
              enabled: !_isLoading,
            ),
            AppSpacing.gapSm,
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                'Must be at least 8 characters with uppercase, lowercase, and a number.',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            AppSpacing.gapMd,

            // Confirm Password field
            AppTextField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              hint: 'Confirm your new password',
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              validator: _validateConfirmPassword,
              enabled: !_isLoading,
              onSubmitted: (_) => _handleSubmit(),
            ),
            AppSpacing.gapLg,

            // Submit button
            AppButton(
              label: 'Reset Password',
              onPressed: _isLoading ? null : _handleSubmit,
              isLoading: _isLoading,
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}
