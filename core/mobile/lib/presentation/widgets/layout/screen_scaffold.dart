import 'package:flutter/material.dart';
import '../organisms/app_header.dart';

/// A scaffold wrapper with optional header, body, FAB, and bottom navigation.
///
/// This is a layout-level widget that provides a consistent screen structure
/// across the application.
///
/// Example:
/// ```dart
/// ScreenScaffold(
///   title: 'Home',
///   showBack: false,
///   body: ListView(...),
///   floatingActionButton: FloatingActionButton(...),
///   bottomNavigationBar: BottomNavBar(...),
/// )
/// ```
class ScreenScaffold extends StatelessWidget {
  /// The main content of the screen.
  final Widget body;

  /// The title displayed in the app bar.
  final String? title;

  /// Widget to display instead of a string title.
  final Widget? titleWidget;

  /// Whether to show the back button.
  final bool showBack;

  /// Custom callback for the back button.
  final VoidCallback? onBack;

  /// Action widgets displayed in the app bar.
  final List<Widget>? actions;

  /// Leading widget in the app bar.
  final Widget? leading;

  /// Background color of the scaffold.
  final Color? backgroundColor;

  /// Whether to use safe area.
  final bool useSafeArea;

  /// Whether to show the app bar.
  final bool showAppBar;

  /// Custom app bar widget.
  final PreferredSizeWidget? appBar;

  /// Floating action button.
  final Widget? floatingActionButton;

  /// Position of the floating action button.
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  /// Bottom navigation bar.
  final Widget? bottomNavigationBar;

  /// Drawer widget.
  final Widget? drawer;

  /// End drawer widget.
  final Widget? endDrawer;

  /// Whether the body should extend behind the app bar.
  final bool extendBodyBehindAppBar;

  /// Whether the body should extend behind the bottom navigation bar.
  final bool extendBody;

  /// Resize to avoid bottom inset (keyboard).
  final bool resizeToAvoidBottomInset;

  /// Custom bottom widget (e.g., TabBar).
  final PreferredSizeWidget? bottom;

  const ScreenScaffold({
    super.key,
    required this.body,
    this.title,
    this.titleWidget,
    this.showBack = true,
    this.onBack,
    this.actions,
    this.leading,
    this.backgroundColor,
    this.useSafeArea = false,
    this.showAppBar = true,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.extendBodyBehindAppBar = false,
    this.extendBody = false,
    this.resizeToAvoidBottomInset = true,
    this.bottom,
  });

  /// Creates a scaffold with no app bar.
  const ScreenScaffold.noAppBar({
    super.key,
    required this.body,
    this.backgroundColor,
    this.useSafeArea = true,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.resizeToAvoidBottomInset = true,
  })  : title = null,
        titleWidget = null,
        showBack = false,
        onBack = null,
        actions = null,
        leading = null,
        showAppBar = false,
        appBar = null,
        extendBodyBehindAppBar = false,
        extendBody = false,
        bottom = null;

  /// Creates a scaffold with tabs.
  const ScreenScaffold.tabbed({
    super.key,
    required this.body,
    required this.bottom,
    this.title,
    this.titleWidget,
    this.showBack = false,
    this.onBack,
    this.actions,
    this.leading,
    this.backgroundColor,
    this.useSafeArea = false,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.resizeToAvoidBottomInset = true,
  })  : showAppBar = true,
        appBar = null,
        extendBodyBehindAppBar = false,
        extendBody = false;

  @override
  Widget build(BuildContext context) {
    Widget content = body;

    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    return Scaffold(
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.surface,
      appBar: appBar ??
          (showAppBar
              ? AppHeader(
                  title: title,
                  titleWidget: titleWidget,
                  showBack: showBack,
                  onBack: onBack,
                  actions: actions,
                  leading: leading,
                  bottom: bottom,
                )
              : null),
      body: content,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      endDrawer: endDrawer,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      extendBody: extendBody,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}
