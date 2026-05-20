import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// A styled app bar with back button, title, and actions.
///
/// This is an organism-level widget that provides a consistent header
/// layout across screens.
///
/// Example:
/// ```dart
/// AppHeader(
///   title: 'Settings',
///   showBack: true,
///   actions: [
///     IconButton(icon: Icon(Icons.save), onPressed: handleSave),
///   ],
/// )
/// ```
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  /// The title displayed in the app bar.
  final String? title;

  /// Widget to display instead of a string title.
  final Widget? titleWidget;

  /// Whether to show the back button.
  final bool showBack;

  /// Custom callback for the back button.
  final VoidCallback? onBack;

  /// Action widgets displayed on the right side.
  final List<Widget>? actions;

  /// Leading widget (replaces back button if provided).
  final Widget? leading;

  /// Background color of the app bar.
  final Color? backgroundColor;

  /// Whether to center the title.
  final bool centerTitle;

  /// Elevation of the app bar.
  final double elevation;

  /// Whether to show a bottom border.
  final bool showBottomBorder;

  /// Custom bottom widget (e.g., TabBar).
  final PreferredSizeWidget? bottom;

  const AppHeader({
    super.key,
    this.title,
    this.titleWidget,
    this.showBack = true,
    this.onBack,
    this.actions,
    this.leading,
    this.backgroundColor,
    this.centerTitle = true,
    this.elevation = 0,
    this.showBottomBorder = true,
    this.bottom,
  });

  /// Creates a header with a search field.
  factory AppHeader.search({
    Key? key,
    required Widget searchField,
    bool showBack = true,
    VoidCallback? onBack,
    List<Widget>? actions,
  }) {
    return AppHeader(
      key: key,
      titleWidget: searchField,
      showBack: showBack,
      onBack: onBack,
      actions: actions,
      centerTitle: false,
    );
  }

  /// Creates a transparent header.
  const AppHeader.transparent({
    super.key,
    this.title,
    this.titleWidget,
    this.showBack = true,
    this.onBack,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.bottom,
  })  : backgroundColor = Colors.transparent,
        elevation = 0,
        showBottomBorder = false;

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: titleWidget ?? (title != null ? Text(title!) : null),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? AppColors.surface,
      elevation: elevation,
      leading: leading ??
          (showBack
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                )
              : null),
      automaticallyImplyLeading: false,
      actions: actions,
      bottom: bottom ??
          (showBottomBorder
              ? const PreferredSize(
                  preferredSize: Size.fromHeight(1),
                  child: Divider(height: 1, color: AppColors.border),
                )
              : null),
      titleTextStyle: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
      ),
    );
  }
}
