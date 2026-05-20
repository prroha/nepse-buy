import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../providers/theme_provider.dart';

/// Theme selector widget for choosing app color themes
///
/// This widget displays all available app theme types with their
/// primary and accent colors, allowing users to preview and select themes.
class ThemeSelector extends ConsumerWidget {
  /// Optional callback when theme changes
  final VoidCallback? onThemeChanged;

  /// Whether to show the theme name
  final bool showName;

  /// Whether to show the theme description
  final bool showDescription;

  /// Layout direction for theme options
  final Axis direction;

  /// Spacing between theme options
  final double spacing;

  /// Size of the color preview circles
  final double colorPreviewSize;

  const ThemeSelector({
    super.key,
    this.onThemeChanged,
    this.showName = true,
    this.showDescription = true,
    this.direction = Axis.vertical,
    this.spacing = 12.0,
    this.colorPreviewSize = 24.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    if (direction == Axis.horizontal) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          children: AppThemeType.values
              .map((theme) => Padding(
                    padding: EdgeInsets.only(right: spacing),
                    child: _ThemeOption(
                      theme: theme,
                      isSelected: themeState.appTheme == theme,
                      showName: showName,
                      showDescription: false,
                      colorPreviewSize: colorPreviewSize,
                      compact: true,
                      onTap: () {
                        themeNotifier.setAppTheme(theme);
                        onThemeChanged?.call();
                      },
                    ),
                  ))
              .toList(),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: AppThemeType.values.length,
      separatorBuilder: (context, index) => SizedBox(height: spacing),
      itemBuilder: (context, index) {
        final theme = AppThemeType.values[index];
        final isSelected = themeState.appTheme == theme;

        return _ThemeOption(
          theme: theme,
          isSelected: isSelected,
          showName: showName,
          showDescription: showDescription,
          colorPreviewSize: colorPreviewSize,
          compact: false,
          onTap: () {
            themeNotifier.setAppTheme(theme);
            onThemeChanged?.call();
          },
        );
      },
    );
  }
}

/// Individual theme option widget
class _ThemeOption extends StatelessWidget {
  final AppThemeType theme;
  final bool isSelected;
  final bool showName;
  final bool showDescription;
  final double colorPreviewSize;
  final bool compact;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.theme,
    required this.isSelected,
    required this.showName,
    required this.showDescription,
    required this.colorPreviewSize,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (compact) {
      return _buildCompactOption(context, colorScheme);
    }

    return _buildFullOption(context, colorScheme);
  }

  Widget _buildCompactOption(BuildContext context, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ColorPreview(
              primaryColor: theme.primaryColor,
              accentColor: theme.accentColor,
              size: colorPreviewSize,
            ),
            if (showName) ...[
              const SizedBox(height: 8),
              Text(
                theme.displayName,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            if (isSelected) ...[
              const SizedBox(height: 4),
              Icon(
                Icons.check_circle,
                size: 16,
                color: colorScheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFullOption(BuildContext context, ColorScheme colorScheme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer.withAlpha(128)
                : colorScheme.surfaceContainerHighest.withAlpha(128),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? colorScheme.primary : colorScheme.outline.withAlpha(50),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              _ColorPreview(
                primaryColor: theme.primaryColor,
                accentColor: theme.accentColor,
                size: colorPreviewSize,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showName)
                      Text(
                        theme.displayName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                      ),
                    if (showDescription) ...[
                      const SizedBox(height: 4),
                      Text(
                        theme.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isSelected ? 1.0 : 0.0,
                child: Icon(
                  Icons.check_circle,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Color preview widget showing primary and accent colors
class _ColorPreview extends StatelessWidget {
  final Color primaryColor;
  final Color accentColor;
  final double size;

  const _ColorPreview({
    required this.primaryColor,
    required this.accentColor,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.6,
      height: size,
      child: Stack(
        children: [
          // Primary color circle
          Positioned(
            left: 0,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withAlpha(100),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          // Accent color circle (overlapping)
          Positioned(
            left: size * 0.6,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withAlpha(100),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Theme selector dialog for use in settings
class ThemeSelectorDialog extends ConsumerWidget {
  const ThemeSelectorDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Text('Choose Theme'),
      content: SizedBox(
        width: double.maxFinite,
        child: ThemeSelector(
          onThemeChanged: () => Navigator.of(context).pop(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  /// Show the theme selector dialog
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const ThemeSelectorDialog(),
    );
  }
}

/// Compact theme selector for inline use
class CompactThemeSelector extends ConsumerWidget {
  /// Optional callback when theme changes
  final VoidCallback? onThemeChanged;

  const CompactThemeSelector({
    super.key,
    this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppThemeType.values.map((theme) {
        final isSelected = themeState.appTheme == theme;
        return _CompactThemeChip(
          theme: theme,
          isSelected: isSelected,
          onTap: () {
            themeNotifier.setAppTheme(theme);
            onThemeChanged?.call();
          },
        );
      }).toList(),
    );
  }
}

class _CompactThemeChip extends StatelessWidget {
  final AppThemeType theme;
  final bool isSelected;
  final VoidCallback onTap;

  const _CompactThemeChip({
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: theme.primaryColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: theme.accentColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              theme.displayName,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.check,
                size: 16,
                color: colorScheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Theme mode and app theme combined selector for settings
class FullThemeSelector extends ConsumerWidget {
  const FullThemeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Color Mode Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Color Mode',
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
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            title: Text(mode.label),
            trailing: isSelected
                ? Icon(Icons.check_circle, color: colorScheme.primary)
                : null,
            selected: isSelected,
            onTap: () => themeNotifier.setThemeMode(mode),
          );
        }),
        const Divider(height: 32),
        // App Theme Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'App Theme',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ThemeSelector(
            showDescription: true,
          ),
        ),
      ],
    );
  }
}
