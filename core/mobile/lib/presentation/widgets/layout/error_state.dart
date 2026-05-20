import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../atoms/app_button.dart';

/// An error state widget with retry functionality.
///
/// This is a layout-level widget for displaying error states with
/// optional retry action.
///
/// Example:
/// ```dart
/// ErrorState(
///   message: 'Failed to load data',
///   onRetry: () => refetch(),
/// )
/// ```
class ErrorState extends StatelessWidget {
  /// The error message to display.
  final String message;

  /// Callback when the retry button is pressed.
  final VoidCallback? onRetry;

  /// Label for the retry button.
  final String retryLabel;

  /// The icon to display.
  final IconData icon;

  /// Icon size.
  final double iconSize;

  /// Optional title text.
  final String? title;

  /// Optional secondary action label.
  final String? secondaryActionLabel;

  /// Callback for secondary action.
  final VoidCallback? onSecondaryAction;

  /// Optional custom illustration widget.
  final Widget? illustration;

  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Retry',
    this.icon = Icons.error_outline,
    this.iconSize = 64,
    this.title,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.illustration,
  });

  /// Creates an error state for network errors.
  const ErrorState.network({
    super.key,
    this.message = 'Unable to connect. Please check your internet connection.',
    this.onRetry,
    this.retryLabel = 'Try again',
  })  : icon = Icons.wifi_off,
        iconSize = 64,
        title = 'Connection error',
        secondaryActionLabel = null,
        onSecondaryAction = null,
        illustration = null;

  /// Creates an error state for server errors.
  const ErrorState.server({
    super.key,
    this.message = 'Something went wrong on our end. Please try again later.',
    this.onRetry,
    this.retryLabel = 'Retry',
  })  : icon = Icons.cloud_off,
        iconSize = 64,
        title = 'Server error',
        secondaryActionLabel = null,
        onSecondaryAction = null,
        illustration = null;

  /// Creates an error state for permission errors.
  const ErrorState.permission({
    super.key,
    this.message = 'You do not have permission to access this resource.',
    this.onRetry,
    this.retryLabel = 'Go back',
  })  : icon = Icons.lock_outline,
        iconSize = 64,
        title = 'Access denied',
        secondaryActionLabel = null,
        onSecondaryAction = null,
        illustration = null;

  /// Creates an error state for not found errors.
  const ErrorState.notFound({
    super.key,
    this.message = 'The requested resource could not be found.',
    this.onRetry,
    this.retryLabel = 'Go back',
  })  : icon = Icons.find_in_page_outlined,
        iconSize = 64,
        title = 'Not found',
        secondaryActionLabel = null,
        onSecondaryAction = null,
        illustration = null;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBackgroundColor = colorScheme.error.withAlpha(isDark ? 26 : 13);

    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Illustration or icon with background
            if (illustration != null)
              illustration!
            else
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: iconSize * 0.6,
                  color: colorScheme.error,
                ),
              ),
            AppSpacing.gapLg,

            // Title
            if (title != null) ...[
              Text(
                title!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              AppSpacing.gapSm,
            ],

            // Message
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),

            // Retry button
            if (onRetry != null) ...[
              AppSpacing.gapLg,
              AppButton(
                label: retryLabel,
                onPressed: onRetry,
                variant: AppButtonVariant.outline,
                icon: Icons.refresh,
              ),
            ],

            // Secondary action
            if (secondaryActionLabel != null && onSecondaryAction != null) ...[
              AppSpacing.gapSm,
              AppButton(
                label: secondaryActionLabel!,
                onPressed: onSecondaryAction,
                variant: AppButtonVariant.text,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Full screen error widget.
///
/// Example:
/// ```dart
/// ErrorScreen(
///   message: 'Something went wrong',
///   onRetry: () => refetch(),
/// )
/// ```
class ErrorScreen extends StatelessWidget {
  /// The error message to display.
  final String message;

  /// Callback when the retry button is pressed.
  final VoidCallback? onRetry;

  /// Label for the retry button.
  final String retryLabel;

  /// Optional title text.
  final String? title;

  /// The icon to display.
  final IconData icon;

  /// Background color.
  final Color? backgroundColor;

  const ErrorScreen({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Retry',
    this.title,
    this.icon = Icons.error_outline,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: backgroundColor ?? colorScheme.surface,
      body: ErrorState(
        message: message,
        onRetry: onRetry,
        retryLabel: retryLabel,
        title: title,
        icon: icon,
      ),
    );
  }
}

/// Backwards-compatible widget wrapper for ErrorState.
///
/// This provides a simpler API matching the old ErrorStateWidget usage.
///
/// Example:
/// ```dart
/// ErrorStateWidget(
///   message: 'Failed to load data',
///   onRetry: () => refetch(),
/// )
/// ```
class ErrorStateWidget extends StatelessWidget {
  /// The error message to display.
  final String message;

  /// Callback when the retry button is pressed.
  final VoidCallback? onRetry;

  const ErrorStateWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      message: message,
      onRetry: onRetry,
    );
  }
}
