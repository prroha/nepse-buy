import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';

/// Divider thickness presets.
enum AppDividerThickness {
  /// Thin divider (0.5px)
  thin,

  /// Normal divider (1px) - default
  normal,

  /// Thick divider (2px)
  thick,
}

/// A styled divider widget with consistent spacing and colors.
///
/// This is an atom-level widget that provides consistent divider styling
/// across the application. Uses Theme.of(context) for theme-aware colors.
///
/// Example:
/// ```dart
/// AppDivider()
/// AppDivider.vertical(height: 24)
/// AppDivider.withLabel('OR')
/// ```
class AppDivider extends StatelessWidget {
  /// The height of the divider (for horizontal dividers).
  final double? height;

  /// The width of the divider (for vertical dividers).
  final double? width;

  /// The thickness preset for the divider line.
  final AppDividerThickness thickness;

  /// The indent from the start of the divider.
  final double? indent;

  /// The indent from the end of the divider.
  final double? endIndent;

  /// Optional color override.
  final Color? color;

  /// Whether this is a vertical divider.
  final bool isVertical;

  /// Optional label to display in the center of the divider.
  final String? label;

  const AppDivider({
    super.key,
    this.height,
    this.width,
    this.thickness = AppDividerThickness.normal,
    this.indent,
    this.endIndent,
    this.color,
    this.label,
  }) : isVertical = false;

  /// Creates a vertical divider.
  const AppDivider.vertical({
    super.key,
    this.height,
    this.width,
    this.thickness = AppDividerThickness.normal,
    this.indent,
    this.endIndent,
    this.color,
  })  : isVertical = true,
        label = null;

  /// Creates a horizontal divider with a centered label.
  const AppDivider.withLabel(
    this.label, {
    super.key,
    this.height,
    this.thickness = AppDividerThickness.normal,
    this.indent,
    this.endIndent,
    this.color,
  })  : isVertical = false,
        width = null;

  /// Creates a section divider with larger spacing.
  const AppDivider.section({
    super.key,
    this.thickness = AppDividerThickness.normal,
    this.indent,
    this.endIndent,
    this.color,
  })  : height = AppSpacing.lg,
        width = null,
        isVertical = false,
        label = null;

  double _getThickness() {
    switch (thickness) {
      case AppDividerThickness.thin:
        return 0.5;
      case AppDividerThickness.normal:
        return 1.0;
      case AppDividerThickness.thick:
        return 2.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dividerColor = color ?? colorScheme.outlineVariant;

    if (label != null) {
      return _buildLabeledDivider(context, dividerColor);
    }

    if (isVertical) {
      return VerticalDivider(
        width: width ?? 1,
        thickness: _getThickness(),
        indent: indent,
        endIndent: endIndent,
        color: dividerColor,
      );
    }

    return Divider(
      height: height ?? 1,
      thickness: _getThickness(),
      indent: indent,
      endIndent: endIndent,
      color: dividerColor,
    );
  }

  Widget _buildLabeledDivider(BuildContext context, Color dividerColor) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: (height ?? AppSpacing.md) / 2),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              height: 1,
              thickness: _getThickness(),
              indent: indent,
              color: dividerColor,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              label!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              height: 1,
              thickness: _getThickness(),
              endIndent: endIndent,
              color: dividerColor,
            ),
          ),
        ],
      ),
    );
  }
}
