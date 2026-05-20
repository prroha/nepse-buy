import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../atoms/app_button.dart';

/// Enum representing different error page variants.
enum ErrorPageVariant {
  /// Page not found (404) error.
  notFound,

  /// Server error (500) error.
  serverError,

  /// Network connectivity error.
  networkError,

  /// Generic error.
  generic,

  /// Permission/access denied error.
  accessDenied,

  /// Session expired error.
  sessionExpired,
}

/// A full-screen error page widget with customizable content.
///
/// This widget provides a consistent error display across the app with
/// different variants for common error types. It supports dark mode
/// and follows the app's design system.
///
/// Example:
/// ```dart
/// ErrorPage(
///   variant: ErrorPageVariant.notFound,
///   onPrimaryAction: () => context.go('/'),
///   onSecondaryAction: () => Navigator.pop(context),
/// )
/// ```
class ErrorPage extends StatelessWidget {
  /// The type of error to display.
  final ErrorPageVariant variant;

  /// Custom title override.
  final String? title;

  /// Custom message override.
  final String? message;

  /// Custom icon override.
  final IconData? icon;

  /// Callback for the primary action button.
  final VoidCallback? onPrimaryAction;

  /// Custom label for the primary action button.
  final String? primaryActionLabel;

  /// Callback for the secondary action button.
  final VoidCallback? onSecondaryAction;

  /// Custom label for the secondary action button.
  final String? secondaryActionLabel;

  /// Whether to show an illustration.
  final bool showIllustration;

  /// Custom illustration widget.
  final Widget? customIllustration;

  const ErrorPage({
    super.key,
    this.variant = ErrorPageVariant.generic,
    this.title,
    this.message,
    this.icon,
    this.onPrimaryAction,
    this.primaryActionLabel,
    this.onSecondaryAction,
    this.secondaryActionLabel,
    this.showIllustration = true,
    this.customIllustration,
  });

  /// Creates a 404 Not Found error page.
  const ErrorPage.notFound({
    super.key,
    this.onPrimaryAction,
    this.onSecondaryAction,
    this.primaryActionLabel = 'Go Home',
    this.secondaryActionLabel = 'Go Back',
  })  : variant = ErrorPageVariant.notFound,
        title = null,
        message = null,
        icon = null,
        showIllustration = true,
        customIllustration = null;

  /// Creates a 500 Server Error page.
  const ErrorPage.serverError({
    super.key,
    this.onPrimaryAction,
    this.onSecondaryAction,
    this.primaryActionLabel = 'Try Again',
    this.secondaryActionLabel = 'Go Home',
  })  : variant = ErrorPageVariant.serverError,
        title = null,
        message = null,
        icon = null,
        showIllustration = true,
        customIllustration = null;

  /// Creates a network error page.
  const ErrorPage.networkError({
    super.key,
    this.onPrimaryAction,
    this.onSecondaryAction,
    this.primaryActionLabel = 'Retry',
    this.secondaryActionLabel,
  })  : variant = ErrorPageVariant.networkError,
        title = null,
        message = null,
        icon = null,
        showIllustration = true,
        customIllustration = null;

  String get _title {
    if (title != null) return title!;
    switch (variant) {
      case ErrorPageVariant.notFound:
        return 'Page Not Found';
      case ErrorPageVariant.serverError:
        return 'Something Went Wrong';
      case ErrorPageVariant.networkError:
        return 'No Connection';
      case ErrorPageVariant.accessDenied:
        return 'Access Denied';
      case ErrorPageVariant.sessionExpired:
        return 'Session Expired';
      case ErrorPageVariant.generic:
        return 'Error';
    }
  }

  String get _message {
    if (message != null) return message!;
    switch (variant) {
      case ErrorPageVariant.notFound:
        return 'Sorry, we couldn\'t find the page you\'re looking for. It may have been moved or deleted.';
      case ErrorPageVariant.serverError:
        return 'We encountered an unexpected error. Our team has been notified and is working to fix the issue.';
      case ErrorPageVariant.networkError:
        return 'Please check your internet connection and try again.';
      case ErrorPageVariant.accessDenied:
        return 'You don\'t have permission to access this resource.';
      case ErrorPageVariant.sessionExpired:
        return 'Your session has expired. Please sign in again to continue.';
      case ErrorPageVariant.generic:
        return 'An error occurred. Please try again.';
    }
  }

  IconData get _icon {
    if (icon != null) return icon!;
    switch (variant) {
      case ErrorPageVariant.notFound:
        return Icons.search_off_rounded;
      case ErrorPageVariant.serverError:
        return Icons.cloud_off_rounded;
      case ErrorPageVariant.networkError:
        return Icons.wifi_off_rounded;
      case ErrorPageVariant.accessDenied:
        return Icons.lock_outline_rounded;
      case ErrorPageVariant.sessionExpired:
        return Icons.timer_off_rounded;
      case ErrorPageVariant.generic:
        return Icons.error_outline_rounded;
    }
  }

  Color _getIconColor(BuildContext context) {
    final colors = context.appColors;
    switch (variant) {
      case ErrorPageVariant.notFound:
        return colors.primary;
      case ErrorPageVariant.serverError:
      case ErrorPageVariant.generic:
        return colors.error;
      case ErrorPageVariant.networkError:
        return colors.warning;
      case ErrorPageVariant.accessDenied:
        return colors.error;
      case ErrorPageVariant.sessionExpired:
        return colors.primary;
    }
  }

  Color _getIconBackgroundColor(BuildContext context) {
    final color = _getIconColor(context);
    return color.withValues(alpha: 0.1);
  }

  String get _errorCode {
    switch (variant) {
      case ErrorPageVariant.notFound:
        return '404';
      case ErrorPageVariant.serverError:
        return '500';
      case ErrorPageVariant.networkError:
      case ErrorPageVariant.accessDenied:
      case ErrorPageVariant.sessionExpired:
      case ErrorPageVariant.generic:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final iconColor = _getIconColor(context);
    final iconBgColor = _getIconBackgroundColor(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Illustration
                if (showIllustration) ...[
                  if (customIllustration != null)
                    customIllustration!
                  else
                    _buildIllustration(context, colors),
                  AppSpacing.gapLg,
                ],

                // Error code (for 404, 500)
                if (_errorCode.isNotEmpty) ...[
                  Text(
                    _errorCode,
                    style: TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                      height: 1,
                    ),
                  ),
                  AppSpacing.gapMd,
                ],

                // Icon badge
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _icon,
                    size: 40,
                    color: iconColor,
                  ),
                ),
                AppSpacing.gapLg,

                // Title
                Text(
                  _title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colors.foreground,
                  ),
                ),
                AppSpacing.gapSm,

                // Message
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: colors.mutedForeground,
                    ),
                  ),
                ),
                AppSpacing.gapXl,

                // Action buttons
                _buildActionButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIllustration(BuildContext context, AppColorScheme colors) {
    final mutedColor = colors.mutedForeground.withValues(alpha: 0.3);
    final accentColor = _getIconColor(context).withValues(alpha: 0.2);

    return SizedBox(
      width: 180,
      height: 150,
      child: CustomPaint(
        painter: _ErrorIllustrationPainter(
          variant: variant,
          mutedColor: mutedColor,
          accentColor: accentColor,
          iconColor: _getIconColor(context),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final hasSecondary = onSecondaryAction != null && secondaryActionLabel != null;

    return Column(
      children: [
        if (onPrimaryAction != null)
          AppButton(
            label: primaryActionLabel ?? 'Continue',
            onPressed: onPrimaryAction,
            variant: AppButtonVariant.primary,
            isFullWidth: true,
            icon: _getPrimaryActionIcon(),
          ),
        if (hasSecondary) ...[
          AppSpacing.gapSm,
          AppButton(
            label: secondaryActionLabel!,
            onPressed: onSecondaryAction,
            variant: AppButtonVariant.outline,
            isFullWidth: true,
            icon: _getSecondaryActionIcon(),
          ),
        ],
      ],
    );
  }

  IconData? _getPrimaryActionIcon() {
    switch (variant) {
      case ErrorPageVariant.notFound:
        return Icons.home_rounded;
      case ErrorPageVariant.serverError:
      case ErrorPageVariant.networkError:
        return Icons.refresh_rounded;
      case ErrorPageVariant.sessionExpired:
        return Icons.login_rounded;
      case ErrorPageVariant.accessDenied:
      case ErrorPageVariant.generic:
        return null;
    }
  }

  IconData? _getSecondaryActionIcon() {
    if (secondaryActionLabel == 'Go Back') {
      return Icons.arrow_back_rounded;
    }
    if (secondaryActionLabel == 'Go Home') {
      return Icons.home_rounded;
    }
    return null;
  }
}

/// Custom painter for error illustrations.
class _ErrorIllustrationPainter extends CustomPainter {
  final ErrorPageVariant variant;
  final Color mutedColor;
  final Color accentColor;
  final Color iconColor;

  _ErrorIllustrationPainter({
    required this.variant,
    required this.mutedColor,
    required this.accentColor,
    required this.iconColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = mutedColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final accentPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    final iconPaint = Paint()
      ..color = iconColor.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    switch (variant) {
      case ErrorPageVariant.notFound:
        _drawNotFoundIllustration(canvas, size, paint, accentPaint, iconPaint);
        break;
      case ErrorPageVariant.serverError:
        _drawServerErrorIllustration(canvas, size, paint, accentPaint, iconPaint);
        break;
      case ErrorPageVariant.networkError:
        _drawNetworkErrorIllustration(canvas, size, paint, accentPaint, iconPaint);
        break;
      default:
        _drawGenericIllustration(canvas, size, paint, accentPaint, iconPaint);
    }
  }

  void _drawNotFoundIllustration(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint accentPaint,
    Paint iconPaint,
  ) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Document
    final docRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(centerX, centerY), width: 80, height: 100),
      const Radius.circular(8),
    );
    canvas.drawRRect(docRect, paint);

    // Document lines
    for (var i = 0; i < 3; i++) {
      final y = centerY - 20 + (i * 15);
      canvas.drawLine(
        Offset(centerX - 25, y),
        Offset(centerX + 25 - (i * 10), y),
        paint,
      );
    }

    // Question mark circle
    canvas.drawCircle(Offset(centerX, centerY + 25), 18, accentPaint);

    // Decorative dots
    canvas.drawCircle(Offset(centerX - 55, centerY - 30), 8, accentPaint);
    canvas.drawCircle(Offset(centerX + 55, centerY + 40), 6, accentPaint);
    canvas.drawCircle(Offset(centerX + 50, centerY - 35), 4, accentPaint);
  }

  void _drawServerErrorIllustration(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint accentPaint,
    Paint iconPaint,
  ) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Monitor
    final monitorRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(centerX, centerY - 10), width: 100, height: 70),
      const Radius.circular(8),
    );
    canvas.drawRRect(monitorRect, paint);

    // Screen
    final screenRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(centerX, centerY - 10), width: 85, height: 55),
      const Radius.circular(4),
    );
    canvas.drawRRect(screenRect, accentPaint);

    // Stand
    final standPath = Path()
      ..moveTo(centerX - 10, centerY + 25)
      ..lineTo(centerX + 10, centerY + 25)
      ..lineTo(centerX, centerY + 45)
      ..close();
    canvas.drawPath(standPath, paint);

    // Base
    canvas.drawLine(
      Offset(centerX - 20, centerY + 45),
      Offset(centerX + 20, centerY + 45),
      paint,
    );

    // Error X on screen
    canvas.drawLine(
      Offset(centerX - 10, centerY - 20),
      Offset(centerX + 10, centerY),
      Paint()..color = iconColor..strokeWidth = 3..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(centerX + 10, centerY - 20),
      Offset(centerX - 10, centerY),
      Paint()..color = iconColor..strokeWidth = 3..strokeCap = StrokeCap.round,
    );

    // Decorative sparks
    _drawSpark(canvas, Offset(centerX + 60, centerY - 30), iconPaint);
    _drawSpark(canvas, Offset(centerX - 55, centerY + 10), iconPaint);
  }

  void _drawNetworkErrorIllustration(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint accentPaint,
    Paint iconPaint,
  ) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // WiFi arcs
    for (var i = 0; i < 3; i++) {
      final radius = 25.0 + (i * 20);
      final rect = Rect.fromCircle(center: Offset(centerX, centerY + 20), radius: radius);
      canvas.drawArc(rect, -2.6, 2.0, false, paint);
    }

    // WiFi dot
    canvas.drawCircle(Offset(centerX, centerY + 20), 5, paint..style = PaintingStyle.fill);

    // Cross line
    final crossPaint = Paint()
      ..color = iconColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(centerX - 40, centerY - 30),
      Offset(centerX + 40, centerY + 50),
      crossPaint,
    );

    // Decorative dots
    canvas.drawCircle(Offset(centerX - 60, centerY - 10), 6, accentPaint);
    canvas.drawCircle(Offset(centerX + 55, centerY - 20), 8, accentPaint);
  }

  void _drawGenericIllustration(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint accentPaint,
    Paint iconPaint,
  ) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Gear/cog outline
    canvas.drawCircle(Offset(centerX, centerY), 40, paint);
    canvas.drawCircle(Offset(centerX, centerY), 20, paint);

    // Broken section
    final arcPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15;
    final arcRect = Rect.fromCircle(center: Offset(centerX, centerY), radius: 30);
    canvas.drawArc(arcRect, 0.5, 1.5, false, arcPaint);

    // Decorative elements
    canvas.drawCircle(Offset(centerX + 55, centerY - 25), 6, accentPaint);
    canvas.drawCircle(Offset(centerX - 50, centerY + 30), 8, accentPaint);
  }

  void _drawSpark(Canvas canvas, Offset center, Paint paint) {
    final sparkPaint = Paint()
      ..color = paint.color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx - 5, center.dy),
      Offset(center.dx + 5, center.dy),
      sparkPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 5),
      Offset(center.dx, center.dy + 5),
      sparkPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
