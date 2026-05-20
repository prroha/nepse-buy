import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/sync/sync_service.dart';
import 'presentation/router/app_router.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/auth/app_lock_screen.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Eager bootstrap — wires the outbox flusher to connectivity changes and
    // tries a first flush. Reading the provider has the side-effect; we
    // don't care about its value.
    ref.watch(syncBootstrapProvider);

    final router = ref.watch(routerProvider);
    final themeState = ref.watch(themeProvider);

    // Get the theme notifier to access theme data methods
    final themeNotifier = ref.watch(themeProvider.notifier);

    // Show loading indicator while theme is being loaded
    if (themeState.isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: themeNotifier.getThemeData(Brightness.light),
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp.router(
      title: 'Starter App',
      debugShowCheckedModeBanner: false,
      theme: themeNotifier.getThemeData(Brightness.light),
      darkTheme: themeNotifier.getThemeData(Brightness.dark),
      themeMode: themeState.flutterThemeMode,
      routerConfig: router,
      builder: (context, child) =>
          AppLockGate(child: child ?? const SizedBox.shrink()),
    );
  }
}
