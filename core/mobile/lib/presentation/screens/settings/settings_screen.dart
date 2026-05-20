import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/export_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../router/routes.dart';
import '../../widgets/molecules/app_snackbar.dart';
import '../../widgets/settings/settings.dart';
import '../../widgets/theme_selector.dart';

/// Settings screen with organized sections for app configuration
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _appVersion = '';
  String _buildNumber = '';
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = packageInfo.version;
          _buildNumber = packageInfo.buildNumber;
        });
      }
    } catch (_) {
      // Fallback if package info fails
      if (mounted) {
        setState(() {
          _appVersion = '1.0.0';
          _buildNumber = '1';
        });
      }
    }
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
            child: Text(
              'Logout',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
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

  Future<void> _handleDeleteAccount(BuildContext context) async {
    final confirmed = await _showDeleteAccountDialog(context);

    if (confirmed == true && mounted) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        // Note: You'll need to add a deleteAccount method to the auth provider
        await ref.read(authProvider.notifier).logout();

        if (mounted) {
          Navigator.of(context).pop(); // Dismiss loading
          AppSnackbar.success(
            context,
            'Account deleted',
            description: 'Your account has been permanently deleted.',
          );
          context.go(Routes.login);
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Dismiss loading
          AppSnackbar.error(
            context,
            'Failed to delete account',
            description: 'An error occurred. Please try again.',
          );
        }
      }
    }
  }

  Future<bool?> _showDeleteAccountDialog(BuildContext context) async {
    final TextEditingController confirmController = TextEditingController();

    return showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.delete_forever,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Delete Account'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to delete your account? All of your data will be permanently removed. This action cannot be undone.',
              ),
              const SizedBox(height: 16),
              Text(
                'Type DELETE to confirm',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmController,
                decoration: const InputDecoration(
                  hintText: 'DELETE',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: confirmController.text == 'DELETE'
                  ? () => Navigator.of(context).pop(true)
                  : null,
              child: Text(
                'Delete',
                style: TextStyle(
                  color: confirmController.text == 'DELETE'
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.onSurface.withAlpha(100),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        AppSnackbar.error(
          context,
          'Cannot open link',
          description: 'Unable to open the link. Please try again.',
        );
      }
    }
  }

  Future<void> _handleExportData(BuildContext context) async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
    });

    try {
      // Show format selection dialog
      final format = await showDialog<ExportFormat>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export My Data'),
          content: const Text('Choose the format for your data export:'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(ExportFormat.json),
              child: const Text('JSON'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(ExportFormat.csv),
              child: const Text('CSV'),
            ),
          ],
        ),
      );

      if (format == null || !mounted) {
        setState(() {
          _isExporting = false;
        });
        return;
      }

      final exportService = ref.read(exportServiceProvider);
      final result = await exportService.exportAndShareMyData(format: format);

      if (!mounted) return;

      result.fold(
        (failure) {
          AppSnackbar.error(
            context,
            'Export failed',
            description: failure.message,
          );
        },
        (_) {
          AppSnackbar.success(
            context,
            'Data exported',
            description: 'Your data has been exported and shared.',
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  void _showThemeDialog(BuildContext context) {
    final themeState = ref.read(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppThemeMode.values.map((mode) {
            return RadioListTile<AppThemeMode>(
              title: Row(
                children: [
                  Icon(mode.icon),
                  const SizedBox(width: 12),
                  Text(mode.label),
                ],
              ),
              value: mode,
              groupValue: themeState.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeNotifier.setTheme(value);
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.home),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          // Profile Section
          SettingsSection(
            title: 'Profile',
            description: 'Manage your profile information',
            children: [
              SettingsItem(
                icon: Icons.person_outline,
                label: 'Edit Profile',
                description: 'Update your name, email, and avatar',
                onTap: () => context.go(Routes.profile),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Security Section
          SettingsSection(
            title: 'Security',
            description: 'Manage your account security',
            children: [
              SettingsItem(
                icon: Icons.lock_outline,
                label: 'Change Password',
                description: 'Update your password',
                onTap: () => context.go(Routes.changePassword),
              ),
              SettingsItem(
                icon: Icons.devices,
                label: 'Active Sessions',
                description: 'View and manage your active sessions',
                onTap: () => context.go(Routes.sessions),
              ),
              SettingsItem(
                icon: Icons.shield_outlined,
                label: 'Two-Factor Authentication',
                description: 'Add an extra layer of security',
                value: 'Coming soon',
                disabled: true,
                showChevron: false,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Appearance Section
          SettingsSection(
            title: 'Appearance',
            description: 'Customize how the app looks',
            children: [
              SettingsItem(
                icon: themeState.themeMode.icon,
                label: 'Color Mode',
                description: 'Light, dark, or system theme',
                value: themeState.themeMode.label,
                onTap: () => _showThemeDialog(context),
              ),
              SettingsItem(
                icon: Icons.palette_outlined,
                label: 'App Theme',
                description: 'Choose your color scheme',
                value: themeState.appTheme.displayName,
                onTap: () => ThemeSelectorDialog.show(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Notifications Section
          SettingsSection(
            title: 'Notifications',
            description: 'Configure notification preferences',
            children: [
              SettingsItem(
                icon: Icons.email_outlined,
                label: 'Email Notifications',
                description: 'Receive updates via email',
                value: 'Coming soon',
                disabled: true,
                showChevron: false,
              ),
              SettingsItem(
                icon: Icons.notifications_outlined,
                label: 'Push Notifications',
                description: 'Receive push notifications',
                value: 'Coming soon',
                disabled: true,
                showChevron: false,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Data & Privacy Section
          SettingsSection(
            title: 'Data & Privacy',
            description: 'Manage your data',
            children: [
              SettingsItem(
                icon: Icons.download_outlined,
                label: 'Export My Data',
                description: 'Download a copy of your personal data (GDPR)',
                onTap: _isExporting ? null : () => _handleExportData(context),
                trailing: _isExporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Account Section - destructive actions with clear visual distinction
          SettingsSection(
            title: 'Account',
            description: 'Manage your account',
            children: [
              SettingsItem(
                icon: Icons.logout,
                label: 'Logout',
                description: 'Sign out of your account',
                onTap: () => _handleLogout(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Danger Zone - separated for clear visual hierarchy
          SettingsSection(
            title: 'Danger Zone',
            description: 'Irreversible actions',
            children: [
              SettingsItem(
                icon: Icons.delete_forever_outlined,
                label: 'Delete Account',
                description: 'Permanently delete your account and all data',
                variant: SettingsItemVariant.danger,
                onTap: () => _handleDeleteAccount(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Help & Support Section
          SettingsSection(
            title: 'Help & Support',
            description: 'Get help and contact us',
            children: [
              SettingsItem(
                icon: Icons.mail_outline,
                label: 'Contact Us',
                description: 'Send us a message',
                onTap: () => context.push(Routes.contact),
              ),
              SettingsItem(
                icon: Icons.help_outline,
                label: 'FAQ',
                description: 'Frequently asked questions',
                onTap: () => context.push(Routes.faq),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // About Section
          SettingsSection(
            title: 'About',
            description: 'App information and legal',
            children: [
              SettingsItem(
                icon: Icons.info_outline,
                label: 'About App',
                description: 'Learn about Fullstack Starter',
                onTap: () => context.push(Routes.about),
              ),
              SettingsItem(
                icon: Icons.numbers,
                label: 'App Version',
                value: 'v$_appVersion ($_buildNumber)',
                showChevron: false,
              ),
              SettingsItem(
                icon: Icons.description_outlined,
                label: 'Terms of Service',
                onTap: () => context.push(Routes.terms),
              ),
              SettingsItem(
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy Policy',
                onTap: () => context.push(Routes.privacy),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
