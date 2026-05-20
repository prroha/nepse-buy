import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../router/routes.dart';
import '../../widgets/atoms/app_button.dart';
import '../../widgets/molecules/app_snackbar.dart';
import '../../widgets/molecules/app_text_field.dart';
import '../../widgets/layout/loading_overlay.dart';
import '../../widgets/layout/error_state.dart';
import '../../widgets/organisms/avatar_upload.dart';

/// Profile screen for viewing and editing user profile
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    // Load profile on screen open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileProvider.notifier).loadProfile();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    final profile = ref.read(profileProvider).profile;
    if (profile != null) {
      _nameController.text = profile.name ?? '';
      _emailController.text = profile.email;
      _hasChanges = false;
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.length > 100) {
      return 'Name must be less than 100 characters';
    }
    final nameRegex = RegExp(r"^[a-zA-Z\s'-]+$");
    if (!nameRegex.hasMatch(value)) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }
    return null;
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

  Future<void> _handleSave() async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await ref.read(profileProvider.notifier).updateProfile(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
          );

      if (mounted) {
        if (success) {
          AppSnackbar.success(
            context,
            'Profile updated',
            description: 'Your profile has been saved successfully.',
          );
          setState(() {
            _hasChanges = false;
          });
        } else {
          final error = ref.read(profileProvider).error;
          if (error != null) {
            AppSnackbar.error(
              context,
              'Update failed',
              description: error,
            );
          }
        }
      }
    }
  }

  void _handleCancel() {
    _initializeForm();
    setState(() {
      _hasChanges = false;
    });
  }

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        AppSnackbar.info(
          context,
          'Logged out',
          description: 'You have been signed out successfully.',
        );
        context.go(Routes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final authState = ref.watch(authProvider);

    // Initialize form when profile is loaded
    ref.listen(profileProvider, (previous, next) {
      if (previous?.profile == null && next.profile != null) {
        _initializeForm();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.home),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: profileState.isLoading,
        child: _buildBody(profileState, authState),
      ),
    );
  }

  Widget _buildBody(ProfileState profileState, AuthState authState) {
    // Error state
    if (profileState.error != null && profileState.profile == null) {
      return ErrorStateWidget(
        message: profileState.error!,
        onRetry: () => ref.read(profileProvider.notifier).loadProfile(),
      );
    }

    // Profile loaded
    if (profileState.profile == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(profileProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSpacing.gapMd,

            // Avatar card
            _buildAvatarCard(profileState),
            AppSpacing.gapLg,

            // Profile form
            _buildProfileForm(profileState),
            AppSpacing.gapLg,

            // Account info
            _buildAccountInfo(profileState),
            AppSpacing.gapLg,

            // Change password link
            _buildChangePasswordLink(),
            AppSpacing.gapXl,
          ],
        ),
      ),
    );
  }

  Future<void> _handleAvatarUpload(File file) async {
    final success = await ref.read(profileProvider.notifier).uploadAvatar(file);
    if (mounted) {
      if (success) {
        AppSnackbar.success(
          context,
          'Avatar uploaded',
          description: 'Your profile picture has been updated.',
        );
      } else {
        final error = ref.read(profileProvider).error;
        if (error != null) {
          AppSnackbar.error(
            context,
            'Upload failed',
            description: error,
          );
        }
      }
    }
  }

  Future<void> _handleAvatarRemove() async {
    final success = await ref.read(profileProvider.notifier).deleteAvatar();
    if (mounted) {
      if (success) {
        AppSnackbar.success(
          context,
          'Avatar removed',
          description: 'Your profile picture has been removed.',
        );
      } else {
        final error = ref.read(profileProvider).error;
        if (error != null) {
          AppSnackbar.error(
            context,
            'Remove failed',
            description: error,
          );
        }
      }
    }
  }

  Widget _buildAvatarCard(ProfileState state) {
    final profile = state.profile!;
    final avatar = state.avatar;

    return Container(
      padding: AppSpacing.cardContentPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar with upload capability
          AvatarUpload(
            currentAvatarUrl: avatar?.url,
            initials: avatar?.initials ?? 'U',
            onUpload: _handleAvatarUpload,
            onRemove: avatar?.url != null ? _handleAvatarRemove : null,
            isUploading: state.isUploadingAvatar,
            uploadProgress: state.uploadProgress,
            size: AvatarUploadSize.xl,
            disabled: state.isSaving,
          ),
          AppSpacing.gapMd,
          // Name
          Text(
            profile.name ?? 'No name set',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          AppSpacing.gapXs,
          // Email
          Text(
            profile.email,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          AppSpacing.gapSm,
          // Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBadge(
                profile.role == 'SUPER_ADMIN' ? 'Super Admin' : profile.role,
                profile.role == 'SUPER_ADMIN'
                    ? AppColors.error
                    : profile.role == 'ADMIN'
                        ? AppColors.primary
                        : AppColors.secondary,
              ),
              if (profile.isActive) ...[
                AppSpacing.gapHSm,
                _buildBadge('Active', AppColors.success),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildProfileForm(ProfileState state) {
    return Container(
      padding: AppSpacing.cardContentPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            AppSpacing.gapMd,

            // Error message
            if (state.error != null && state.profile != null)
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
                        state.error!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.error, size: 18),
                      onPressed: () => ref.read(profileProvider.notifier).clearError(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

            // Name field
            AppTextField(
              controller: _nameController,
              label: 'Name',
              hint: 'Enter your name',
              prefixIcon: const Icon(Icons.person_outline),
              validator: _validateName,
              enabled: !state.isSaving,
              onChanged: (_) {
                if (!_hasChanges) {
                  setState(() {
                    _hasChanges = true;
                  });
                }
              },
            ),
            AppSpacing.gapMd,

            // Email field
            AppTextField(
              controller: _emailController,
              label: 'Email',
              hint: 'Enter your email',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.email_outlined),
              validator: _validateEmail,
              enabled: !state.isSaving,
              onChanged: (_) {
                if (!_hasChanges) {
                  setState(() {
                    _hasChanges = true;
                  });
                }
              },
            ),
            AppSpacing.gapLg,

            // Buttons
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Save Changes',
                    onPressed: _hasChanges && !state.isSaving ? _handleSave : null,
                    isLoading: state.isSaving,
                  ),
                ),
                if (_hasChanges) ...[
                  AppSpacing.gapHMd,
                  AppButton(
                    label: 'Cancel',
                    onPressed: state.isSaving ? null : _handleCancel,
                    variant: AppButtonVariant.outline,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfo(ProfileState state) {
    final profile = state.profile!;

    return Container(
      padding: AppSpacing.cardContentPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          AppSpacing.gapMd,
          _buildInfoRow('User ID', profile.id),
          AppSpacing.gapSm,
          _buildInfoRow(
            'Member Since',
            _formatDate(profile.createdAt),
          ),
          AppSpacing.gapSm,
          _buildInfoRow(
            'Last Updated',
            _formatDate(profile.updatedAt),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'monospace',
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  Widget _buildChangePasswordLink() {
    return Container(
      padding: AppSpacing.cardContentPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          AppSpacing.gapMd,
          // Change password - full width list tile style for better discoverability
          InkWell(
            onTap: () => context.go(Routes.changePassword),
            borderRadius: AppSpacing.borderRadiusSm,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      borderRadius: AppSpacing.borderRadiusSm,
                    ),
                    child: const Icon(Icons.lock_outline, size: 20, color: AppColors.primary),
                  ),
                  AppSpacing.gapHMd,
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Change Password',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Update your account password',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          // Settings - full width list tile style
          InkWell(
            onTap: () => context.go(Routes.settings),
            borderRadius: AppSpacing.borderRadiusSm,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withAlpha(25),
                      borderRadius: AppSpacing.borderRadiusSm,
                    ),
                    child: const Icon(Icons.settings_outlined, size: 20, color: AppColors.secondary),
                  ),
                  AppSpacing.gapHMd,
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Settings',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Manage app preferences',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
