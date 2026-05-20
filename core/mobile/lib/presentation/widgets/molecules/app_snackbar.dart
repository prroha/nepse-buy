import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

// =====================================================
// App Snackbar Widget
// =====================================================
//
// A styled snackbar widget following the app's design system.
// Supports success, error, warning, and info variants with
// consistent styling and dark mode support.
//
// This widget is typically used via ToastService, but can also
// be used directly when you need more control over the snackbar.
//
// Usage:
//   // Using the static method
//   AppSnackbar.show(
//     context,
//     message: 'Profile saved!',
//     variant: SnackbarVariant.success,
//   );
//
//   // With action
//   AppSnackbar.show(
//     context,
//     message: 'Failed to save',
//     variant: SnackbarVariant.error,
//     action: SnackBarAction(
//       label: 'Retry',
//       onPressed: () => retry(),
//     ),
//   );
//
// For most use cases, prefer using ToastService which provides
// a simpler API and handles common patterns.
// =====================================================

/// Snackbar variant types
enum SnackbarVariant {
  success,
  error,
  warning,
  info,
}

/// App-styled snackbar widget
class AppSnackbar {
  /// Shows a styled snackbar with the given message and variant
  ///
  /// [context] - Build context for showing the snackbar
  /// [message] - Main message to display
  /// [description] - Optional secondary message
  /// [variant] - Visual variant (success, error, warning, info)
  /// [duration] - Duration to show the snackbar
  /// [action] - Optional action button
  /// [onDismissed] - Callback when snackbar is dismissed
  static void show(
    BuildContext context, {
    required String message,
    String? description,
    SnackbarVariant variant = SnackbarVariant.info,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
    VoidCallback? onDismissed,
  }) {
    // Clear any existing snackbar
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = _getVariantColors(variant, isDark, theme.colorScheme);
    final icon = _getVariantIcon(variant);

    final snackBar = SnackBar(
      content: _SnackbarContent(
        message: message,
        description: description,
        icon: icon,
        foregroundColor: colors.foreground,
      ),
      backgroundColor: colors.background,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusSm, // Tighter radius
      ),
      margin: const EdgeInsets.all(AppSpacing.md), // 12dp
      // Tighter padding
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md, // 12dp
        vertical: 10,
      ),
      duration: duration,
      action: action != null
          ? SnackBarAction(
              label: action.label,
              textColor: colors.foreground,
              onPressed: action.onPressed,
            )
          : null,
      dismissDirection: DismissDirection.horizontal,
      onVisible: () {},
    );

    ScaffoldMessenger.of(context)
        .showSnackBar(snackBar)
        .closed
        .then((reason) {
      if (onDismissed != null) {
        onDismissed();
      }
    });
  }

  /// Shows a success snackbar
  static void success(
    BuildContext context,
    String message, {
    String? description,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    show(
      context,
      message: message,
      description: description,
      variant: SnackbarVariant.success,
      duration: duration,
      action: action,
    );
  }

  /// Shows an error snackbar
  static void error(
    BuildContext context,
    String message, {
    String? description,
    Duration duration = const Duration(seconds: 6),
    SnackBarAction? action,
  }) {
    show(
      context,
      message: message,
      description: description,
      variant: SnackbarVariant.error,
      duration: duration,
      action: action,
    );
  }

  /// Shows a warning snackbar
  static void warning(
    BuildContext context,
    String message, {
    String? description,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    show(
      context,
      message: message,
      description: description,
      variant: SnackbarVariant.warning,
      duration: duration,
      action: action,
    );
  }

  /// Shows an info snackbar
  static void info(
    BuildContext context,
    String message, {
    String? description,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    show(
      context,
      message: message,
      description: description,
      variant: SnackbarVariant.info,
      duration: duration,
      action: action,
    );
  }

  /// Hides the current snackbar
  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  /// Gets colors for each variant
  static _SnackbarColors _getVariantColors(SnackbarVariant variant, bool isDark, ColorScheme colorScheme) {
    switch (variant) {
      case SnackbarVariant.success:
        return _SnackbarColors(
          background: isDark ? const Color(0xFF166534) : const Color(0xFF16A34A),
          foreground: Colors.white,
        );
      case SnackbarVariant.error:
        return _SnackbarColors(
          background: isDark ? const Color(0xFF991B1B) : colorScheme.error,
          foreground: Colors.white,
        );
      case SnackbarVariant.warning:
        return _SnackbarColors(
          background: isDark ? const Color(0xFFB45309) : const Color(0xFFD97706),
          foreground: Colors.white,
        );
      case SnackbarVariant.info:
        return _SnackbarColors(
          background: isDark ? const Color(0xFF1D4ED8) : const Color(0xFF0284C7),
          foreground: Colors.white,
        );
    }
  }

  /// Gets icon for each variant
  static IconData _getVariantIcon(SnackbarVariant variant) {
    switch (variant) {
      case SnackbarVariant.success:
        return Icons.check_circle_outline;
      case SnackbarVariant.error:
        return Icons.error_outline;
      case SnackbarVariant.warning:
        return Icons.warning_amber_outlined;
      case SnackbarVariant.info:
        return Icons.info_outline;
    }
  }
}

/// Internal snackbar content widget
class _SnackbarContent extends StatelessWidget {
  final String message;
  final String? description;
  final IconData icon;
  final Color foregroundColor;

  const _SnackbarContent({
    required this.message,
    this.description,
    required this.icon,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Icon
        Icon(
          icon,
          color: foregroundColor,
          size: 20,
        ),
        AppSpacing.gapHSm,
        // Message content
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: TextStyle(
                  color: foregroundColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              if (description != null) ...[
                const SizedBox(height: 2),
                Text(
                  description!,
                  style: TextStyle(
                    color: foregroundColor.withAlpha(200),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Internal class for snackbar colors
class _SnackbarColors {
  final Color background;
  final Color foreground;

  const _SnackbarColors({
    required this.background,
    required this.foreground,
  });
}
