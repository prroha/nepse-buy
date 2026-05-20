import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/layout/error_page.dart';
import '../../router/routes.dart';

/// A screen displayed when a route is not found (404).
///
/// This screen provides a user-friendly message and navigation options
/// to help users recover from the error.
///
/// Example:
/// ```dart
/// // In router errorBuilder:
/// errorBuilder: (context, state) => const NotFoundScreen(),
/// ```
class NotFoundScreen extends StatelessWidget {
  /// The path that was not found.
  final String? path;

  const NotFoundScreen({
    super.key,
    this.path,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorPage.notFound(
      onPrimaryAction: () => context.go(Routes.home),
      onSecondaryAction: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(Routes.home);
        }
      },
    );
  }
}
