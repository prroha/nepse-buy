import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';

/// Shimmer animation wrapper that creates a loading effect.
///
/// Wraps child widgets with a subtle animated shimmer gradient
/// to indicate loading state.
///
/// Example:
/// ```dart
/// Shimmer(
///   child: Container(
///     width: 100,
///     height: 20,
///     color: Colors.grey,
///   ),
/// )
/// ```
class Shimmer extends StatefulWidget {
  /// The child widget to apply shimmer effect to.
  final Widget child;

  /// Duration of one shimmer animation cycle.
  final Duration duration;

  /// Whether the shimmer animation is enabled.
  final bool enabled;

  /// Base color for the shimmer gradient.
  final Color? baseColor;

  /// Highlight color for the shimmer gradient.
  final Color? highlightColor;

  const Shimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.enabled = true,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    if (widget.enabled) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(Shimmer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = widget.baseColor ??
        (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0));
    final highlightColor = widget.highlightColor ??
        (isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5));

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlidingGradientTransform(
                slidePercent: _controller.value,
              ),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Transform for sliding the gradient across the shimmer.
class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * (slidePercent * 2 - 1),
      0,
      0,
    );
  }
}

/// A rectangular skeleton placeholder with configurable size and border radius.
///
/// This is the base building block for skeleton loading states.
///
/// Example:
/// ```dart
/// SkeletonBox(
///   width: 100,
///   height: 20,
///   borderRadius: BorderRadius.circular(4),
/// )
/// ```
class SkeletonBox extends StatelessWidget {
  /// Width of the skeleton. If null, expands to fill available width.
  final double? width;

  /// Height of the skeleton. Required.
  final double height;

  /// Border radius of the skeleton.
  final BorderRadius? borderRadius;

  /// Whether to enable shimmer animation.
  final bool shimmer;

  /// Custom color override.
  final Color? color;

  /// Margin around the skeleton.
  final EdgeInsetsGeometry? margin;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius,
    this.shimmer = true,
    this.color,
    this.margin,
  });

  /// Creates a small skeleton box (8px height).
  const SkeletonBox.small({
    super.key,
    this.width,
    this.borderRadius,
    this.shimmer = true,
    this.color,
    this.margin,
  }) : height = 8;

  /// Creates a medium skeleton box (16px height).
  const SkeletonBox.medium({
    super.key,
    this.width,
    this.borderRadius,
    this.shimmer = true,
    this.color,
    this.margin,
  }) : height = 16;

  /// Creates a large skeleton box (24px height).
  const SkeletonBox.large({
    super.key,
    this.width,
    this.borderRadius,
    this.shimmer = true,
    this.color,
    this.margin,
  }) : height = 24;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor = color ??
        (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0));

    Widget box = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: borderRadius ?? AppSpacing.borderRadiusSm,
      ),
    );

    if (shimmer) {
      return Shimmer(child: box);
    }
    return box;
  }
}

/// A circular skeleton placeholder.
///
/// Example:
/// ```dart
/// SkeletonCircle(size: 48) // 48x48 circle
/// ```
class SkeletonCircle extends StatelessWidget {
  /// Diameter of the circle.
  final double size;

  /// Whether to enable shimmer animation.
  final bool shimmer;

  /// Custom color override.
  final Color? color;

  /// Margin around the skeleton.
  final EdgeInsetsGeometry? margin;

  const SkeletonCircle({
    super.key,
    required this.size,
    this.shimmer = true,
    this.color,
    this.margin,
  });

  /// Extra small circle (24px).
  const SkeletonCircle.xs({
    super.key,
    this.shimmer = true,
    this.color,
    this.margin,
  }) : size = 24;

  /// Small circle (32px).
  const SkeletonCircle.sm({
    super.key,
    this.shimmer = true,
    this.color,
    this.margin,
  }) : size = 32;

  /// Medium circle (40px).
  const SkeletonCircle.md({
    super.key,
    this.shimmer = true,
    this.color,
    this.margin,
  }) : size = 40;

  /// Large circle (48px).
  const SkeletonCircle.lg({
    super.key,
    this.shimmer = true,
    this.color,
    this.margin,
  }) : size = 48;

  /// Extra large circle (64px).
  const SkeletonCircle.xl({
    super.key,
    this.shimmer = true,
    this.color,
    this.margin,
  }) : size = 64;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor = color ??
        (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0));

    Widget circle = Container(
      width: size,
      height: size,
      margin: margin,
      decoration: BoxDecoration(
        color: effectiveColor,
        shape: BoxShape.circle,
      ),
    );

    if (shimmer) {
      return Shimmer(child: circle);
    }
    return circle;
  }
}

/// A text skeleton with configurable lines.
///
/// Example:
/// ```dart
/// SkeletonText(lines: 3) // 3 lines of text
/// ```
class SkeletonText extends StatelessWidget {
  /// Number of lines to show.
  final int lines;

  /// Height of each line.
  final double lineHeight;

  /// Space between lines.
  final double lineSpacing;

  /// Whether the last line should be shorter.
  final bool lastLineShort;

  /// Width factor for the last line (0.0 to 1.0).
  final double lastLineWidthFactor;

  /// Whether to enable shimmer animation.
  final bool shimmer;

  /// Custom color override.
  final Color? color;

  const SkeletonText({
    super.key,
    this.lines = 1,
    this.lineHeight = 14,
    this.lineSpacing = 8,
    this.lastLineShort = true,
    this.lastLineWidthFactor = 0.6,
    this.shimmer = true,
    this.color,
  });

  /// Creates a heading skeleton (larger text).
  const SkeletonText.heading({
    super.key,
    this.lines = 1,
    this.lastLineShort = false,
    this.lastLineWidthFactor = 0.6,
    this.shimmer = true,
    this.color,
  })  : lineHeight = 24,
        lineSpacing = 8;

  /// Creates a paragraph skeleton (multiple lines).
  const SkeletonText.paragraph({
    super.key,
    this.lines = 3,
    this.lastLineShort = true,
    this.lastLineWidthFactor = 0.7,
    this.shimmer = true,
    this.color,
  })  : lineHeight = 14,
        lineSpacing = 8;

  @override
  Widget build(BuildContext context) {
    if (lines == 1) {
      return SkeletonBox(
        height: lineHeight,
        shimmer: shimmer,
        color: color,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(lines, (index) {
        final isLast = index == lines - 1;
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : lineSpacing),
          child: FractionallySizedBox(
            widthFactor: isLast && lastLineShort ? lastLineWidthFactor : 1.0,
            child: SkeletonBox(
              height: lineHeight,
              shimmer: shimmer,
              color: color,
            ),
          ),
        );
      }),
    );
  }
}

/// A skeleton for avatar with optional text.
///
/// Example:
/// ```dart
/// SkeletonAvatar(
///   size: SkeletonAvatarSize.md,
///   showText: true,
/// )
/// ```
class SkeletonAvatar extends StatelessWidget {
  /// Size of the avatar.
  final SkeletonAvatarSize size;

  /// Whether to show name/subtitle text placeholders.
  final bool showText;

  /// Whether to enable shimmer animation.
  final bool shimmer;

  const SkeletonAvatar({
    super.key,
    this.size = SkeletonAvatarSize.md,
    this.showText = false,
    this.shimmer = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!showText) {
      return SkeletonCircle(size: size.dimension, shimmer: shimmer);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SkeletonCircle(size: size.dimension, shimmer: shimmer),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SkeletonBox(
                width: 100,
                height: 14,
                shimmer: shimmer,
              ),
              const SizedBox(height: 6),
              SkeletonBox(
                width: 70,
                height: 12,
                shimmer: shimmer,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Avatar size options.
enum SkeletonAvatarSize {
  xs(24),
  sm(32),
  md(40),
  lg(48),
  xl(64);

  final double dimension;
  const SkeletonAvatarSize(this.dimension);
}

/// A skeleton for button placeholders.
///
/// Example:
/// ```dart
/// SkeletonButton(size: SkeletonButtonSize.md)
/// ```
class SkeletonButton extends StatelessWidget {
  /// Size of the button.
  final SkeletonButtonSize size;

  /// Whether to expand to full width.
  final bool fullWidth;

  /// Whether to enable shimmer animation.
  final bool shimmer;

  const SkeletonButton({
    super.key,
    this.size = SkeletonButtonSize.md,
    this.fullWidth = false,
    this.shimmer = true,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: fullWidth ? null : size.width,
      height: size.height,
      borderRadius: AppSpacing.borderRadiusMd,
      shimmer: shimmer,
    );
  }
}

/// Button size options.
enum SkeletonButtonSize {
  sm(32, 80),
  md(40, 100),
  lg(48, 120);

  final double height;
  final double width;
  const SkeletonButtonSize(this.height, this.width);
}

/// A skeleton for image placeholders.
///
/// Example:
/// ```dart
/// SkeletonImage(
///   aspectRatio: SkeletonImageAspectRatio.video,
/// )
/// ```
class SkeletonImage extends StatelessWidget {
  /// Aspect ratio of the image.
  final SkeletonImageAspectRatio aspectRatio;

  /// Border radius.
  final BorderRadius? borderRadius;

  /// Whether to enable shimmer animation.
  final bool shimmer;

  /// Fixed height (overrides aspect ratio).
  final double? height;

  const SkeletonImage({
    super.key,
    this.aspectRatio = SkeletonImageAspectRatio.video,
    this.borderRadius,
    this.shimmer = true,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);

    Widget image = AspectRatio(
      aspectRatio: aspectRatio.value,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: borderRadius ?? AppSpacing.borderRadiusMd,
        ),
      ),
    );

    if (height != null) {
      image = Container(
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: borderRadius ?? AppSpacing.borderRadiusMd,
        ),
      );
    }

    if (shimmer) {
      return Shimmer(child: image);
    }
    return image;
  }
}

/// Image aspect ratio options.
enum SkeletonImageAspectRatio {
  square(1.0),
  portrait(3 / 4),
  video(16 / 9),
  wide(2 / 1);

  final double value;
  const SkeletonImageAspectRatio(this.value);
}
