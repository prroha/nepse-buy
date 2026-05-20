import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../atoms/skeleton.dart';

/// A skeleton placeholder for list items.
///
/// Matches the layout of actual list items for smooth loading transitions.
///
/// Example:
/// ```dart
/// SkeletonListItem(
///   variant: SkeletonListItemVariant.detailed,
/// )
/// ```
class SkeletonListItem extends StatelessWidget {
  /// List item variant.
  final SkeletonListItemVariant variant;

  /// Whether to show a leading element (icon/image).
  final bool showLeading;

  /// Leading element type.
  final SkeletonLeadingType leadingType;

  /// Whether to show a trailing element.
  final bool showTrailing;

  /// Trailing element type.
  final SkeletonTrailingType trailingType;

  /// Number of subtitle lines.
  final int subtitleLines;

  /// Whether to enable shimmer animation.
  final bool shimmer;

  /// Padding around the item.
  final EdgeInsetsGeometry? padding;

  const SkeletonListItem({
    super.key,
    this.variant = SkeletonListItemVariant.standard,
    this.showLeading = true,
    this.leadingType = SkeletonLeadingType.avatar,
    this.showTrailing = false,
    this.trailingType = SkeletonTrailingType.icon,
    this.subtitleLines = 1,
    this.shimmer = true,
    this.padding,
  });

  /// Creates a simple list item skeleton with icon and text.
  const SkeletonListItem.simple({
    super.key,
    this.showLeading = true,
    this.showTrailing = false,
    this.trailingType = SkeletonTrailingType.icon,
    this.shimmer = true,
    this.padding,
  })  : variant = SkeletonListItemVariant.simple,
        leadingType = SkeletonLeadingType.icon,
        subtitleLines = 0;

  /// Creates a standard list item skeleton with avatar and subtitle.
  const SkeletonListItem.standard({
    super.key,
    this.showLeading = true,
    this.leadingType = SkeletonLeadingType.avatar,
    this.showTrailing = true,
    this.trailingType = SkeletonTrailingType.icon,
    this.subtitleLines = 1,
    this.shimmer = true,
    this.padding,
  }) : variant = SkeletonListItemVariant.standard;

  /// Creates a detailed list item skeleton with more content.
  const SkeletonListItem.detailed({
    super.key,
    this.showLeading = true,
    this.leadingType = SkeletonLeadingType.image,
    this.showTrailing = true,
    this.trailingType = SkeletonTrailingType.button,
    this.subtitleLines = 2,
    this.shimmer = true,
    this.padding,
  }) : variant = SkeletonListItemVariant.detailed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Tighter padding
      padding: padding ?? const EdgeInsets.symmetric(
        horizontal: AppSpacing.md, // 12dp
        vertical: 6,
      ),
      child: Row(
        crossAxisAlignment: variant == SkeletonListItemVariant.detailed
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          if (showLeading) ...[
            _buildLeading(),
            const SizedBox(width: AppSpacing.sm), // Tighter gap
          ],
          Expanded(child: _buildContent()),
          if (showTrailing) ...[
            const SizedBox(width: AppSpacing.sm), // Tighter gap
            _buildTrailing(),
          ],
        ],
      ),
    );
  }

  Widget _buildLeading() {
    switch (leadingType) {
      case SkeletonLeadingType.icon:
        return SkeletonBox(
          width: 24,
          height: 24,
          borderRadius: BorderRadius.circular(4),
          shimmer: shimmer,
        );
      case SkeletonLeadingType.avatar:
        return SkeletonCircle.md(shimmer: shimmer);
      case SkeletonLeadingType.image:
        return SkeletonBox(
          width: 56,
          height: 56,
          borderRadius: AppSpacing.borderRadiusSm,
          shimmer: shimmer,
        );
      case SkeletonLeadingType.checkbox:
        return SkeletonBox(
          width: 20,
          height: 20,
          borderRadius: BorderRadius.circular(4),
          shimmer: shimmer,
        );
    }
  }

  Widget _buildContent() {
    switch (variant) {
      case SkeletonListItemVariant.simple:
        return SkeletonBox(height: 16, shimmer: shimmer);

      case SkeletonListItemVariant.standard:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SkeletonBox(height: 16, shimmer: shimmer),
            if (subtitleLines > 0) ...[
              const SizedBox(height: AppSpacing.xs),
              FractionallySizedBox(
                widthFactor: 0.7,
                child: SkeletonBox(height: 12, shimmer: shimmer),
              ),
            ],
          ],
        );

      case SkeletonListItemVariant.detailed:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SkeletonBox(height: 18, shimmer: shimmer),
            const SizedBox(height: AppSpacing.sm),
            SkeletonText(lines: subtitleLines, shimmer: shimmer),
            const SizedBox(height: AppSpacing.xs),
            FractionallySizedBox(
              widthFactor: 0.4,
              child: SkeletonBox(height: 10, shimmer: shimmer),
            ),
          ],
        );
    }
  }

  Widget _buildTrailing() {
    switch (trailingType) {
      case SkeletonTrailingType.icon:
        return SkeletonBox(
          width: 24,
          height: 24,
          borderRadius: BorderRadius.circular(4),
          shimmer: shimmer,
        );
      case SkeletonTrailingType.button:
        return SkeletonButton(size: SkeletonButtonSize.sm, shimmer: shimmer);
      case SkeletonTrailingType.text:
        return SkeletonBox(width: 40, height: 14, shimmer: shimmer);
      case SkeletonTrailingType.toggle:
        return SkeletonBox(
          width: 48,
          height: 28,
          borderRadius: BorderRadius.circular(14),
          shimmer: shimmer,
        );
    }
  }
}

/// List item variant options.
enum SkeletonListItemVariant {
  simple,
  standard,
  detailed,
}

/// Leading element type options.
enum SkeletonLeadingType {
  icon,
  avatar,
  image,
  checkbox,
}

/// Trailing element type options.
enum SkeletonTrailingType {
  icon,
  button,
  text,
  toggle,
}

/// A skeleton for list with multiple items.
///
/// Example:
/// ```dart
/// SkeletonList(
///   itemCount: 5,
///   itemVariant: SkeletonListItemVariant.standard,
/// )
/// ```
class SkeletonList extends StatelessWidget {
  /// Number of items to show.
  final int itemCount;

  /// List item variant.
  final SkeletonListItemVariant itemVariant;

  /// Whether to show dividers between items.
  final bool showDividers;

  /// Whether to show leading elements.
  final bool showLeading;

  /// Whether to show trailing elements.
  final bool showTrailing;

  /// Whether to enable shimmer animation.
  final bool shimmer;

  /// Padding around the list.
  final EdgeInsetsGeometry? padding;

  const SkeletonList({
    super.key,
    this.itemCount = 5,
    this.itemVariant = SkeletonListItemVariant.standard,
    this.showDividers = false,
    this.showLeading = true,
    this.showTrailing = false,
    this.shimmer = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      itemCount: itemCount,
      separatorBuilder: (context, index) {
        if (showDividers) {
          return const Divider(height: 1);
        }
        return const SizedBox(height: AppSpacing.sm);
      },
      itemBuilder: (context, index) {
        return SkeletonListItem(
          variant: itemVariant,
          showLeading: showLeading,
          showTrailing: showTrailing,
          shimmer: shimmer,
        );
      },
    );
  }
}

/// A skeleton for notification items.
///
/// Example:
/// ```dart
/// SkeletonNotificationItem()
/// ```
class SkeletonNotificationItem extends StatelessWidget {
  /// Whether to show unread indicator.
  final bool showUnreadIndicator;

  /// Whether to enable shimmer animation.
  final bool shimmer;

  const SkeletonNotificationItem({
    super.key,
    this.showUnreadIndicator = true,
    this.shimmer = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonCircle.md(shimmer: shimmer),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 14, shimmer: shimmer),
                const SizedBox(height: AppSpacing.xs),
                FractionallySizedBox(
                  widthFactor: 0.85,
                  child: SkeletonBox(height: 14, shimmer: shimmer),
                ),
                const SizedBox(height: AppSpacing.sm),
                SkeletonBox(width: 60, height: 10, shimmer: shimmer),
              ],
            ),
          ),
          if (showUnreadIndicator)
            SkeletonCircle(size: 8, shimmer: shimmer),
        ],
      ),
    );
  }
}

/// A skeleton for message/chat items.
///
/// Example:
/// ```dart
/// SkeletonMessageItem(isOutgoing: false)
/// ```
class SkeletonMessageItem extends StatelessWidget {
  /// Whether the message is outgoing (right-aligned).
  final bool isOutgoing;

  /// Number of text lines.
  final int lines;

  /// Whether to enable shimmer animation.
  final bool shimmer;

  const SkeletonMessageItem({
    super.key,
    this.isOutgoing = false,
    this.lines = 2,
    this.shimmer = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: isOutgoing ? 64 : AppSpacing.md,
        right: isOutgoing ? AppSpacing.md : 64,
        top: AppSpacing.sm,
        bottom: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment:
            isOutgoing ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isOutgoing) ...[
            SkeletonCircle.sm(shimmer: shimmer),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isOutgoing
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isOutgoing ? 16 : 4),
                  bottomRight: Radius.circular(isOutgoing ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SkeletonText(
                    lines: lines,
                    shimmer: shimmer,
                    color: isOutgoing ? Colors.white24 : null,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  SkeletonBox(
                    width: 40,
                    height: 10,
                    shimmer: shimmer,
                    color: isOutgoing ? Colors.white24 : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A skeleton for comment items.
///
/// Example:
/// ```dart
/// SkeletonCommentItem(showReplies: true)
/// ```
class SkeletonCommentItem extends StatelessWidget {
  /// Whether to show reply button.
  final bool showReplyButton;

  /// Number of replies to show.
  final int replyCount;

  /// Whether to enable shimmer animation.
  final bool shimmer;

  const SkeletonCommentItem({
    super.key,
    this.showReplyButton = true,
    this.replyCount = 0,
    this.shimmer = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonCircle.md(shimmer: shimmer),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SkeletonBox(width: 100, height: 14, shimmer: shimmer),
                        const SizedBox(width: AppSpacing.sm),
                        SkeletonBox(width: 50, height: 10, shimmer: shimmer),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SkeletonText(lines: 2, shimmer: shimmer),
                    if (showReplyButton) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          SkeletonBox(width: 40, height: 12, shimmer: shimmer),
                          const SizedBox(width: AppSpacing.md),
                          SkeletonBox(width: 40, height: 12, shimmer: shimmer),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (replyCount > 0) ...[
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.only(left: 52),
              child: Column(
                children: List.generate(replyCount, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonCircle.sm(shimmer: shimmer),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  SkeletonBox(
                                    width: 80,
                                    height: 12,
                                    shimmer: shimmer,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  SkeletonBox(
                                    width: 40,
                                    height: 10,
                                    shimmer: shimmer,
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              SkeletonBox(height: 12, shimmer: shimmer),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
