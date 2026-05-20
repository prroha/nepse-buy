import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/theme_provider.dart';
import '../../../core/theme/app_spacing.dart';

/// Theme toggle variant
enum ThemeToggleVariant {
  /// Simple icon button toggle
  icon,

  /// Segmented button with all options
  segmented,

  /// List tile for settings
  listTile,

  /// Switch toggle
  switchToggle,
}

/// Theme toggle widget for switching between light, dark, and system themes
class ThemeToggle extends ConsumerWidget {
  /// The variant of the toggle to display
  final ThemeToggleVariant variant;

  /// Size of the icon for icon variant
  final double iconSize;

  /// Whether to show labels (for segmented variant)
  final bool showLabels;

  const ThemeToggle({
    super.key,
    this.variant = ThemeToggleVariant.icon,
    this.iconSize = 24,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (variant) {
      case ThemeToggleVariant.icon:
        return _buildIconToggle(context, themeNotifier, isDark);

      case ThemeToggleVariant.segmented:
        return _buildSegmentedToggle(context, themeState, themeNotifier);

      case ThemeToggleVariant.listTile:
        return _buildListTileToggle(context, themeState, themeNotifier);

      case ThemeToggleVariant.switchToggle:
        return _buildSwitchToggle(context, themeState, themeNotifier, isDark);
    }
  }

  Widget _buildIconToggle(
    BuildContext context,
    ThemeNotifier notifier,
    bool isDark,
  ) {
    return IconButton(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return RotationTransition(
            turns: animation,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        child: Icon(
          isDark ? Icons.light_mode : Icons.dark_mode,
          key: ValueKey(isDark),
          size: iconSize,
        ),
      ),
      onPressed: () => notifier.toggleTheme(context),
      tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
    );
  }

  Widget _buildSegmentedToggle(
    BuildContext context,
    ThemeState state,
    ThemeNotifier notifier,
  ) {
    return SegmentedButton<AppThemeMode>(
      segments: AppThemeMode.values.map((mode) {
        return ButtonSegment<AppThemeMode>(
          value: mode,
          icon: Icon(mode.icon),
          label: showLabels ? Text(mode.label) : null,
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
    );
  }

  Widget _buildListTileToggle(
    BuildContext context,
    ThemeState state,
    ThemeNotifier notifier,
  ) {
    return Column(
      children: [
        ListTile(
          leading: Icon(
            state.themeMode.icon,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: const Text('Theme'),
          subtitle: Text(state.themeMode.label),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showThemeDialog(context, state, notifier),
        ),
      ],
    );
  }

  Widget _buildSwitchToggle(
    BuildContext context,
    ThemeState state,
    ThemeNotifier notifier,
    bool isDark,
  ) {
    return SwitchListTile(
      secondary: Icon(
        isDark ? Icons.dark_mode : Icons.light_mode,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: const Text('Dark Mode'),
      subtitle: Text(
        state.themeMode == AppThemeMode.system
            ? 'Following system'
            : (isDark ? 'On' : 'Off'),
      ),
      value: isDark,
      onChanged: (value) {
        notifier.setTheme(value ? AppThemeMode.dark : AppThemeMode.light);
      },
    );
  }

  void _showThemeDialog(
    BuildContext context,
    ThemeState state,
    ThemeNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: AppThemeMode.values.map((mode) {
              return RadioListTile<AppThemeMode>(
                title: Row(
                  children: [
                    Icon(mode.icon),
                    AppSpacing.gapSm,
                    Text(mode.label),
                  ],
                ),
                value: mode,
                groupValue: state.themeMode,
                onChanged: (value) {
                  if (value != null) {
                    notifier.setTheme(value);
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
        );
      },
    );
  }
}

/// A simple theme toggle button that just toggles between light and dark
class ThemeToggleButton extends ConsumerWidget {
  /// Size of the button
  final double size;

  /// Background color of the button
  final Color? backgroundColor;

  const ThemeToggleButton({
    super.key,
    this.size = 48,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeNotifier = ref.read(themeProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: backgroundColor ?? colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(size / 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(size / 2),
        onTap: () => themeNotifier.toggleTheme(context),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: child,
                );
              },
              child: Icon(
                isDark ? Icons.light_mode : Icons.dark_mode,
                key: ValueKey(isDark),
                size: size * 0.5,
                color: isDark
                    ? const Color(0xFFF59E0B) // Warning color for light mode icon
                    : colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Theme mode selector for settings pages
class ThemeModeSelector extends ConsumerWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Appearance',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ...AppThemeMode.values.map((mode) {
          final isSelected = themeState.themeMode == mode;
          return ListTile(
            leading: Icon(
              mode.icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            title: Text(mode.label),
            trailing: isSelected
                ? Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            selected: isSelected,
            onTap: () => themeNotifier.setTheme(mode),
          );
        }),
      ],
    );
  }
}
