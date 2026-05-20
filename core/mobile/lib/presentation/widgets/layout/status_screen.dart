import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../atoms/app_button.dart';

/// Variant for status screen styling.
enum StatusScreenVariant {
  /// Loading state with spinner
  loading,

  /// Success state with check icon
  success,

  /// Error state with warning icon
  error,

  /// Info state with info icon
  info,
}

/// A full-screen status display for loading, success, error, and info states.
///
/// Provides consistent status screen layout with:
/// - Themed icon with circular background
/// - Title and message text
/// - Optional primary and secondary actions
///
/// Example:
/// ```dart
/// StatusScreen.loading(
///   title: 'Verifying your email...',
///   message: 'Please wait while we verify your email address.',
/// )
///
/// StatusScreen.success(
///   title: 'Email verified!',
///   message: 'Your email has been verified successfully.',
///   primaryActionLabel: 'Go to dashboard',
///   onPrimaryAction: () => context.go(Routes.home),
/// )
/// ```
class StatusScreen extends StatelessWidget {
  /// The variant that controls icon and colors.
  final StatusScreenVariant variant;

  /// The title text.
  final String title;

  /// The message/description text.
  final String? message;

  /// Optional custom icon. If null, uses default based on variant.
  final IconData? icon;

  /// Label for the primary action button.
  final String? primaryActionLabel;

  /// Callback for the primary action.
  final VoidCallback? onPrimaryAction;

  /// Label for the secondary action (displayed as a TextButton).
  final String? secondaryActionLabel;

  /// Callback for the secondary action.
  final VoidCallback? onSecondaryAction;

  /// Optional additional content below the actions.
  final Widget? bottomWidget;

  /// Whether the screen should use a Scaffold.
  final bool useScaffold;

  const StatusScreen({
    super.key,
    required this.variant,
    required this.title,
    this.message,
    this.icon,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.bottomWidget,
    this.useScaffold = true,
  });

  /// Creates a loading status screen.
  const StatusScreen.loading({
    super.key,
    required this.title,
    this.message,
    this.bottomWidget,
    this.useScaffold = true,
  })  : variant = StatusScreenVariant.loading,
        icon = null,
        primaryActionLabel = null,
        onPrimaryAction = null,
        secondaryActionLabel = null,
        onSecondaryAction = null;

  /// Creates a success status screen.
  const StatusScreen.success({
    super.key,
    required this.title,
    this.message,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.bottomWidget,
    this.useScaffold = true,
  })  : variant = StatusScreenVariant.success,
        icon = Icons.check_circle_outline;

  /// Creates an error status screen.
  const StatusScreen.error({
    super.key,
    required this.title,
    this.message,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.bottomWidget,
    this.useScaffold = true,
  })  : variant = StatusScreenVariant.error,
        icon = Icons.warning_amber_rounded;

  /// Creates an info status screen.
  const StatusScreen.info({
    super.key,
    required this.title,
    this.message,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.bottomWidget,
    this.useScaffold = true,
  })  : variant = StatusScreenVariant.info,
        icon = Icons.info_outline;

  Color _getIconColor(ColorScheme colorScheme) {
    switch (variant) {
      case StatusScreenVariant.loading:
        return colorScheme.primary;
      case StatusScreenVariant.success:
        return Colors.green;
      case StatusScreenVariant.error:
        return colorScheme.error;
      case StatusScreenVariant.info:
        return colorScheme.primary;
    }
  }

  Color _getBackgroundColor(ColorScheme colorScheme) {
    switch (variant) {
      case StatusScreenVariant.loading:
        return colorScheme.primary.withAlpha(25);
      case StatusScreenVariant.success:
        return Colors.green.withAlpha(25);
      case StatusScreenVariant.error:
        return colorScheme.error.withAlpha(25);
      case StatusScreenVariant.info:
        return colorScheme.primary.withAlpha(25);
    }
  }

  IconData _getDefaultIcon() {
    switch (variant) {
      case StatusScreenVariant.loading:
        return Icons.hourglass_empty; // Not used, spinner shown instead
      case StatusScreenVariant.success:
        return Icons.check_circle_outline;
      case StatusScreenVariant.error:
        return Icons.warning_amber_rounded;
      case StatusScreenVariant.info:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);

    if (!useScaffold) {
      return content;
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: content,
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = _getIconColor(colorScheme);
    final backgroundColor = _getBackgroundColor(colorScheme);
    final effectiveIcon = icon ?? _getDefaultIcon();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icon/Spinner
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: variant == StatusScreenVariant.loading
                    ? Center(
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                          ),
                        ),
                      )
                    : Icon(
                        effectiveIcon,
                        color: iconColor,
                        size: 32,
                      ),
              ),
            ),
            AppSpacing.gapLg,

            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            // Message
            if (message != null) ...[
              AppSpacing.gapSm,
              Text(
                message!,
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // Primary Action
            if (primaryActionLabel != null && onPrimaryAction != null) ...[
              AppSpacing.gapXl,
              AppButton(
                label: primaryActionLabel!,
                onPressed: onPrimaryAction,
                isFullWidth: true,
              ),
            ],

            // Secondary Action
            if (secondaryActionLabel != null && onSecondaryAction != null) ...[
              AppSpacing.gapMd,
              TextButton(
                onPressed: onSecondaryAction,
                child: Text(
                  secondaryActionLabel!,
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],

            // Bottom Widget
            if (bottomWidget != null) ...[
              AppSpacing.gapMd,
              bottomWidget!,
            ],
          ],
        ),
      ),
    );
  }
}

/// A compact status view that can be embedded within other screens.
///
/// Similar to StatusScreen but without the scaffold wrapper.
/// Useful for displaying status within cards or other containers.
///
/// Example:
/// ```dart
/// if (isLoading)
///   StatusView.loading(
///     title: 'Processing...',
///   )
/// else if (hasError)
///   StatusView.error(
///     title: 'Something went wrong',
///     message: errorMessage,
///     onRetry: () => retry(),
///   )
/// ```
class StatusView extends StatelessWidget {
  /// The variant that controls icon and colors.
  final StatusScreenVariant variant;

  /// The title text.
  final String title;

  /// The message/description text.
  final String? message;

  /// Optional custom icon.
  final IconData? icon;

  /// Callback for retry action (shows a retry button).
  final VoidCallback? onRetry;

  /// Label for the retry button.
  final String retryLabel;

  const StatusView({
    super.key,
    required this.variant,
    required this.title,
    this.message,
    this.icon,
    this.onRetry,
    this.retryLabel = 'Retry',
  });

  /// Creates a loading status view.
  const StatusView.loading({
    super.key,
    required this.title,
    this.message,
  })  : variant = StatusScreenVariant.loading,
        icon = null,
        onRetry = null,
        retryLabel = 'Retry';

  /// Creates an error status view with optional retry.
  const StatusView.error({
    super.key,
    required this.title,
    this.message,
    this.onRetry,
    this.retryLabel = 'Retry',
  })  : variant = StatusScreenVariant.error,
        icon = Icons.error_outline;

  @override
  Widget build(BuildContext context) {
    return StatusScreen(
      variant: variant,
      title: title,
      message: message,
      icon: icon,
      primaryActionLabel: onRetry != null ? retryLabel : null,
      onPrimaryAction: onRetry,
      useScaffold: false,
    );
  }
}
