import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../atoms/app_button.dart';

/// Variant types for empty state styling.
enum EmptyStateVariant {
  /// Default variant with neutral styling
  noData,

  /// Search results empty state
  noResults,

  /// Notifications empty state
  noNotifications,

  /// Error variant with destructive styling
  error,

  /// Offline/connection variant with warning styling
  offline,
}

/// An empty state widget with illustration, message, and optional action.
///
/// This is a layout-level widget for displaying empty states in lists,
/// search results, or other content areas.
///
/// Example:
/// ```dart
/// EmptyState(
///   icon: Icons.search_off,
///   title: 'No results found',
///   message: 'Try adjusting your search criteria',
///   actionLabel: 'Clear filters',
///   onAction: () => clearFilters(),
/// )
/// ```
class EmptyState extends StatelessWidget {
  /// The icon to display.
  final IconData icon;

  /// The title text.
  final String title;

  /// Optional description message.
  final String? message;

  /// Optional action button label.
  final String? actionLabel;

  /// Callback when the action button is pressed.
  final VoidCallback? onAction;

  /// Icon size.
  final double iconSize;

  /// Icon color.
  final Color? iconColor;

  /// Optional custom illustration widget.
  final Widget? illustration;

  /// Optional secondary action button label.
  final String? secondaryActionLabel;

  /// Callback for secondary action.
  final VoidCallback? onSecondaryAction;

  /// The variant that controls icon color and background.
  final EmptyStateVariant variant;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.iconSize = 64,
    this.iconColor,
    this.illustration,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.variant = EmptyStateVariant.noData,
  });

  /// Creates an empty state for no data scenarios.
  const EmptyState.noData({
    super.key,
    this.title = 'Nothing here yet',
    this.message = 'This list is empty. Add some items to get started.',
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  })  : icon = Icons.inbox_outlined,
        iconSize = 64,
        iconColor = null,
        illustration = null,
        variant = EmptyStateVariant.noData;

  /// Creates an empty state for search results.
  const EmptyState.noResults({
    super.key,
    this.title = 'No results found',
    this.message = "We couldn't find what you're looking for. Try adjusting your search or filters.",
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  })  : icon = Icons.search_off,
        iconSize = 64,
        iconColor = null,
        illustration = null,
        variant = EmptyStateVariant.noResults;

  /// Creates an empty state for notifications.
  const EmptyState.noNotifications({
    super.key,
    this.title = "You're all caught up!",
    this.message = "No new notifications right now. We'll let you know when something important happens.",
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  })  : icon = Icons.notifications_off_outlined,
        iconSize = 64,
        iconColor = null,
        illustration = null,
        variant = EmptyStateVariant.noNotifications;

  /// Creates an empty state for network errors.
  const EmptyState.offline({
    super.key,
    this.title = 'No internet connection',
    this.message = 'Please check your connection and try again. Your changes will sync once you\'re back online.',
    this.actionLabel = 'Try again',
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  })  : icon = Icons.wifi_off,
        iconSize = 64,
        iconColor = null,
        illustration = null,
        variant = EmptyStateVariant.offline;

  /// Creates an empty state for error scenarios.
  const EmptyState.error({
    super.key,
    this.title = 'Something went wrong',
    this.message = 'We encountered an error loading this content. Please try again.',
    this.actionLabel = 'Retry',
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  })  : icon = Icons.error_outline,
        iconSize = 64,
        iconColor = null,
        illustration = null,
        variant = EmptyStateVariant.error;

  Color _getIconColor(BuildContext context) {
    if (iconColor != null) return iconColor!;

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (variant) {
      case EmptyStateVariant.error:
        return colorScheme.error;
      case EmptyStateVariant.offline:
        return isDark ? Colors.amber : const Color(0xFFD97706);
      case EmptyStateVariant.noData:
      case EmptyStateVariant.noResults:
      case EmptyStateVariant.noNotifications:
        return colorScheme.outline;
    }
  }

  Color _getBackgroundColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (variant) {
      case EmptyStateVariant.error:
        return colorScheme.error.withAlpha(isDark ? 26 : 13);
      case EmptyStateVariant.offline:
        return isDark ? Colors.amber.withAlpha(26) : const Color(0xFFD97706).withAlpha(13);
      case EmptyStateVariant.noData:
      case EmptyStateVariant.noResults:
      case EmptyStateVariant.noNotifications:
        return colorScheme.outlineVariant.withAlpha(isDark ? 128 : 77);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final titleColor = colorScheme.onSurface;
    final messageColor = colorScheme.onSurfaceVariant;

    return Center(
      child: Padding(
        // Tighter padding
        padding: const EdgeInsets.all(AppSpacing.md), // 12dp
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Illustration or icon with background - tighter size
            if (illustration != null)
              illustration!
            else
              Container(
                width: 64, // Reduced from 80
                height: 64,
                decoration: BoxDecoration(
                  color: _getBackgroundColor(context),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32, // Reduced
                  color: _getIconColor(context),
                ),
              ),
            AppSpacing.gapMd, // Tighter gap

            // Title - tighter
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18, // Reduced from 20
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
            ),

            // Message
            if (message != null) ...[
              AppSpacing.gapXs, // Tighter gap
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280), // Slightly narrower
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13, // Slightly smaller
                    color: messageColor,
                    height: 1.4,
                  ),
                ),
              ),
            ],

            // Actions
            if (actionLabel != null && onAction != null) ...[
              AppSpacing.gapMd, // Tighter gap
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                size: AppButtonSize.small, // Smaller button
                variant: variant == EmptyStateVariant.error ||
                        variant == EmptyStateVariant.offline
                    ? AppButtonVariant.outline
                    : AppButtonVariant.primary,
              ),
            ],

            if (secondaryActionLabel != null && onSecondaryAction != null) ...[
              AppSpacing.gapXs, // Tighter gap
              AppButton(
                label: secondaryActionLabel!,
                onPressed: onSecondaryAction,
                size: AppButtonSize.small,
                variant: AppButtonVariant.text,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Backwards-compatible widget wrapper for EmptyState.
///
/// This provides a simpler API matching the old EmptyStateWidget usage.
///
/// Example:
/// ```dart
/// EmptyStateWidget(
///   message: 'No users found',
///   icon: Icons.people_outline,
/// )
/// ```
class EmptyStateWidget extends StatelessWidget {
  /// The message to display.
  final String message;

  /// The icon to display.
  final IconData icon;

  /// Optional action button label.
  final String? actionLabel;

  /// Callback when the action button is pressed.
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.message,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: icon,
      title: message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}
