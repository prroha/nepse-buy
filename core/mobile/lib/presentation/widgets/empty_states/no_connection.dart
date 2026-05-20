import 'package:flutter/material.dart';
import '../layout/empty_state.dart';

/// Empty state for connection/network issues.
///
/// Use this when the app is offline or a network request fails
/// due to connectivity issues.
///
/// Example:
/// ```dart
/// NoConnection(
///   onRetry: () => fetchData(),
/// )
/// ```
class NoConnection extends StatelessWidget {
  /// Callback when retry button is pressed.
  final VoidCallback? onRetry;

  /// Label for the retry button.
  final String retryLabel;

  /// Title to display.
  final String title;

  /// Optional description message.
  final String? message;

  /// Whether to show cached data hint.
  final bool showCachedDataHint;

  const NoConnection({
    super.key,
    this.onRetry,
    this.retryLabel = 'Try again',
    this.title = 'No internet connection',
    this.message,
    this.showCachedDataHint = false,
  });

  /// Creates a connection error state with sync hint.
  const NoConnection.withSyncHint({
    super.key,
    this.onRetry,
    this.retryLabel = 'Retry',
  })  : title = 'No internet connection',
        message = 'Your changes will sync automatically once you\'re back online.',
        showCachedDataHint = true;

  /// Creates a server connection error state.
  const NoConnection.serverError({
    super.key,
    this.onRetry,
    this.retryLabel = 'Retry',
  })  : title = 'Connection failed',
        message = 'Unable to connect to the server. Please check your connection and try again.',
        showCachedDataHint = false;

  /// Creates a timeout error state.
  const NoConnection.timeout({
    super.key,
    this.onRetry,
    this.retryLabel = 'Try again',
  })  : title = 'Connection timed out',
        message = 'The request took too long. Please check your connection and try again.',
        showCachedDataHint = false;

  String get _message {
    if (message != null) return message!;

    if (showCachedDataHint) {
      return 'Please check your connection and try again. Your changes will sync once you\'re back online.';
    }
    return 'Please check your connection and try again.';
  }

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.wifi_off,
      title: title,
      message: _message,
      actionLabel: onRetry != null ? retryLabel : null,
      onAction: onRetry,
      variant: EmptyStateVariant.offline,
    );
  }
}
