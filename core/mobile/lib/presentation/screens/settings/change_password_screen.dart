import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/atoms/app_button.dart';
import '../../widgets/molecules/app_snackbar.dart';
import '../../widgets/molecules/password_field.dart';

/// Screen for changing user password
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showSuccess = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Current password is required';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'New password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    // Check for at least one uppercase, one lowercase, and one number
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
      return 'Password must contain uppercase, lowercase, and number';
    }
    if (value == _currentPasswordController.text) {
      return 'New password must be different from current';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _handleChangePassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await ref.read(authProvider.notifier).changePassword(
            _currentPasswordController.text,
            _newPasswordController.text,
            _confirmPasswordController.text,
          );

      if (mounted) {
        if (success) {
          setState(() {
            _showSuccess = true;
          });
          // Clear form
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();

          // Show success snackbar
          AppSnackbar.success(
            context,
            'Password changed',
            description: 'Your password has been updated successfully.',
          );
        } else {
          // Show error snackbar
          final error = ref.read(authProvider).error;
          if (error != null) {
            AppSnackbar.error(
              context,
              'Password change failed',
              description: error,
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final errorMessage = authState.error;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Change Password'),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                const Text(
                  'Update Your Password',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                AppSpacing.gapSm,
                const Text(
                  'Enter your current password and choose a new secure password.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                AppSpacing.gapXl,

                // Error message
                if (errorMessage != null && errorMessage.isNotEmpty) ...[
                  Container(
                    padding: AppSpacing.cardContentPadding,
                    decoration: BoxDecoration(
                      color: AppColors.error.withAlpha(25),
                      borderRadius: AppSpacing.borderRadiusMd,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error),
                        AppSpacing.gapHSm,
                        Expanded(
                          child: Text(
                            errorMessage,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.error, size: 18),
                          onPressed: () => ref.read(authProvider.notifier).clearError(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapMd,
                ],

                // Success message
                if (_showSuccess) ...[
                  Container(
                    padding: AppSpacing.cardContentPadding,
                    decoration: BoxDecoration(
                      color: AppColors.success.withAlpha(25),
                      borderRadius: AppSpacing.borderRadiusMd,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: AppColors.success),
                        AppSpacing.gapHSm,
                        const Expanded(
                          child: Text(
                            'Password changed successfully!',
                            style: TextStyle(color: AppColors.success),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.success, size: 18),
                          onPressed: () => setState(() => _showSuccess = false),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapMd,
                ],

                // Current password field
                PasswordField(
                  controller: _currentPasswordController,
                  label: 'Current Password',
                  hint: 'Enter your current password',
                  textInputAction: TextInputAction.next,
                  validator: _validateCurrentPassword,
                  enabled: !authState.isLoading,
                ),
                AppSpacing.gapMd,

                // New password field
                PasswordField(
                  controller: _newPasswordController,
                  label: 'New Password',
                  hint: 'Enter your new password',
                  textInputAction: TextInputAction.next,
                  helperText: 'At least 8 characters with uppercase, lowercase, and number',
                  validator: _validateNewPassword,
                  enabled: !authState.isLoading,
                ),
                AppSpacing.gapMd,

                // Confirm password field
                PasswordField(
                  controller: _confirmPasswordController,
                  label: 'Confirm New Password',
                  hint: 'Re-enter your new password',
                  textInputAction: TextInputAction.done,
                  validator: _validateConfirmPassword,
                  enabled: !authState.isLoading,
                  onSubmitted: (_) => _handleChangePassword(),
                ),
                AppSpacing.gapLg,

                // Change password button
                AppButton(
                  label: 'Change Password',
                  onPressed: authState.isLoading ? null : _handleChangePassword,
                  isLoading: authState.isLoading,
                  isFullWidth: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
