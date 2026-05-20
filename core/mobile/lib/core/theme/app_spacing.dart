import 'package:flutter/material.dart';

/// App spacing constants - content-first, tighter spacing matching web design system.
/// Uses 4dp base unit for consistent, compact layouts that maximize screen real estate
/// while maintaining touch-friendliness (minimum 44dp touch targets).
class AppSpacing {
  // ==========================================================================
  // Base unit: 4dp - Tighter, content-first spacing scale
  // ==========================================================================

  /// Hairline spacing (2dp) - line-height-style tight gaps between stacked labels
  static const double xxs = 2.0;

  /// Extra small spacing (4dp) - Tight inline spacing, related text
  static const double xs = 4.0;

  /// Small spacing (8dp) - Related items, tight grouping
  static const double sm = 8.0;

  /// Medium spacing (12dp) - Card padding, form gaps, standard spacing
  static const double md = 12.0;

  /// Large spacing (16dp) - Section spacing, screen padding
  static const double lg = 16.0;

  /// Extra large spacing (24dp) - Major sections, hero areas
  static const double xl = 24.0;

  /// Extra extra large spacing (32dp) - Hero/page sections
  static const double xxl = 32.0;

  // ==========================================================================
  // Semantic spacing - Named values for specific use cases
  // ==========================================================================

  /// Input field internal padding
  static const double inputPadding = 12.0;

  /// Card content padding
  static const double cardPadding = 12.0;

  /// Button horizontal padding
  static const double buttonPaddingH = 16.0;

  /// Button vertical padding
  static const double buttonPaddingV = 10.0;

  /// Spacing between list items
  static const double listItemSpacing = 8.0;

  /// Section spacing in scrollable content
  static const double sectionSpacing = 16.0;

  /// Icon size standard
  static const double iconSize = 20.0;

  /// Icon size small
  static const double iconSizeSm = 16.0;

  /// Icon size large
  static const double iconSizeLg = 24.0;

  // ==========================================================================
  // Touch target constraints - Accessibility compliance
  // ==========================================================================

  /// Minimum touch target size for accessibility (44dp per WCAG)
  static const double minTouchTarget = 44.0;

  /// Standard button height
  static const double buttonHeight = 44.0;

  /// Compact button height (still meets touch target with padding)
  static const double buttonHeightSm = 36.0;

  /// Large button height
  static const double buttonHeightLg = 52.0;

  // ==========================================================================
  // Edge insets helpers - Pre-built padding combinations
  // ==========================================================================

  /// Screen edge padding - consistent safe margins
  static const EdgeInsets screenPadding = EdgeInsets.all(lg);

  /// Horizontal screen padding only
  static const EdgeInsets screenPaddingH = EdgeInsets.symmetric(horizontal: lg);

  /// Card content padding - tighter for content-first design
  static const EdgeInsets cardContentPadding = EdgeInsets.all(md);

  /// List item padding
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: sm,
  );

  /// Button padding - tighter vertical for compact buttons
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: buttonPaddingH,
    vertical: buttonPaddingV,
  );

  /// Input field content padding
  static const EdgeInsets inputContentPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: md,
  );

  /// Dialog content padding
  static const EdgeInsets dialogPadding = EdgeInsets.all(lg);

  /// Modal/sheet padding
  static const EdgeInsets sheetPadding = EdgeInsets.fromLTRB(lg, md, lg, lg);

  /// Form field spacing (between fields)
  static const EdgeInsets formFieldMargin = EdgeInsets.only(bottom: md);

  /// Section padding with top margin
  static const EdgeInsets sectionPadding = EdgeInsets.only(
    left: lg,
    right: lg,
    top: lg,
    bottom: sm,
  );

  // ==========================================================================
  // Common gaps - SizedBox shortcuts for vertical spacing
  // ==========================================================================

  /// Extra small vertical gap (4dp)
  static const SizedBox gapXs = SizedBox(height: xs);

  /// Small vertical gap (8dp)
  static const SizedBox gapSm = SizedBox(height: sm);

  /// Medium vertical gap (12dp)
  static const SizedBox gapMd = SizedBox(height: md);

  /// Large vertical gap (16dp)
  static const SizedBox gapLg = SizedBox(height: lg);

  /// Extra large vertical gap (24dp)
  static const SizedBox gapXl = SizedBox(height: xl);

  /// Extra extra large vertical gap (32dp)
  static const SizedBox gapXxl = SizedBox(height: xxl);

  // ==========================================================================
  // Horizontal gaps - SizedBox shortcuts for horizontal spacing
  // ==========================================================================

  /// Extra small horizontal gap (4dp)
  static const SizedBox gapHXs = SizedBox(width: xs);

  /// Small horizontal gap (8dp)
  static const SizedBox gapHSm = SizedBox(width: sm);

  /// Medium horizontal gap (12dp)
  static const SizedBox gapHMd = SizedBox(width: md);

  /// Large horizontal gap (16dp)
  static const SizedBox gapHLg = SizedBox(width: lg);

  /// Extra large horizontal gap (24dp)
  static const SizedBox gapHXl = SizedBox(width: xl);

  // ==========================================================================
  // Border radius - Consistent corner rounding
  // ==========================================================================

  /// Small border radius (8dp) - Buttons, inputs, small cards
  static final BorderRadius borderRadiusSm = BorderRadius.circular(8.0);

  /// Medium border radius (12dp) - Cards, dialogs, sheets
  static final BorderRadius borderRadiusMd = BorderRadius.circular(12.0);

  /// Large border radius (16dp) - Large cards, modals
  static final BorderRadius borderRadiusLg = BorderRadius.circular(16.0);

  /// Extra large border radius (24dp) - Bottom sheets, large modals
  static final BorderRadius borderRadiusXl = BorderRadius.circular(24.0);

  /// Full/pill border radius - Pills, tags, circular elements
  static final BorderRadius borderRadiusFull = BorderRadius.circular(9999.0);
}

// ============================================================================
// Gap widgets - Reusable spacing widgets for cleaner code
// ============================================================================

/// A reusable vertical gap widget for consistent spacing.
/// Use this instead of SizedBox for cleaner code.
///
/// Example:
/// ```dart
/// Column(
///   children: [
///     Text('Title'),
///     const Gap.sm(),
///     Text('Description'),
///   ],
/// )
/// ```
class Gap extends StatelessWidget {
  final double size;

  const Gap.xs({super.key}) : size = AppSpacing.xs;
  const Gap.sm({super.key}) : size = AppSpacing.sm;
  const Gap.md({super.key}) : size = AppSpacing.md;
  const Gap.lg({super.key}) : size = AppSpacing.lg;
  const Gap.xl({super.key}) : size = AppSpacing.xl;
  const Gap.xxl({super.key}) : size = AppSpacing.xxl;
  const Gap.custom(this.size, {super.key});

  @override
  Widget build(BuildContext context) => SizedBox(height: size);
}

/// A reusable horizontal gap widget for consistent spacing.
///
/// Example:
/// ```dart
/// Row(
///   children: [
///     Icon(Icons.star),
///     const HGap.sm(),
///     Text('Rating'),
///   ],
/// )
/// ```
class HGap extends StatelessWidget {
  final double size;

  const HGap.xs({super.key}) : size = AppSpacing.xs;
  const HGap.sm({super.key}) : size = AppSpacing.sm;
  const HGap.md({super.key}) : size = AppSpacing.md;
  const HGap.lg({super.key}) : size = AppSpacing.lg;
  const HGap.xl({super.key}) : size = AppSpacing.xl;
  const HGap.custom(this.size, {super.key});

  @override
  Widget build(BuildContext context) => SizedBox(width: size);
}
