import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';

/// A reusable scaffold for authentication screens.
///
/// Provides consistent layout with:
/// - Centered content with max width constraint
/// - Optional branding icon
/// - Optional app bar with back button
/// - Consistent padding and spacing
///
/// Example:
/// ```dart
/// AuthScaffold(
///   title: 'Welcome Back',
///   subtitle: 'Sign in to continue',
///   icon: Icons.apps_rounded,
///   showBackButton: false,
///   child: Column(...),
/// )
/// ```
class AuthScaffold extends StatelessWidget {
  /// The main content of the auth screen (typically the form).
  final Widget child;

  /// Whether to show a back button in the app bar.
  final bool showBackButton;

  /// Callback when back button is pressed. Uses Navigator.pop by default.
  final VoidCallback? onBack;

  /// Optional bottom widget (e.g., "Already have an account? Sign In" link).
  final Widget? bottomWidget;

  /// The icon to display in the branding area.
  final IconData? icon;

  /// Maximum width for the content.
  final double maxWidth;

  /// Whether to use safe area.
  final bool useSafeArea;

  const AuthScaffold({
    super.key,
    required this.child,
    this.showBackButton = false,
    this.onBack,
    this.bottomWidget,
    this.icon,
    this.maxWidth = 400,
    this.useSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: showBackButton
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
                onPressed: onBack ?? () => Navigator.of(context).pop(),
              ),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Branding icon
                  if (icon != null) ...[
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          icon,
                          size: 48,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    AppSpacing.gapLg,
                  ],

                  // Main content
                  child,

                  // Bottom widget (navigation links)
                  if (bottomWidget != null) ...[
                    AppSpacing.gapLg,
                    bottomWidget!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A themed card container for auth forms.
///
/// Provides consistent styling for auth screen cards with:
/// - Theme-aware background and shadow
/// - Optional title and subtitle headers
/// - Content padding
///
/// Example:
/// ```dart
/// AuthCard(
///   title: 'Welcome Back',
///   subtitle: 'Sign in to continue',
///   child: Column(children: [...formFields]),
/// )
/// ```
class AuthCard extends StatelessWidget {
  /// The main content of the card.
  final Widget child;

  /// Optional title displayed at the top.
  final String? title;

  /// Optional subtitle displayed below the title.
  final String? subtitle;

  /// Custom padding for the card content.
  final EdgeInsetsGeometry? padding;

  const AuthCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: padding ?? AppSpacing.cardContentPadding,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withAlpha(20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          if (title != null) ...[
            Text(
              title!,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              AppSpacing.gapXs,
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            AppSpacing.gapLg,
          ],

          // Content
          child,
        ],
      ),
    );
  }
}

/// A dismissible error banner for displaying error messages.
///
/// Provides consistent error display with:
/// - Theme-aware colors
/// - Error icon
/// - Dismiss button
///
/// Example:
/// ```dart
/// if (errorMessage != null)
///   ErrorBanner(
///     message: errorMessage,
///     onDismiss: () => clearError(),
///   ),
/// ```
class ErrorBanner extends StatelessWidget {
  /// The error message to display.
  final String message;

  /// Callback when the dismiss button is pressed.
  final VoidCallback? onDismiss;

  /// The icon to display. Defaults to error_outline.
  final IconData icon;

  const ErrorBanner({
    super.key,
    required this.message,
    this.onDismiss,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.error),
          AppSpacing.gapHSm,
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colorScheme.error),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: Icon(Icons.close, color: colorScheme.error, size: 18),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

/// An info banner for displaying informational messages.
///
/// Example:
/// ```dart
/// InfoBanner(
///   message: 'Need a new verification link? Sign in and request one.',
/// )
/// ```
class InfoBanner extends StatelessWidget {
  /// The message to display.
  final String message;

  /// The icon to display. Defaults to info_outline.
  final IconData icon;

  const InfoBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withAlpha(77),
        borderRadius: AppSpacing.borderRadiusSm,
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary, size: 20),
          AppSpacing.gapHSm,
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A navigation link row for auth screens.
///
/// Displays a "prompt text + action link" pattern commonly used in auth screens.
///
/// Example:
/// ```dart
/// AuthNavLink(
///   prompt: "Don't have an account?",
///   actionLabel: 'Sign Up',
///   onAction: () => context.go(Routes.register),
///   isLoading: isLoading,
/// )
/// ```
class AuthNavLink extends StatelessWidget {
  /// The prompt text (e.g., "Don't have an account?").
  final String prompt;

  /// The action button label (e.g., "Sign Up").
  final String actionLabel;

  /// Callback when the action button is pressed.
  final VoidCallback? onAction;

  /// Whether the action button should be disabled (e.g., during loading).
  final bool isLoading;

  const AuthNavLink({
    super.key,
    required this.prompt,
    required this.actionLabel,
    this.onAction,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          prompt,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        TextButton(
          onPressed: isLoading ? null : onAction,
          child: Text(
            actionLabel,
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
