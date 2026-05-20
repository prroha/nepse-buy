import 'package:flutter/material.dart';

/// Icon size presets.
enum AppIconSize {
  /// Extra small icon (12px)
  xs,

  /// Small icon (16px)
  sm,

  /// Medium icon (24px) - default
  md,

  /// Large icon (32px)
  lg,

  /// Extra large icon (48px)
  xl,
}

/// Icon color presets.
enum AppIconColor {
  /// Primary brand color
  primary,

  /// Secondary brand color
  secondary,

  /// Success/positive state
  success,

  /// Warning state
  warning,

  /// Error/danger state
  error,

  /// Info state
  info,

  /// Primary text color
  textPrimary,

  /// Secondary/muted text color
  textSecondary,

  /// White color for dark backgrounds
  white,
}

/// A styled icon wrapper with size and color presets.
///
/// This is an atom-level widget that provides consistent icon styling
/// across the application. Uses Theme.of(context) for theme-aware colors.
///
/// Example:
/// ```dart
/// AppIcon(
///   Icons.home,
///   size: AppIconSize.lg,
///   color: AppIconColor.primary,
/// )
/// ```
class AppIcon extends StatelessWidget {
  /// The icon to display.
  final IconData icon;

  /// The size preset for the icon.
  final AppIconSize size;

  /// The color preset for the icon. If null, uses default icon color.
  final AppIconColor? colorPreset;

  /// Custom color that overrides the color preset.
  final Color? customColor;

  /// Semantic label for accessibility.
  final String? semanticLabel;

  const AppIcon(
    this.icon, {
    super.key,
    this.size = AppIconSize.md,
    this.colorPreset,
    this.customColor,
    this.semanticLabel,
  });

  /// Creates a primary colored icon.
  const AppIcon.primary(
    this.icon, {
    super.key,
    this.size = AppIconSize.md,
    this.semanticLabel,
  })  : colorPreset = AppIconColor.primary,
        customColor = null;

  /// Creates a success colored icon.
  const AppIcon.success(
    this.icon, {
    super.key,
    this.size = AppIconSize.md,
    this.semanticLabel,
  })  : colorPreset = AppIconColor.success,
        customColor = null;

  /// Creates an error colored icon.
  const AppIcon.error(
    this.icon, {
    super.key,
    this.size = AppIconSize.md,
    this.semanticLabel,
  })  : colorPreset = AppIconColor.error,
        customColor = null;

  /// Creates a warning colored icon.
  const AppIcon.warning(
    this.icon, {
    super.key,
    this.size = AppIconSize.md,
    this.semanticLabel,
  })  : colorPreset = AppIconColor.warning,
        customColor = null;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: _getSize(),
      color: _getColor(context),
      semanticLabel: semanticLabel,
    );
  }

  double _getSize() {
    switch (size) {
      case AppIconSize.xs:
        return 12;
      case AppIconSize.sm:
        return 16;
      case AppIconSize.md:
        return 24;
      case AppIconSize.lg:
        return 32;
      case AppIconSize.xl:
        return 48;
    }
  }

  Color? _getColor(BuildContext context) {
    if (customColor != null) return customColor;
    if (colorPreset == null) return null;

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (colorPreset!) {
      case AppIconColor.primary:
        return colorScheme.primary;
      case AppIconColor.secondary:
        return colorScheme.secondary;
      case AppIconColor.success:
        // Use a theme-aware success color
        return isDark ? const Color(0xFF22C55E) : const Color(0xFF16A34A);
      case AppIconColor.warning:
        return isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706);
      case AppIconColor.error:
        return colorScheme.error;
      case AppIconColor.info:
        return isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
      case AppIconColor.textPrimary:
        return colorScheme.onSurface;
      case AppIconColor.textSecondary:
        return colorScheme.onSurfaceVariant;
      case AppIconColor.white:
        return Colors.white;
    }
  }
}
