import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// A centered loading spinner widget.
///
/// This is a layout-level widget for displaying loading states.
///
/// Example:
/// ```dart
/// LoadingWidget(
///   message: 'Loading...',
/// )
/// ```
class LoadingWidget extends StatelessWidget {
  /// Optional message displayed below the spinner.
  final String? message;

  /// Color of the spinner.
  final Color? color;

  /// Size of the spinner.
  final double size;

  const LoadingWidget({
    super.key,
    this.message,
    this.color,
    this.size = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? AppColors.primary,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// An overlay that shows a loading indicator on top of content.
///
/// This is a layout-level widget that wraps content with an optional
/// loading overlay.
///
/// Example:
/// ```dart
/// LoadingOverlay(
///   isLoading: state.isLoading,
///   message: 'Processing...',
///   child: MyContent(),
/// )
/// ```
class LoadingOverlay extends StatelessWidget {
  /// Whether to show the loading overlay.
  final bool isLoading;

  /// The content to display behind the overlay.
  final Widget child;

  /// Optional message to display with the spinner.
  final String? message;

  /// Color of the overlay background.
  final Color? overlayColor;

  /// Color of the spinner.
  final Color? spinnerColor;

  /// Whether to block user interaction while loading.
  final bool blockInteraction;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.overlayColor,
    this.spinnerColor,
    this.blockInteraction = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !blockInteraction,
              child: Container(
                color: overlayColor ?? AppColors.black.withAlpha(128),
                child: LoadingWidget(
                  message: message,
                  color: spinnerColor ?? AppColors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A full screen loading state.
///
/// Example:
/// ```dart
/// if (state.isLoading) {
///   return LoadingScreen(message: 'Loading data...');
/// }
/// ```
class LoadingScreen extends StatelessWidget {
  /// Optional message to display.
  final String? message;

  /// Background color.
  final Color? backgroundColor;

  const LoadingScreen({
    super.key,
    this.message,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.background,
      body: LoadingWidget(message: message),
    );
  }
}
