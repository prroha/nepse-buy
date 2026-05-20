import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../router/routes.dart';
import '../../widgets/atoms/app_button.dart';
import '../../widgets/molecules/app_snackbar.dart';
import '../../widgets/molecules/email_verification_banner.dart';
import '../../widgets/notifications/notification_bell.dart';
import '../../widgets/organisms/app_drawer.dart';

/// Home screen with user info, drawer navigation, and logout functionality
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final colorScheme = Theme.of(context).colorScheme;

    // Show confirmation dialog
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
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Build drawer items based on user role
    final drawerItems = <AppDrawerItem>[
      AppDrawerItem(
        icon: Icons.home_outlined,
        label: 'Home',
        isSelected: true,
        onTap: () {}, // Already on home
      ),
      AppDrawerItem(
        icon: Icons.person_outline,
        label: 'Profile',
        onTap: () => context.go(Routes.profile),
      ),
      AppDrawerItem(
        icon: Icons.search,
        label: 'Search',
        onTap: () => context.push(Routes.search),
      ),
      AppDrawerItem(
        icon: Icons.notifications_outlined,
        label: 'Notifications',
        onTap: () => context.push(Routes.notifications),
      ),
    ];

    // Add admin items if user is admin
    if (authState.isAdmin) {
      drawerItems.addAll([
        AppDrawerItem(
          icon: Icons.dashboard_outlined,
          label: 'Admin Dashboard',
          onTap: () => context.push(Routes.adminDashboard),
        ),
        AppDrawerItem(
          icon: Icons.people_outline,
          label: 'Manage Users',
          onTap: () => context.push(Routes.adminUsers),
        ),
        AppDrawerItem(
          icon: Icons.history,
          label: 'Audit Logs',
          onTap: () => context.push(Routes.adminAuditLogs),
        ),
      ]);
    }

    final footerItems = <AppDrawerItem>[
      AppDrawerItem(
        icon: Icons.settings_outlined,
        label: 'Settings',
        onTap: () => context.go(Routes.settings),
      ),
      AppDrawerItem(
        icon: Icons.logout,
        label: 'Logout',
        onTap: () => _handleLogout(context, ref),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        centerTitle: true,
        elevation: 0,
        actions: [
          // Notifications bell - time-sensitive, kept prominent
          const NotificationBell(),
          // User menu - consolidates Profile, Settings, Theme, Logout
          _UserMenu(onLogout: () => _handleLogout(context, ref)),
        ],
      ),
      drawer: AppDrawer(
        headerTitle: authState.email ?? 'User',
        headerSubtitle: authState.isAdmin ? 'Administrator' : 'Member',
        headerAvatar: CircleAvatar(
          radius: 24,
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
            authState.email?.isNotEmpty == true
                ? authState.email![0].toUpperCase()
                : 'U',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        items: drawerItems,
        footerItems: footerItems,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Email verification banner - shown when email is not verified
            if (!authState.isEmailVerified)
              EmailVerificationBanner(email: authState.email),

            Expanded(
              child: Padding(
                padding: AppSpacing.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppSpacing.gapLg,
                    // Welcome card
                    Container(
                      padding: AppSpacing.cardContentPadding,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: AppSpacing.borderRadiusMd,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withAlpha(20),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: colorScheme.primary,
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                          AppSpacing.gapMd,
                          Text(
                            'Welcome!',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          AppSpacing.gapXs,
                          if (authState.email != null)
                            Text(
                              authState.email!,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          if (authState.isAdmin) ...[
                            AppSpacing.gapSm,
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.tertiaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Administrator',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onTertiaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    AppSpacing.gapXl,

                    // Info section
                    Text(
                      'You are successfully logged in.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    AppSpacing.gapLg,

                    // Profile button
                    AppButton(
                      label: 'View Profile',
                      onPressed: () => context.go(Routes.profile),
                      variant: AppButtonVariant.primary,
                      isFullWidth: true,
                      icon: Icons.person,
                    ),
                    AppSpacing.gapMd,

                    // Settings button
                    AppButton(
                      label: 'Settings',
                      onPressed: () => context.go(Routes.settings),
                      variant: AppButtonVariant.outline,
                      isFullWidth: true,
                      icon: Icons.settings,
                    ),

                    // Admin button - only visible for admin users
                    if (authState.isAdmin) ...[
                      AppSpacing.gapMd,
                      AppButton(
                        label: 'Admin Dashboard',
                        onPressed: () => context.push(Routes.adminDashboard),
                        variant: AppButtonVariant.secondary,
                        isFullWidth: true,
                        icon: Icons.admin_panel_settings,
                      ),
                    ],

                    const Spacer(),

                    // Logout button - styled as text button to be less prominent
                    // keeping it accessible but not encouraging accidental taps
                    TextButton.icon(
                      onPressed: () => _handleLogout(context, ref),
                      icon: Icon(Icons.logout, color: colorScheme.error),
                      label: Text(
                        'Logout',
                        style: TextStyle(color: colorScheme.error),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    AppSpacing.gapMd,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// User menu popup that consolidates Profile, Settings, Theme, and Logout
/// Reduces cognitive load by grouping related actions (Hick's Law)
class _UserMenu extends ConsumerWidget {
  final VoidCallback onLogout;

  const _UserMenu({required this.onLogout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    // Get user initial for avatar
    final userInitial = authState.email?.isNotEmpty == true
        ? authState.email![0].toUpperCase()
        : 'U';

    return PopupMenuButton<String>(
      icon: CircleAvatar(
        radius: 16,
        backgroundColor: colorScheme.primaryContainer,
        child: Text(
          userInitial,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
      ),
      tooltip: 'User menu',
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      itemBuilder: (context) => [
        // Profile
        const PopupMenuItem<String>(
          value: 'profile',
          child: ListTile(
            leading: Icon(Icons.person_outline),
            title: Text('Profile'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        // Settings
        const PopupMenuItem<String>(
          value: 'settings',
          child: ListTile(
            leading: Icon(Icons.settings_outlined),
            title: Text('Settings'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        // Search
        const PopupMenuItem<String>(
          value: 'search',
          child: ListTile(
            leading: Icon(Icons.search),
            title: Text('Search'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        const PopupMenuDivider(),
        // Theme toggle
        PopupMenuItem<String>(
          value: 'theme',
          child: ListTile(
            leading: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            title: Text(isDark ? 'Light Mode' : 'Dark Mode'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        const PopupMenuDivider(),
        // Logout
        PopupMenuItem<String>(
          value: 'logout',
          child: ListTile(
            leading: Icon(Icons.logout, color: colorScheme.error),
            title: Text(
              'Logout',
              style: TextStyle(color: colorScheme.error),
            ),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'profile':
            context.go(Routes.profile);
          case 'settings':
            context.go(Routes.settings);
          case 'search':
            context.push(Routes.search);
          case 'theme':
            ref.read(themeProvider.notifier).toggleTheme(context);
          case 'logout':
            onLogout();
        }
      },
    );
  }
}
