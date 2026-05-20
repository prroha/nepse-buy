import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../atoms/skeleton.dart';

/// A skeleton placeholder for card components.
///
/// Matches the layout of actual cards for smooth loading transitions.
///
/// Example:
/// ```dart
/// SkeletonCard(
///   variant: SkeletonCardVariant.vertical,
///   showImage: true,
/// )
/// ```
class SkeletonCard extends StatelessWidget {
  /// Card layout variant.
  final SkeletonCardVariant variant;

  /// Whether to show an image placeholder.
  final bool showImage;

  /// Number of text lines to show.
  final int textLines;

  /// Whether to show action buttons.
  final bool showActions;

  /// Padding inside the card.
  final EdgeInsetsGeometry? padding;

  /// Margin around the card.
  final EdgeInsetsGeometry? margin;

  /// Whether to show border.
  final bool showBorder;

  /// Whether to enable shimmer animation.
  final bool shimmer;

  const SkeletonCard({
    super.key,
    this.variant = SkeletonCardVariant.vertical,
    this.showImage = true,
    this.textLines = 2,
    this.showActions = false,
    this.padding,
    this.margin,
    this.showBorder = true,
    this.shimmer = true,
  });

  /// Creates a vertical card skeleton.
  const SkeletonCard.vertical({
    super.key,
    this.showImage = true,
    this.textLines = 2,
    this.showActions = false,
    this.padding,
    this.margin,
    this.showBorder = true,
    this.shimmer = true,
  }) : variant = SkeletonCardVariant.vertical;

  /// Creates a horizontal card skeleton.
  const SkeletonCard.horizontal({
    super.key,
    this.showImage = true,
    this.textLines = 2,
    this.showActions = false,
    this.padding,
    this.margin,
    this.showBorder = true,
    this.shimmer = true,
  }) : variant = SkeletonCardVariant.horizontal;

  /// Creates a compact card skeleton.
  const SkeletonCard.compact({
    super.key,
    this.showImage = true,
    this.textLines = 1,
    this.showActions = false,
    this.padding,
    this.margin,
    this.showBorder = true,
    this.shimmer = true,
  }) : variant = SkeletonCardVariant.compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget content;
    switch (variant) {
      case SkeletonCardVariant.horizontal:
        content = _buildHorizontalCard();
        break;
      case SkeletonCardVariant.compact:
        content = _buildCompactCard();
        break;
      case SkeletonCardVariant.vertical:
      default:
        content = _buildVerticalCard();
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        border: showBorder
            ? Border.all(color: colorScheme.outlineVariant)
            : null,
        boxShadow: showBorder
            ? null
            : [
                BoxShadow(
                  color: colorScheme.shadow.withAlpha(13),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Padding(
        // Tighter padding: 12dp (md is now 12)
        padding: padding ?? const EdgeInsets.all(AppSpacing.md),
        child: content,
      ),
    );
  }

  Widget _buildVerticalCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showImage) ...[
          SkeletonImage(
            aspectRatio: SkeletonImageAspectRatio.video,
            shimmer: shimmer,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        SkeletonBox(
          height: 20,
          shimmer: shimmer,
        ),
        const SizedBox(height: AppSpacing.sm),
        SkeletonText(
          lines: textLines,
          shimmer: shimmer,
        ),
        if (showActions) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              SkeletonButton(size: SkeletonButtonSize.sm, shimmer: shimmer),
              const SizedBox(width: AppSpacing.sm),
              SkeletonButton(size: SkeletonButtonSize.sm, shimmer: shimmer),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildHorizontalCard() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showImage)
          SkeletonBox(
            width: 100,
            height: 80,
            borderRadius: AppSpacing.borderRadiusSm,
            shimmer: shimmer,
          ),
        if (showImage) const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SkeletonBox(height: 18, shimmer: shimmer),
              const SizedBox(height: AppSpacing.sm),
              SkeletonText(lines: textLines, shimmer: shimmer),
              if (showActions) ...[
                const SizedBox(height: AppSpacing.sm),
                SkeletonButton(size: SkeletonButtonSize.sm, shimmer: shimmer),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactCard() {
    return Row(
      children: [
        if (showImage)
          SkeletonBox(
            width: 48,
            height: 48,
            borderRadius: AppSpacing.borderRadiusSm,
            shimmer: shimmer,
          ),
        if (showImage) const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SkeletonBox(height: 16, shimmer: shimmer),
              const SizedBox(height: AppSpacing.xs),
              FractionallySizedBox(
                widthFactor: 0.7,
                child: SkeletonBox(height: 12, shimmer: shimmer),
              ),
            ],
          ),
        ),
        if (showActions)
          SkeletonBox(
            width: 32,
            height: 32,
            shimmer: shimmer,
          ),
      ],
    );
  }
}

/// Card variant options.
enum SkeletonCardVariant {
  vertical,
  horizontal,
  compact,
}

/// A skeleton for user cards.
///
/// Example:
/// ```dart
/// SkeletonUserCard(
///   variant: SkeletonUserCardVariant.detailed,
/// )
/// ```
class SkeletonUserCard extends StatelessWidget {
  /// Card variant.
  final SkeletonUserCardVariant variant;

  /// Whether to show action buttons.
  final bool showActions;

  /// Whether to enable shimmer animation.
  final bool shimmer;

  const SkeletonUserCard({
    super.key,
    this.variant = SkeletonUserCardVariant.standard,
    this.showActions = true,
    this.shimmer = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget content;
    switch (variant) {
      case SkeletonUserCardVariant.compact:
        content = _buildCompact();
        break;
      case SkeletonUserCardVariant.detailed:
        content = _buildDetailed();
        break;
      case SkeletonUserCardVariant.standard:
      default:
        content = _buildStandard();
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: content,
    );
  }

  Widget _buildCompact() {
    return Row(
      children: [
        SkeletonCircle.sm(shimmer: shimmer),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: SkeletonBox(height: 14, shimmer: shimmer),
        ),
        if (showActions) SkeletonBox(width: 24, height: 24, shimmer: shimmer),
      ],
    );
  }

  Widget _buildStandard() {
    return Row(
      children: [
        SkeletonCircle.lg(shimmer: shimmer),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SkeletonBox(height: 16, shimmer: shimmer),
              const SizedBox(height: AppSpacing.xs),
              FractionallySizedBox(
                widthFactor: 0.6,
                child: SkeletonBox(height: 12, shimmer: shimmer),
              ),
            ],
          ),
        ),
        if (showActions)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SkeletonBox(width: 32, height: 32, shimmer: shimmer),
              const SizedBox(width: AppSpacing.sm),
              SkeletonBox(width: 32, height: 32, shimmer: shimmer),
            ],
          ),
      ],
    );
  }

  Widget _buildDetailed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonCircle.xl(shimmer: shimmer),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(height: 20, shimmer: shimmer),
                  const SizedBox(height: AppSpacing.sm),
                  FractionallySizedBox(
                    widthFactor: 0.6,
                    child: SkeletonBox(height: 14, shimmer: shimmer),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      SkeletonBox(width: 60, height: 20, shimmer: shimmer),
                      const SizedBox(width: AppSpacing.sm),
                      SkeletonBox(width: 80, height: 20, shimmer: shimmer),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const Divider(),
        const SizedBox(height: AppSpacing.sm),
        SkeletonText(lines: 2, shimmer: shimmer),
        if (showActions) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              SkeletonButton(size: SkeletonButtonSize.sm, shimmer: shimmer),
              const SizedBox(width: AppSpacing.sm),
              SkeletonButton(size: SkeletonButtonSize.sm, shimmer: shimmer),
            ],
          ),
        ],
      ],
    );
  }
}

/// User card variant options.
enum SkeletonUserCardVariant {
  compact,
  standard,
  detailed,
}

/// A skeleton for product cards (e-commerce).
///
/// Example:
/// ```dart
/// SkeletonProductCard()
/// ```
class SkeletonProductCard extends StatelessWidget {
  /// Whether to show quick action buttons.
  final bool showActions;

  /// Whether to enable shimmer animation.
  final bool shimmer;

  const SkeletonProductCard({
    super.key,
    this.showActions = true,
    this.shimmer = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              SkeletonImage(
                aspectRatio: SkeletonImageAspectRatio.square,
                borderRadius: BorderRadius.zero,
                shimmer: shimmer,
              ),
              if (showActions)
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: Column(
                    children: [
                      SkeletonCircle.sm(shimmer: shimmer),
                      const SizedBox(height: AppSpacing.xs),
                      SkeletonCircle.sm(shimmer: shimmer),
                    ],
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 16, shimmer: shimmer),
                const SizedBox(height: AppSpacing.sm),
                FractionallySizedBox(
                  widthFactor: 0.8,
                  child: SkeletonBox(height: 12, shimmer: shimmer),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 80, height: 20, shimmer: shimmer),
                        const SizedBox(height: AppSpacing.xs),
                        SkeletonBox(width: 50, height: 12, shimmer: shimmer),
                      ],
                    ),
                    if (showActions)
                      SkeletonButton(
                        size: SkeletonButtonSize.sm,
                        shimmer: shimmer,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
