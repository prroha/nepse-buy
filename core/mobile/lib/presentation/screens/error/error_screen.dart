import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../widgets/atoms/app_button.dart';
import '../../widgets/layout/error_page.dart';
import '../../router/routes.dart';

/// A screen displayed when a runtime error occurs (500-type errors).
///
/// This screen provides a user-friendly message and options to retry
/// or navigate away. In debug mode, it shows additional error details.
///
/// Example:
/// ```dart
/// MaterialApp(
///   builder: (context, child) {
///     ErrorWidget.builder = (FlutterErrorDetails details) {
///       return AppErrorScreen(
///         error: details.exception,
///         stackTrace: details.stack,
///         onRetry: () => Navigator.of(context).pushReplacement(...),
///       );
///     };
///     return child!;
///   },
/// )
/// ```
class AppErrorScreen extends StatefulWidget {
  /// The error that occurred.
  final Object? error;

  /// The stack trace of the error.
  final StackTrace? stackTrace;

  /// Callback to retry the failed operation.
  final VoidCallback? onRetry;

  /// Callback to navigate home.
  final VoidCallback? onGoHome;

  /// Custom error message to display.
  final String? customMessage;

  const AppErrorScreen({
    super.key,
    this.error,
    this.stackTrace,
    this.onRetry,
    this.onGoHome,
    this.customMessage,
  });

  @override
  State<AppErrorScreen> createState() => _AppErrorScreenState();
}

class _AppErrorScreenState extends State<AppErrorScreen> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    // In release mode, show a simple error page
    if (kReleaseMode) {
      return ErrorPage.serverError(
        onPrimaryAction: widget.onRetry,
        onSecondaryAction: widget.onGoHome ?? () => context.go(Routes.home),
      );
    }

    // In debug mode, show additional details
    return _buildDebugErrorScreen(context);
  }

  Widget _buildDebugErrorScreen(BuildContext context) {
    final colors = context.appColors;
    final textColor = colors.foreground;
    final secondaryTextColor = colors.mutedForeground;
    final backgroundColor = colors.background;
    final surfaceColor = colors.card;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppSpacing.gapXl,

              // Error icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bug_report_rounded,
                  size: 40,
                  color: AppColors.error,
                ),
              ),
              AppSpacing.gapLg,

              // Title
              Text(
                'Something Went Wrong',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.gapSm,

              // Message
              Text(
                widget.customMessage ??
                    'An unexpected error occurred. See details below.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: secondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.gapLg,

              // Error details toggle
              TextButton.icon(
                onPressed: () => setState(() => _showDetails = !_showDetails),
                icon: Icon(
                  _showDetails ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.primary,
                ),
                label: Text(
                  _showDetails ? 'Hide Details' : 'Show Details',
                  style: const TextStyle(color: AppColors.primary),
                ),
              ),

              // Error details
              if (_showDetails) ...[
                AppSpacing.gapMd,
                Container(
                  width: double.infinity,
                  padding: AppSpacing.cardContentPadding,
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: AppSpacing.borderRadiusMd,
                    border: Border.all(
                      color: colors.border,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Error type
                      Text(
                        'Error Type',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: secondaryTextColor,
                        ),
                      ),
                      AppSpacing.gapXs,
                      Text(
                        widget.error?.runtimeType.toString() ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'monospace',
                          color: AppColors.error,
                        ),
                      ),
                      AppSpacing.gapMd,

                      // Error message
                      Text(
                        'Message',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: secondaryTextColor,
                        ),
                      ),
                      AppSpacing.gapXs,
                      Text(
                        widget.error?.toString() ?? 'No message available',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'monospace',
                          color: textColor,
                        ),
                      ),

                      // Stack trace
                      if (widget.stackTrace != null) ...[
                        AppSpacing.gapMd,
                        Text(
                          'Stack Trace',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: secondaryTextColor,
                          ),
                        ),
                        AppSpacing.gapXs,
                        Container(
                          height: 200,
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.muted,
                            borderRadius: AppSpacing.borderRadiusSm,
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              widget.stackTrace.toString(),
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: secondaryTextColor,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              AppSpacing.gapXl,

              // Action buttons - Primary action should be most likely next step
              // If there's a retry option, that's usually what users want
              if (widget.onRetry != null) ...[
                AppButton(
                  label: 'Try Again',
                  onPressed: widget.onRetry,
                  variant: AppButtonVariant.primary,
                  isFullWidth: true,
                  icon: Icons.refresh_rounded,
                ),
                AppSpacing.gapSm,
                AppButton(
                  label: 'Go Home',
                  onPressed: widget.onGoHome ?? () => context.go(Routes.home),
                  variant: AppButtonVariant.outline,
                  isFullWidth: true,
                  icon: Icons.home_rounded,
                ),
              ] else ...[
                // No retry - Go Home becomes primary
                AppButton(
                  label: 'Go Home',
                  onPressed: widget.onGoHome ?? () => context.go(Routes.home),
                  variant: AppButtonVariant.primary,
                  isFullWidth: true,
                  icon: Icons.home_rounded,
                ),
              ],

              // Debug mode indicator
              AppSpacing.gapXl,
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: AppSpacing.borderRadiusSm,
                  border: Border.all(
                    color: AppColors.warning.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.developer_mode,
                      size: 16,
                      color: AppColors.warning,
                    ),
                    AppSpacing.gapHSm,
                    Text(
                      'Debug Mode',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapMd,
            ],
          ),
        ),
      ),
    );
  }
}

/// A compact error widget for use within other screens.
///
/// This is useful for showing errors in parts of a screen without
/// replacing the entire view.
class CompactErrorWidget extends StatelessWidget {
  /// The error message to display.
  final String message;

  /// Callback to retry the failed operation.
  final VoidCallback? onRetry;

  const CompactErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: AppSpacing.cardContentPadding,
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.1),
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: colors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 32,
            color: colors.error,
          ),
          AppSpacing.gapSm,
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: colors.foreground,
            ),
          ),
          if (onRetry != null) ...[
            AppSpacing.gapMd,
            AppButton(
              label: 'Retry',
              onPressed: onRetry,
              variant: AppButtonVariant.outline,
              size: AppButtonSize.small,
              icon: Icons.refresh_rounded,
            ),
          ],
        ],
      ),
    );
  }
}
