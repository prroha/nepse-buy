import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../router/routes.dart';
import '../../widgets/atoms/app_button.dart';
import '../../widgets/layout/auth_scaffold.dart';
import '../../widgets/molecules/app_text_field.dart';

/// Forgot password screen for requesting password reset
/// Uses centered card layout with theme system colors
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _submitted = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)+$',
    );
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
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
    final result = await authRepo.forgotPassword(
      email: _emailController.text.trim(),
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
          _submitted = true;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return _buildSuccessView();
    }

    return AuthScaffold(
      showBackButton: true,
      onBack: () => context.go(Routes.login),
      icon: Icons.lock_reset_rounded,
      bottomWidget: AuthNavLink(
        prompt: 'Remember your password?',
        actionLabel: 'Sign In',
        onAction: () => context.go(Routes.login),
        isLoading: _isLoading,
      ),
      child: Form(
        key: _formKey,
        child: AuthCard(
          title: 'Forgot Password?',
          subtitle: "Enter your email address and we'll send you a link to reset your password.",
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

              // Email field
              AppTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'Enter your email',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                prefixIcon: const Icon(Icons.email_outlined),
                validator: _validateEmail,
                enabled: !_isLoading,
                onSubmitted: (_) => _handleSubmit(),
              ),
              AppSpacing.gapLg,

              // Submit button
              AppButton(
                label: 'Send Reset Link',
                onPressed: _isLoading ? null : _handleSubmit,
                isLoading: _isLoading,
                isFullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AuthScaffold(
      child: AuthCard(
        child: Column(
          children: [
            // Success icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.email_outlined,
                size: 40,
                color: colorScheme.primary,
              ),
            ),
            AppSpacing.gapLg,

            // Success message
            Text(
              'Check Your Email',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapSm,
            Text(
              'If an account exists for ${_emailController.text}, we\'ve sent a password reset link.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapXl,

            // Primary action
            AppButton(
              label: 'Back to Sign In',
              onPressed: () => context.go(Routes.login),
              isFullWidth: true,
            ),
            AppSpacing.gapMd,

            // Secondary action
            TextButton(
              onPressed: () {
                setState(() {
                  _submitted = false;
                  _emailController.clear();
                });
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                minimumSize: const Size(48, 44),
              ),
              child: Text(
                "Didn't receive the email? Try again",
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
