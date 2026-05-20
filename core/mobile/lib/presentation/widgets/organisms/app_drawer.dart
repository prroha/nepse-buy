import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_spacing.dart';
import '../../providers/theme_provider.dart';

/// A menu item in the navigation drawer.
class AppDrawerItem {
  /// The icon displayed for the menu item.
  final IconData icon;

  /// The label displayed for the menu item.
  final String label;

  /// Route or callback identifier for the menu item.
  final String? route;

  /// Callback when the item is tapped.
  final VoidCallback? onTap;

  /// Whether this item is currently selected.
  final bool isSelected;

  /// Badge count to display.
  final int? badgeCount;

  const AppDrawerItem({
    required this.icon,
    required this.label,
    this.route,
    this.onTap,
    this.isSelected = false,
    this.badgeCount,
  });
}

/// A navigation drawer with menu items and optional header.
///
/// This is an organism-level widget that provides a consistent
/// navigation drawer layout.
///
/// Example:
/// ```dart
/// AppDrawer(
///   headerTitle: 'My App',
///   headerSubtitle: 'user@example.com',
///   items: [
///     AppDrawerItem(icon: Icons.home, label: 'Home', isSelected: true),
///     AppDrawerItem(icon: Icons.settings, label: 'Settings'),
///   ],
///   footerItems: [
///     AppDrawerItem(icon: Icons.logout, label: 'Logout'),
///   ],
/// )
/// ```
class AppDrawer extends ConsumerWidget {
  /// Title displayed in the header.
  final String? headerTitle;

  /// Subtitle displayed in the header.
  final String? headerSubtitle;

  /// Avatar widget to display in the header.
  final Widget? headerAvatar;

  /// Custom header widget (replaces default header).
  final Widget? customHeader;

  /// Navigation menu items.
  final List<AppDrawerItem> items;

  /// Footer menu items (displayed at the bottom).
  final List<AppDrawerItem>? footerItems;

  /// Callback when a menu item is tapped.
  final void Function(AppDrawerItem item)? onItemTap;

  /// Width of the drawer.
  final double? width;

  /// Whether to show the theme toggle in the drawer.
  final bool showThemeToggle;

  const AppDrawer({
    super.key,
    this.headerTitle,
    this.headerSubtitle,
    this.headerAvatar,
    this.customHeader,
    required this.items,
    this.footerItems,
    this.onItemTap,
    this.width,
    this.showThemeToggle = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    return Drawer(
      width: width,
      backgroundColor: colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            if (customHeader != null)
              customHeader!
            else if (headerTitle != null || headerAvatar != null)
              _buildHeader(context),

            // Main items - tighter padding
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                itemCount: items.length,
                itemBuilder: (context, index) =>
                    _buildMenuItem(context, items[index]),
              ),
            ),

            // Theme toggle
            if (showThemeToggle) ...[
              Divider(height: 1, color: colorScheme.outlineVariant),
              _buildThemeToggle(context, themeState, themeNotifier),
            ],

            // Footer items - tighter padding
            if (footerItems != null && footerItems!.isNotEmpty) ...[
              Divider(height: 1, color: colorScheme.outlineVariant),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Column(
                  children: footerItems!
                      .map((item) => _buildMenuItem(context, item))
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggle(
    BuildContext context,
    ThemeState state,
    ThemeNotifier notifier,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      // Tighter padding
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md, // 12dp
        vertical: 6,
      ),
      child: Row(
        children: [
          Icon(
            state.themeMode.icon,
            color: colorScheme.primary,
            size: 18, // Smaller icon
          ),
          AppSpacing.gapXs, // Tighter gap
          Text(
            'Theme',
            style: theme.textTheme.bodySmall,
          ),
          const Spacer(),
          SegmentedButton<AppThemeMode>(
            segments: AppThemeMode.values.map((mode) {
              return ButtonSegment<AppThemeMode>(
                value: mode,
                icon: Icon(mode.icon, size: 16),
                tooltip: mode.label,
              );
            }).toList(),
            selected: {state.themeMode},
            onSelectionChanged: (selected) {
              if (selected.isNotEmpty) {
                notifier.setTheme(selected.first);
              }
            },
            showSelectedIcon: false,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      // Tighter padding
      padding: const EdgeInsets.all(AppSpacing.md), // 12dp
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (headerAvatar != null) ...[
            headerAvatar!,
            AppSpacing.gapSm, // Tighter gap
          ],
          if (headerTitle != null)
            Text(
              headerTitle!,
              style: theme.textTheme.titleSmall?.copyWith( // Smaller title
                fontWeight: FontWeight.w600,
              ),
            ),
          if (headerSubtitle != null) ...[
            const SizedBox(height: 2), // Tighter gap
            Text(
              headerSubtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, AppDrawerItem item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      dense: true, // Enable dense mode for tighter layout
      visualDensity: VisualDensity.compact,
      leading: Icon(
        item.icon,
        size: 20, // Slightly smaller icon
        color: item.isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      title: Text(
        item.label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: item.isSelected ? colorScheme.primary : colorScheme.onSurface,
          fontWeight: item.isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: item.badgeCount != null && item.badgeCount! > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: colorScheme.error,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                item.badgeCount! > 99 ? '99+' : '${item.badgeCount}',
                style: TextStyle(
                  color: colorScheme.onError,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          : null,
      selected: item.isSelected,
      selectedTileColor: colorScheme.primary.withAlpha(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      // Tighter content padding
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md, // 12dp
        vertical: 2,
      ),
      onTap: () {
        item.onTap?.call();
        onItemTap?.call(item);
        Navigator.of(context).pop();
      },
    );
  }
}
