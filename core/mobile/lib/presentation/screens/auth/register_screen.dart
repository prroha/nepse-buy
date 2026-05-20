import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_spacing.dart';
import '../../providers/auth_provider.dart';
import '../../router/routes.dart';
import '../../widgets/atoms/app_button.dart';
import '../../widgets/layout/auth_scaffold.dart';
import '../../widgets/molecules/app_snackbar.dart';
import '../../widgets/molecules/app_text_field.dart';

/// Password strength levels
enum PasswordStrength { weak, fair, good, strong }

/// Registration screen with form validation
/// Uses centered card layout with theme system colors
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  PasswordStrength _passwordStrength = PasswordStrength.weak;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_updatePasswordStrength);
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    final password = _passwordController.text;
    setState(() {
      _passwordStrength = _calculatePasswordStrength(password);
    });
  }

  PasswordStrength _calculatePasswordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.weak;

    int score = 0;

    // Length checks
    if (password.length >= ValidationConfig.passwordMinLength) score++;
    if (password.length >= ValidationConfig.passwordMinLength + 4) score++;

    // Character type checks
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.fair;
    if (score <= 5) return PasswordStrength.good;
    return PasswordStrength.strong;
  }

  Color _getStrengthColor(PasswordStrength strength, ColorScheme colorScheme) {
    switch (strength) {
      case PasswordStrength.weak:
        return colorScheme.error;
      case PasswordStrength.fair:
        return Colors.orange;
      case PasswordStrength.good:
        return Colors.yellow.shade700;
      case PasswordStrength.strong:
        return Colors.green;
    }
  }

  String _getStrengthLabel(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.fair:
        return 'Fair';
      case PasswordStrength.good:
        return 'Good';
      case PasswordStrength.strong:
        return 'Strong';
    }
  }

  double _getStrengthProgress(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return 0.25;
      case PasswordStrength.fair:
        return 0.5;
      case PasswordStrength.good:
        return 0.75;
      case PasswordStrength.strong:
        return 1.0;
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!ValidationConfig.emailPattern.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < ValidationConfig.passwordMinLength) {
      return 'Password must be at least ${ValidationConfig.passwordMinLength} characters';
    }
    // Additional strength requirements
    if (!ValidationConfig.passwordComplexityPattern.hasMatch(value)) {
      return 'Password must contain at least one letter and one number';
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

  Future<void> _handleRegister() async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await ref.read(authProvider.notifier).register(
            _emailController.text.trim(),
            _passwordController.text,
            _confirmPasswordController.text,
          );
      if (mounted) {
        if (success) {
          AppSnackbar.success(
            context,
            'Account created!',
            description: 'Welcome aboard. You are now signed in.',
          );
          context.go(Routes.home);
        } else {
          // Error is already shown in the UI, but also show a snackbar
          final error = ref.read(authProvider).error;
          if (error != null) {
            AppSnackbar.error(
              context,
              'Registration failed',
              description: error,
            );
          }
        }
      }
    }
  }

  Widget _buildPasswordStrengthIndicator(ColorScheme colorScheme) {
    final password = _passwordController.text;
    if (password.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _getStrengthProgress(_passwordStrength),
                  backgroundColor: colorScheme.outlineVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getStrengthColor(_passwordStrength, colorScheme),
                  ),
                  minHeight: 4,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _getStrengthLabel(_passwordStrength),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _getStrengthColor(_passwordStrength, colorScheme),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Use 8+ characters with uppercase, lowercase, numbers, and symbols',
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurfaceVariant.withAlpha(180),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final errorMessage = authState.error;
    final colorScheme = Theme.of(context).colorScheme;

    return AuthScaffold(
      icon: Icons.person_add_rounded,
      bottomWidget: AuthNavLink(
        prompt: 'Already have an account?',
        actionLabel: 'Sign In',
        onAction: () => context.go(Routes.login),
        isLoading: authState.isLoading,
      ),
      child: Form(
        key: _formKey,
        child: AuthCard(
          title: 'Create Account',
          subtitle: 'Sign up to get started',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Error message
              if (errorMessage != null && errorMessage.isNotEmpty) ...[
                ErrorBanner(
                  message: errorMessage,
                  onDismiss: () => ref.read(authProvider.notifier).clearError(),
                ),
                AppSpacing.gapMd,
              ],

              // Email field
              AppTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'Enter your email',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.email_outlined),
                validator: _validateEmail,
                enabled: !authState.isLoading,
              ),
              AppSpacing.gapMd,

              // Password field with strength indicator
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'Enter your password',
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
                    enabled: !authState.isLoading,
                  ),
                  _buildPasswordStrengthIndicator(colorScheme),
                ],
              ),
              AppSpacing.gapMd,

              // Confirm password field
              AppTextField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                hint: 'Confirm your password',
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
                enabled: !authState.isLoading,
                onSubmitted: (_) => _handleRegister(),
              ),
              AppSpacing.gapLg,

              // Register button
              AppButton(
                label: 'Create Account',
                onPressed: authState.isLoading ? null : _handleRegister,
                isLoading: authState.isLoading,
                isFullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
