import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Available app theme types with different color schemes
enum AppThemeType {
  /// Educational theme - Blue & Purple (default)
  educational,

  /// Corporate/Business theme - Navy & Gold
  corporate,

  /// Health/Wellness theme - Teal & Coral
  health,

  /// Creative/Design theme - Pink & Yellow
  creative,

  /// Finance theme - Green & Dark Blue
  finance,

  /// Nature/Eco theme - Green & Brown
  nature,
}

/// Extension for AppThemeType with metadata
extension AppThemeTypeExtension on AppThemeType {
  /// Display name for the theme
  String get displayName {
    switch (this) {
      case AppThemeType.educational:
        return 'Educational';
      case AppThemeType.corporate:
        return 'Corporate';
      case AppThemeType.health:
        return 'Health & Wellness';
      case AppThemeType.creative:
        return 'Creative';
      case AppThemeType.finance:
        return 'Finance';
      case AppThemeType.nature:
        return 'Nature';
    }
  }

  /// Description of the theme
  String get description {
    switch (this) {
      case AppThemeType.educational:
        return 'Blue & Purple - Perfect for learning apps';
      case AppThemeType.corporate:
        return 'Navy & Gold - Professional and elegant';
      case AppThemeType.health:
        return 'Teal & Coral - Calm and refreshing';
      case AppThemeType.creative:
        return 'Pink & Yellow - Bold and inspiring';
      case AppThemeType.finance:
        return 'Green & Blue - Trust and stability';
      case AppThemeType.nature:
        return 'Green & Brown - Organic and natural';
    }
  }

  /// Primary color for the theme
  Color get primaryColor {
    switch (this) {
      case AppThemeType.educational:
        return const Color(0xFF2563EB); // Blue
      case AppThemeType.corporate:
        return const Color(0xFF1E3A5F); // Navy
      case AppThemeType.health:
        return const Color(0xFF0D9488); // Teal
      case AppThemeType.creative:
        return const Color(0xFFDB2777); // Pink
      case AppThemeType.finance:
        return const Color(0xFF059669); // Green
      case AppThemeType.nature:
        return const Color(0xFF16A34A); // Forest Green
    }
  }

  /// Secondary/Accent color for the theme
  Color get accentColor {
    switch (this) {
      case AppThemeType.educational:
        return const Color(0xFF7C3AED); // Purple
      case AppThemeType.corporate:
        return const Color(0xFFD4A517); // Gold
      case AppThemeType.health:
        return const Color(0xFFF97316); // Coral
      case AppThemeType.creative:
        return const Color(0xFFFBBF24); // Yellow
      case AppThemeType.finance:
        return const Color(0xFF1E40AF); // Dark Blue
      case AppThemeType.nature:
        return const Color(0xFF92400E); // Brown
    }
  }

  /// Lighter variant of primary color
  Color get primaryLight {
    switch (this) {
      case AppThemeType.educational:
        return const Color(0xFF3B82F6);
      case AppThemeType.corporate:
        return const Color(0xFF2D4A6F);
      case AppThemeType.health:
        return const Color(0xFF14B8A6);
      case AppThemeType.creative:
        return const Color(0xFFEC4899);
      case AppThemeType.finance:
        return const Color(0xFF10B981);
      case AppThemeType.nature:
        return const Color(0xFF22C55E);
    }
  }

  /// Darker variant of primary color
  Color get primaryDark {
    switch (this) {
      case AppThemeType.educational:
        return const Color(0xFF1D4ED8);
      case AppThemeType.corporate:
        return const Color(0xFF152A40);
      case AppThemeType.health:
        return const Color(0xFF0F766E);
      case AppThemeType.creative:
        return const Color(0xFFBE185D);
      case AppThemeType.finance:
        return const Color(0xFF047857);
      case AppThemeType.nature:
        return const Color(0xFF15803D);
    }
  }
}

/// Theme mode options (light/dark/system)
enum AppThemeMode {
  system,
  light,
  dark,
}

/// Extension to convert between AppThemeMode and Flutter's ThemeMode
extension AppThemeModeExtension on AppThemeMode {
  ThemeMode toThemeMode() {
    switch (this) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  String get label {
    switch (this) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System';
    }
  }

  IconData get icon {
    switch (this) {
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
      case AppThemeMode.system:
        return Icons.settings_brightness;
    }
  }
}

/// Storage keys for theme preferences
const String _themeTypeStorageKey = 'app_theme_type';
const String _themeModeStorageKey = 'theme_mode';

/// Theme state class
class ThemeState {
  final AppThemeType appTheme;
  final AppThemeMode themeMode;
  final bool isLoading;

  const ThemeState({
    this.appTheme = AppThemeType.educational,
    this.themeMode = AppThemeMode.system,
    this.isLoading = true,
  });

  ThemeState copyWith({
    AppThemeType? appTheme,
    AppThemeMode? themeMode,
    bool? isLoading,
  }) {
    return ThemeState(
      appTheme: appTheme ?? this.appTheme,
      themeMode: themeMode ?? this.themeMode,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Get Flutter's ThemeMode
  ThemeMode get flutterThemeMode => themeMode.toThemeMode();
}

/// Theme notifier for managing theme state
class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(const ThemeState()) {
    _loadFromPrefs();
  }

  /// Load theme preferences from SharedPreferences
  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load theme type
      final storedThemeType = prefs.getString(_themeTypeStorageKey);
      AppThemeType appTheme = AppThemeType.educational;
      if (storedThemeType != null) {
        appTheme = AppThemeType.values.firstWhere(
          (e) => e.name == storedThemeType,
          orElse: () => AppThemeType.educational,
        );
      }

      // Load theme mode
      final storedThemeMode = prefs.getString(_themeModeStorageKey);
      AppThemeMode themeMode = AppThemeMode.system;
      if (storedThemeMode != null) {
        themeMode = AppThemeMode.values.firstWhere(
          (e) => e.name == storedThemeMode,
          orElse: () => AppThemeMode.system,
        );
      }

      state = ThemeState(
        appTheme: appTheme,
        themeMode: themeMode,
        isLoading: false,
      );
    } catch (e) {
      state = const ThemeState(
        appTheme: AppThemeType.educational,
        themeMode: AppThemeMode.system,
        isLoading: false,
      );
    }
  }

  /// Set app theme type and persist to storage
  Future<void> setAppTheme(AppThemeType theme) async {
    state = state.copyWith(appTheme: theme);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeTypeStorageKey, theme.name);
    } catch (e) {
      // Silently fail - theme is still applied in memory
    }
  }

  /// Set theme mode (light/dark/system) and persist to storage
  Future<void> setThemeMode(AppThemeMode mode) async {
    state = state.copyWith(themeMode: mode);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeStorageKey, mode.name);
    } catch (e) {
      // Silently fail - theme is still applied in memory
    }
  }

  /// Alias for setThemeMode for backward compatibility
  Future<void> setTheme(AppThemeMode mode) => setThemeMode(mode);

  /// Toggle between light and dark mode (skips system)
  Future<void> toggleTheme(BuildContext context) async {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    await setThemeMode(isDark ? AppThemeMode.light : AppThemeMode.dark);
  }

  /// Cycle through all theme modes
  Future<void> cycleThemeMode() async {
    final modes = AppThemeMode.values;
    final currentIndex = modes.indexOf(state.themeMode);
    final nextIndex = (currentIndex + 1) % modes.length;
    await setThemeMode(modes[nextIndex]);
  }

  /// Cycle through all app theme types
  Future<void> cycleAppTheme() async {
    final themes = AppThemeType.values;
    final currentIndex = themes.indexOf(state.appTheme);
    final nextIndex = (currentIndex + 1) % themes.length;
    await setAppTheme(themes[nextIndex]);
  }

  /// Get ThemeData for the current app theme and brightness
  ThemeData getThemeData(Brightness brightness) {
    final appTheme = state.appTheme;
    final isDark = brightness == Brightness.dark;

    return isDark
        ? _buildDarkTheme(appTheme)
        : _buildLightTheme(appTheme);
  }

  /// Build light theme for a given app theme type
  ThemeData _buildLightTheme(AppThemeType appTheme) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: appTheme.primaryColor,
        brightness: Brightness.light,
        primary: appTheme.primaryColor,
        secondary: appTheme.accentColor,
        error: const Color(0xFFEF4444),
        surface: const Color(0xFFFFFFFF),
      ),
      scaffoldBackgroundColor: const Color(0xFFF9FAFB),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: const Color(0xFFFFFFFF),
        foregroundColor: const Color(0xFF111827),
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: appTheme.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: appTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: appTheme.primaryColor,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5E7EB),
        thickness: 1,
      ),
      iconTheme: const IconThemeData(
        color: Color(0xFF6B7280),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Color(0xFF111827),
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF111827),
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF111827),
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF111827),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Color(0xFF111827),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Color(0xFF111827),
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF111827),
        ),
      ),
    );
  }

  /// Build dark theme for a given app theme type
  ThemeData _buildDarkTheme(AppThemeType appTheme) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: appTheme.primaryColor,
        brightness: Brightness.dark,
        primary: appTheme.primaryLight,
        secondary: appTheme.accentColor,
        error: const Color(0xFFEF4444),
        surface: const Color(0xFF1E1E1E),
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: const Color(0xFFF5F5F5),
        iconTheme: const IconThemeData(color: Color(0xFFF5F5F5)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2C2C2C)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2C2C2C)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: appTheme.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: appTheme.primaryLight,
          foregroundColor: const Color(0xFF121212),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: appTheme.primaryLight,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2C2C2C),
        thickness: 1,
      ),
      iconTheme: const IconThemeData(
        color: Color(0xFFB0B0B0),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Color(0xFFF5F5F5),
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFFF5F5F5),
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFFF5F5F5),
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFFF5F5F5),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Color(0xFFF5F5F5),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Color(0xFFF5F5F5),
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFFF5F5F5),
        ),
      ),
    );
  }
}

/// Theme provider
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});

/// Convenience provider to get the Flutter ThemeMode
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(themeProvider).flutterThemeMode;
});

/// Provider to get the current app theme type
final appThemeTypeProvider = Provider<AppThemeType>((ref) {
  return ref.watch(themeProvider).appTheme;
});

/// Provider to get the light ThemeData for the current app theme
final lightThemeDataProvider = Provider<ThemeData>((ref) {
  final themeNotifier = ref.watch(themeProvider.notifier);
  return themeNotifier.getThemeData(Brightness.light);
});

/// Provider to get the dark ThemeData for the current app theme
final darkThemeDataProvider = Provider<ThemeData>((ref) {
  final themeNotifier = ref.watch(themeProvider.notifier);
  return themeNotifier.getThemeData(Brightness.dark);
});

/// Provider to get the primary color of the current app theme
final primaryColorProvider = Provider<Color>((ref) {
  return ref.watch(themeProvider).appTheme.primaryColor;
});

/// Provider to get the accent color of the current app theme
final accentColorProvider = Provider<Color>((ref) {
  return ref.watch(themeProvider).appTheme.accentColor;
});
