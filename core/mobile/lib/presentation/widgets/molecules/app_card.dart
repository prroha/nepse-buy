import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../atoms/app_text.dart';

/// A styled card with optional header, content, and footer sections.
///
/// This is a molecule-level widget that provides a consistent card layout
/// with flexible content areas.
///
/// Example:
/// ```dart
/// AppCard(
///   header: Text('Card Title'),
///   child: Text('Card content goes here'),
///   footer: AppButton(label: 'Action', onPressed: () {}),
/// )
/// ```
class AppCard extends StatelessWidget {
  /// The main content of the card.
  final Widget child;

  /// Optional header widget displayed at the top.
  final Widget? header;

  /// Optional footer widget displayed at the bottom.
  final Widget? footer;

  /// Padding around the card content.
  final EdgeInsetsGeometry? padding;

  /// Margin around the entire card.
  final EdgeInsetsGeometry? margin;

  /// Background color of the card.
  final Color? backgroundColor;

  /// Border radius of the card.
  final BorderRadius? borderRadius;

  /// Whether to show a shadow.
  final bool hasShadow;

  /// Whether to show a border.
  final bool hasBorder;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  /// Callback when the card is long pressed.
  final VoidCallback? onLongPress;

  const AppCard({
    super.key,
    required this.child,
    this.header,
    this.footer,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius,
    this.hasShadow = true,
    this.hasBorder = false,
    this.onTap,
    this.onLongPress,
  });

  /// Creates a card with a title header.
  factory AppCard.titled({
    Key? key,
    required String title,
    required Widget child,
    Widget? trailing,
    Widget? footer,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
  }) {
    return AppCard(
      key: key,
      header: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Use AppText atom for consistent typography
          AppText(
            title,
            variant: AppTextVariant.heading4,
          ),
          if (trailing != null) trailing,
        ],
      ),
      footer: footer,
      padding: padding,
      margin: margin,
      onTap: onTap,
      child: child,
    );
  }

  /// Creates a compact card with tighter padding.
  const AppCard.compact({
    super.key,
    required this.child,
    this.header,
    this.footer,
    this.margin,
    this.backgroundColor,
    this.borderRadius,
    this.hasShadow = true,
    this.hasBorder = false,
    this.onTap,
    this.onLongPress,
  }) : padding = const EdgeInsets.all(AppSpacing.sm);

  /// Creates a flat card without shadow.
  const AppCard.flat({
    super.key,
    required this.child,
    this.header,
    this.footer,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius,
    this.onTap,
    this.onLongPress,
  })  : hasShadow = false,
        hasBorder = true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.surface,
        borderRadius: borderRadius ?? AppSpacing.borderRadiusMd,
        border: hasBorder
            ? Border.all(color: colorScheme.outlineVariant)
            : null,
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: colorScheme.shadow.withAlpha(13),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (header != null)
            Padding(
              padding: padding ?? AppSpacing.cardContentPadding,
              child: header,
            ),
          if (header != null && (hasBorder || hasShadow))
            Divider(height: 1, color: colorScheme.outlineVariant),
          Padding(
            padding: padding ?? AppSpacing.cardContentPadding,
            child: child,
          ),
          if (footer != null && (hasBorder || hasShadow))
            Divider(height: 1, color: colorScheme.outlineVariant),
          if (footer != null)
            Padding(
              padding: padding ?? AppSpacing.cardContentPadding,
              child: footer,
            ),
        ],
      ),
    );

    if (onTap != null || onLongPress != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: borderRadius ?? AppSpacing.borderRadiusMd,
          child: card,
        ),
      );
    }

    return card;
  }
}
