import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Toast service provider for dependency injection
final toastServiceProvider = Provider<ToastService>((ref) => ToastService());

// =====================================================
// Toast Service
// =====================================================
//
// A service for showing toast notifications (snackbars) throughout the app.
// Provides consistent styling and behavior for success, error, warning, and info toasts.
//
// Usage:
//   // Get the service instance (typically via dependency injection)
//   final toastService = ToastService();
//
//   // Show toasts
//   toastService.showSuccess(context, 'Profile saved!');
//   toastService.showError(context, 'Failed to save');
//   toastService.showWarning(context, 'Session expires soon');
//   toastService.showInfo(context, 'New features available');
//
//   // With action button
//   toastService.showError(
//     context,
//     'Failed to save',
//     action: ToastAction(label: 'Retry', onPressed: () => retry()),
//   );
//
// Integration with Riverpod:
//   final toastServiceProvider = Provider<ToastService>((ref) => ToastService());
//
//   // In a widget
//   final toastService = ref.read(toastServiceProvider);
//   toastService.showSuccess(context, 'Done!');
// =====================================================

/// Toast variant types
enum ToastVariant {
  success,
  error,
  warning,
  info,
}

/// Configuration for toast action button
class ToastAction {
  final String label;
  final VoidCallback onPressed;

  const ToastAction({
    required this.label,
    required this.onPressed,
  });
}

/// Toast service for showing snackbar notifications
class ToastService {
  /// Default duration for toasts in milliseconds
  static const int defaultDuration = 4000;

  /// Duration for error toasts (longer to ensure user sees it)
  static const int errorDuration = 6000;

  /// Shows a success toast
  ///
  /// [context] - Build context for showing the snackbar
  /// [message] - Main message to display
  /// [description] - Optional secondary message
  /// [duration] - Duration in milliseconds (default: 4000)
  /// [action] - Optional action button
  void showSuccess(
    BuildContext context,
    String message, {
    String? description,
    int? duration,
    ToastAction? action,
  }) {
    _showToast(
      context,
      message: message,
      description: description,
      variant: ToastVariant.success,
      duration: duration ?? defaultDuration,
      action: action,
    );
  }

  /// Shows an error toast
  ///
  /// [context] - Build context for showing the snackbar
  /// [message] - Main message to display
  /// [description] - Optional secondary message
  /// [duration] - Duration in milliseconds (default: 6000 for errors)
  /// [action] - Optional action button (e.g., "Retry")
  void showError(
    BuildContext context,
    String message, {
    String? description,
    int? duration,
    ToastAction? action,
  }) {
    _showToast(
      context,
      message: message,
      description: description,
      variant: ToastVariant.error,
      duration: duration ?? errorDuration,
      action: action,
    );
  }

  /// Shows a warning toast
  ///
  /// [context] - Build context for showing the snackbar
  /// [message] - Main message to display
  /// [description] - Optional secondary message
  /// [duration] - Duration in milliseconds (default: 4000)
  /// [action] - Optional action button
  void showWarning(
    BuildContext context,
    String message, {
    String? description,
    int? duration,
    ToastAction? action,
  }) {
    _showToast(
      context,
      message: message,
      description: description,
      variant: ToastVariant.warning,
      duration: duration ?? defaultDuration,
      action: action,
    );
  }

  /// Shows an info toast
  ///
  /// [context] - Build context for showing the snackbar
  /// [message] - Main message to display
  /// [description] - Optional secondary message
  /// [duration] - Duration in milliseconds (default: 4000)
  /// [action] - Optional action button
  void showInfo(
    BuildContext context,
    String message, {
    String? description,
    int? duration,
    ToastAction? action,
  }) {
    _showToast(
      context,
      message: message,
      description: description,
      variant: ToastVariant.info,
      duration: duration ?? defaultDuration,
      action: action,
    );
  }

  /// Hides any currently visible toast
  void hide(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  /// Internal method to show a toast
  void _showToast(
    BuildContext context, {
    required String message,
    String? description,
    required ToastVariant variant,
    required int duration,
    ToastAction? action,
  }) {
    // Clear any existing snackbar before showing new one
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final colors = _getVariantColors(variant, context);
    final icon = _getVariantIcon(variant);

    final snackBar = SnackBar(
      content: Row(
        children: [
          // Icon
          Icon(
            icon,
            color: colors.foreground,
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
                    color: colors.foreground,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      color: colors.foreground.withAlpha(200),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      backgroundColor: colors.background,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      margin: const EdgeInsets.all(AppSpacing.md),
      duration: Duration(milliseconds: duration),
      action: action != null
          ? SnackBarAction(
              label: action.label,
              textColor: colors.foreground,
              onPressed: action.onPressed,
            )
          : null,
      dismissDirection: DismissDirection.horizontal,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Gets colors for each toast variant
  _ToastColors _getVariantColors(ToastVariant variant, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (variant) {
      case ToastVariant.success:
        return _ToastColors(
          background: isDark ? const Color(0xFF166534) : AppColors.success,
          foreground: AppColors.white,
        );
      case ToastVariant.error:
        return _ToastColors(
          background: isDark ? const Color(0xFF991B1B) : AppColors.error,
          foreground: AppColors.white,
        );
      case ToastVariant.warning:
        return _ToastColors(
          background: isDark ? const Color(0xFFB45309) : AppColors.warning,
          foreground: AppColors.white,
        );
      case ToastVariant.info:
        return _ToastColors(
          background: isDark ? const Color(0xFF1D4ED8) : AppColors.info,
          foreground: AppColors.white,
        );
    }
  }

  /// Gets icon for each toast variant
  IconData _getVariantIcon(ToastVariant variant) {
    switch (variant) {
      case ToastVariant.success:
        return Icons.check_circle_outline;
      case ToastVariant.error:
        return Icons.error_outline;
      case ToastVariant.warning:
        return Icons.warning_amber_outlined;
      case ToastVariant.info:
        return Icons.info_outline;
    }
  }
}

/// Internal class for toast colors
class _ToastColors {
  final Color background;
  final Color foreground;

  const _ToastColors({
    required this.background,
    required this.foreground,
  });
}
