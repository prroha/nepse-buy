import 'package:flutter/material.dart';

/// Text variants for different typographic styles.
enum AppTextVariant {
  /// Large heading (28px, bold)
  heading1,

  /// Medium heading (24px, bold)
  heading2,

  /// Small heading (20px, semibold)
  heading3,

  /// Section heading (18px, semibold)
  heading4,

  /// Body text (16px, regular)
  body,

  /// Smaller body text (14px, regular)
  bodySmall,

  /// Caption text (12px, regular)
  caption,

  /// Label text (14px, medium)
  label,

  /// Overline text (10px, uppercase, medium)
  overline,
}

/// A styled text widget with predefined variants.
///
/// This is an atom-level widget that provides consistent typography
/// across the application. Uses Theme.of(context) for theme-aware colors.
///
/// Example:
/// ```dart
/// AppText(
///   'Welcome Back',
///   variant: AppTextVariant.heading1,
///   textAlign: TextAlign.center,
/// )
/// ```
class AppText extends StatelessWidget {
  /// The text content to display.
  final String text;

  /// The typographic variant of the text.
  final AppTextVariant variant;

  /// Optional color override. Defaults based on variant and theme.
  final Color? color;

  /// How the text should be aligned horizontally.
  final TextAlign? textAlign;

  /// The maximum number of lines for the text.
  final int? maxLines;

  /// How visual overflow should be handled.
  final TextOverflow? overflow;

  /// Whether to apply strikethrough decoration.
  final bool strikethrough;

  /// Whether to apply underline decoration.
  final bool underline;

  const AppText(
    this.text, {
    super.key,
    this.variant = AppTextVariant.body,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.strikethrough = false,
    this.underline = false,
  });

  /// Creates a heading1 text.
  const AppText.heading1(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.strikethrough = false,
    this.underline = false,
  }) : variant = AppTextVariant.heading1;

  /// Creates a heading2 text.
  const AppText.heading2(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.strikethrough = false,
    this.underline = false,
  }) : variant = AppTextVariant.heading2;

  /// Creates a heading3 text.
  const AppText.heading3(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.strikethrough = false,
    this.underline = false,
  }) : variant = AppTextVariant.heading3;

  /// Creates a body text.
  const AppText.body(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.strikethrough = false,
    this.underline = false,
  }) : variant = AppTextVariant.body;

  /// Creates a caption text.
  const AppText.caption(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.strikethrough = false,
    this.underline = false,
  }) : variant = AppTextVariant.caption;

  /// Creates a label text.
  const AppText.label(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.strikethrough = false,
    this.underline = false,
  }) : variant = AppTextVariant.label;

  @override
  Widget build(BuildContext context) {
    return Text(
      variant == AppTextVariant.overline ? text.toUpperCase() : text,
      style: _getTextStyle(context),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  TextStyle _getTextStyle(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Theme-aware default colors
    final primaryTextColor = colorScheme.onSurface;
    final secondaryTextColor = colorScheme.onSurfaceVariant;
    final mutedTextColor = colorScheme.outline;

    final TextDecoration? decoration;
    if (strikethrough && underline) {
      decoration = TextDecoration.combine([
        TextDecoration.lineThrough,
        TextDecoration.underline,
      ]);
    } else if (strikethrough) {
      decoration = TextDecoration.lineThrough;
    } else if (underline) {
      decoration = TextDecoration.underline;
    } else {
      decoration = null;
    }

    switch (variant) {
      case AppTextVariant.heading1:
        return TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: color ?? primaryTextColor,
          decoration: decoration,
          height: 1.2,
        );
      case AppTextVariant.heading2:
        return TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: color ?? primaryTextColor,
          decoration: decoration,
          height: 1.25,
        );
      case AppTextVariant.heading3:
        return TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: color ?? primaryTextColor,
          decoration: decoration,
          height: 1.3,
        );
      case AppTextVariant.heading4:
        return TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: color ?? primaryTextColor,
          decoration: decoration,
          height: 1.35,
        );
      case AppTextVariant.body:
        return TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: color ?? primaryTextColor,
          decoration: decoration,
          height: 1.5,
        );
      case AppTextVariant.bodySmall:
        return TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: color ?? secondaryTextColor,
          decoration: decoration,
          height: 1.5,
        );
      case AppTextVariant.caption:
        return TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: color ?? mutedTextColor,
          decoration: decoration,
          height: 1.4,
        );
      case AppTextVariant.label:
        return TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: color ?? primaryTextColor,
          decoration: decoration,
          height: 1.4,
        );
      case AppTextVariant.overline:
        return TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color ?? mutedTextColor,
          letterSpacing: 1.5,
          decoration: decoration,
          height: 1.6,
        );
    }
  }
}
