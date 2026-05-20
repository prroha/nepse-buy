import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';

/// Badge variants for different visual styles.
enum AppBadgeVariant {
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

  /// Neutral/gray state
  neutral,
}

/// Badge sizes.
enum AppBadgeSize {
  /// Small badge (compact)
  small,

  /// Medium badge (default)
  medium,
}

/// A badge widget for notifications, status indicators, and labels.
///
/// This is an atom-level widget that provides consistent badge styling
/// across the application.
///
/// Example:
/// ```dart
/// AppBadge(
///   label: 'New',
///   variant: AppBadgeVariant.success,
/// )
/// ```
class AppBadge extends StatelessWidget {
  /// The text label displayed in the badge. Can be null for dot badges.
  final String? label;

  /// The visual variant of the badge.
  final AppBadgeVariant variant;

  /// The size of the badge.
  final AppBadgeSize size;

  /// Whether to render as a dot (no label, circular).
  final bool isDot;

  /// Optional leading icon.
  final IconData? icon;

  const AppBadge({
    super.key,
    this.label,
    this.variant = AppBadgeVariant.primary,
    this.size = AppBadgeSize.medium,
    this.isDot = false,
    this.icon,
  });

  /// Creates a dot badge (typically for notification indicators).
  const AppBadge.dot({
    super.key,
    this.variant = AppBadgeVariant.error,
  })  : label = null,
        size = AppBadgeSize.small,
        isDot = true,
        icon = null;

  /// Creates a notification count badge.
  factory AppBadge.count(
    int count, {
    Key? key,
    AppBadgeVariant variant = AppBadgeVariant.error,
    int maxCount = 99,
  }) {
    final displayText = count > maxCount ? '$maxCount+' : '$count';
    return AppBadge(
      key: key,
      label: displayText,
      variant: variant,
      size: AppBadgeSize.small,
    );
  }

  /// Creates a status badge with an icon.
  const AppBadge.status(
    this.label, {
    super.key,
    this.variant = AppBadgeVariant.neutral,
    this.icon,
  })  : size = AppBadgeSize.medium,
        isDot = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDot) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: _getBackgroundColor(colorScheme, isDark),
          shape: BoxShape.circle,
        ),
      );
    }

    return Container(
      padding: _getPadding(),
      decoration: BoxDecoration(
        color: _getBackgroundColor(colorScheme, isDark),
        borderRadius: AppSpacing.borderRadiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: _getIconSize(),
              color: _getTextColor(colorScheme),
            ),
            if (label != null) SizedBox(width: size == AppBadgeSize.small ? 2 : 4),
          ],
          if (label != null)
            Text(
              label!,
              style: TextStyle(
                fontSize: _getFontSize(),
                fontWeight: FontWeight.w500,
                color: _getTextColor(colorScheme),
                height: 1,
              ),
            ),
        ],
      ),
    );
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case AppBadgeSize.small:
        return const EdgeInsets.symmetric(horizontal: 6, vertical: 2);
      case AppBadgeSize.medium:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
    }
  }

  double _getFontSize() {
    switch (size) {
      case AppBadgeSize.small:
        return 10;
      case AppBadgeSize.medium:
        return 12;
    }
  }

  double _getIconSize() {
    switch (size) {
      case AppBadgeSize.small:
        return 10;
      case AppBadgeSize.medium:
        return 12;
    }
  }

  Color _getBackgroundColor(ColorScheme colorScheme, bool isDark) {
    switch (variant) {
      case AppBadgeVariant.primary:
        return colorScheme.primary;
      case AppBadgeVariant.secondary:
        return colorScheme.secondary;
      case AppBadgeVariant.success:
        return isDark ? const Color(0xFF22C55E) : const Color(0xFF16A34A);
      case AppBadgeVariant.warning:
        return isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706);
      case AppBadgeVariant.error:
        return colorScheme.error;
      case AppBadgeVariant.info:
        return isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
      case AppBadgeVariant.neutral:
        return colorScheme.outlineVariant;
    }
  }

  Color _getTextColor(ColorScheme colorScheme) {
    switch (variant) {
      case AppBadgeVariant.neutral:
        return colorScheme.onSurfaceVariant;
      default:
        return Colors.white;
    }
  }
}
