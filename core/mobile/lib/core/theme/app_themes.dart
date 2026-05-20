import 'package:flutter/material.dart';

/// App-Type Specific Theme Configurations
///
/// Color palettes based on color psychology research to optimize
/// user experience for different application types.
/// Matches the web design system exactly.

// =====================================================
// Type Definitions
// =====================================================

/// Enum representing different app types with their specific themes
enum AppThemeType {
  educational,
  finance,
  ecommerce,
  accounting,
  notes,
  health,
  social,
  creative,
}

/// Extension to provide additional properties for AppThemeType
extension AppThemeTypeExtension on AppThemeType {
  /// Get the string identifier for the theme type
  String get id {
    switch (this) {
      case AppThemeType.educational:
        return 'edu';
      case AppThemeType.finance:
        return 'finance';
      case AppThemeType.ecommerce:
        return 'ecommerce';
      case AppThemeType.accounting:
        return 'accounting';
      case AppThemeType.notes:
        return 'notes';
      case AppThemeType.health:
        return 'health';
      case AppThemeType.social:
        return 'social';
      case AppThemeType.creative:
        return 'creative';
    }
  }

  /// Get AppThemeType from string id
  static AppThemeType? fromId(String id) {
    switch (id) {
      case 'edu':
      case 'educational':
        return AppThemeType.educational;
      case 'finance':
        return AppThemeType.finance;
      case 'ecommerce':
        return AppThemeType.ecommerce;
      case 'accounting':
        return AppThemeType.accounting;
      case 'notes':
        return AppThemeType.notes;
      case 'health':
        return AppThemeType.health;
      case 'social':
        return AppThemeType.social;
      case 'creative':
        return AppThemeType.creative;
      default:
        return null;
    }
  }
}

/// Colors for a specific theme including semantic colors
class AppThemeColors {
  /// Primary brand color
  final Color primary;

  /// Foreground color for text on primary
  final Color primaryForeground;

  /// Accent/highlight color
  final Color accent;

  /// Foreground color for text on accent
  final Color accentForeground;

  /// Main background color
  final Color background;

  /// Main foreground/text color
  final Color foreground;

  /// Card/surface background color
  final Color card;

  /// Border color
  final Color border;

  /// Success status color
  final Color success;

  /// Warning status color
  final Color warning;

  /// Error/destructive color
  final Color error;

  /// Info status color
  final Color info;

  /// Secondary background color
  final Color backgroundSecondary;

  /// Muted text color
  final Color textMuted;

  const AppThemeColors({
    required this.primary,
    required this.primaryForeground,
    required this.accent,
    required this.accentForeground,
    required this.background,
    required this.foreground,
    required this.card,
    required this.border,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.backgroundSecondary,
    required this.textMuted,
  });

  /// Create a copy with optional overrides
  AppThemeColors copyWith({
    Color? primary,
    Color? primaryForeground,
    Color? accent,
    Color? accentForeground,
    Color? background,
    Color? foreground,
    Color? card,
    Color? border,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? backgroundSecondary,
    Color? textMuted,
  }) {
    return AppThemeColors(
      primary: primary ?? this.primary,
      primaryForeground: primaryForeground ?? this.primaryForeground,
      accent: accent ?? this.accent,
      accentForeground: accentForeground ?? this.accentForeground,
      background: background ?? this.background,
      foreground: foreground ?? this.foreground,
      card: card ?? this.card,
      border: border ?? this.border,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      backgroundSecondary: backgroundSecondary ?? this.backgroundSecondary,
      textMuted: textMuted ?? this.textMuted,
    );
  }
}

/// Configuration for a complete app theme
class AppThemeConfig {
  /// Unique identifier for the theme
  final String id;

  /// Human-readable name
  final String name;

  /// Brief description of the theme
  final String description;

  /// Color psychology explanation
  final String psychology;

  /// Light mode colors
  final AppThemeColors lightColors;

  /// Dark mode colors
  final AppThemeColors darkColors;

  const AppThemeConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.psychology,
    required this.lightColors,
    required this.darkColors,
  });
}

// =====================================================
// Shared Semantic Colors
// =====================================================

const _semanticColorsLight = (
  success: Color(0xFF16A34A),
  successLight: Color(0xFFDCFCE7),
  warning: Color(0xFFD97706),
  warningLight: Color(0xFFFEF3C7),
  error: Color(0xFFDC2626),
  errorLight: Color(0xFFFEE2E2),
  info: Color(0xFF0284C7),
  infoLight: Color(0xFFE0F2FE),
);

const _semanticColorsDark = (
  success: Color(0xFF22C55E),
  successLight: Color(0xFF166534),
  warning: Color(0xFFF59E0B),
  warningLight: Color(0xFF78350F),
  error: Color(0xFFEF4444),
  errorLight: Color(0xFF7F1D1D),
  info: Color(0xFF38BDF8),
  infoLight: Color(0xFF0C4A6E),
);

// =====================================================
// Educational Theme
// =====================================================

/// Educational theme - Enhances focus and information retention
/// Primary: Deep Blue (#1E40AF) - Trust, intelligence, stability
/// Accent: Amber (#F59E0B) - Attention, warmth, highlighting
const educationalTheme = AppThemeConfig(
  id: 'edu',
  name: 'Educational',
  description: 'Optimized for learning platforms and educational content',
  psychology:
      'Enhances focus and information retention through calming blues and attention-grabbing amber accents',
  lightColors: AppThemeColors(
    primary: Color(0xFF1E40AF),
    primaryForeground: Color(0xFFFFFFFF),
    accent: Color(0xFFF59E0B),
    accentForeground: Color(0xFF1C1917),
    background: Color(0xFFF8FAFC),
    foreground: Color(0xFF0F172A),
    card: Color(0xFFFFFFFF),
    border: Color(0xFFE2E8F0),
    success: Color(0xFF16A34A),
    warning: Color(0xFFD97706),
    error: Color(0xFFDC2626),
    info: Color(0xFF0284C7),
    backgroundSecondary: Color(0xFFF1F5F9),
    textMuted: Color(0xFF94A3B8),
  ),
  darkColors: AppThemeColors(
    primary: Color(0xFF3B82F6),
    primaryForeground: Color(0xFFFFFFFF),
    accent: Color(0xFFFBBF24),
    accentForeground: Color(0xFF1C1917),
    background: Color(0xFF0F172A),
    foreground: Color(0xFFF8FAFC),
    card: Color(0xFF1E293B),
    border: Color(0xFF334155),
    success: Color(0xFF22C55E),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    info: Color(0xFF38BDF8),
    backgroundSecondary: Color(0xFF1E293B),
    textMuted: Color(0xFF64748B),
  ),
);

// =====================================================
// Finance Theme
// =====================================================

/// Finance theme - Instills confidence and security
/// Primary: Navy (#1E3A5F) - Trust, security, professionalism
/// Accent: Emerald (#059669) - Growth, prosperity, success
const financeTheme = AppThemeConfig(
  id: 'finance',
  name: 'Finance',
  description: 'Designed for banking, investment, and financial applications',
  psychology:
      'Instills confidence and security through navy blues and growth-oriented greens',
  lightColors: AppThemeColors(
    primary: Color(0xFF1E3A5F),
    primaryForeground: Color(0xFFFFFFFF),
    accent: Color(0xFF059669),
    accentForeground: Color(0xFFFFFFFF),
    background: Color(0xFFF8FAFC),
    foreground: Color(0xFF0F172A),
    card: Color(0xFFFFFFFF),
    border: Color(0xFFE2E8F0),
    success: Color(0xFF16A34A),
    warning: Color(0xFFD97706),
    error: Color(0xFFDC2626),
    info: Color(0xFF0284C7),
    backgroundSecondary: Color(0xFFF1F5F9),
    textMuted: Color(0xFF94A3B8),
  ),
  darkColors: AppThemeColors(
    primary: Color(0xFF3B82F6),
    primaryForeground: Color(0xFFFFFFFF),
    accent: Color(0xFF10B981),
    accentForeground: Color(0xFF0F172A),
    background: Color(0xFF0C1222),
    foreground: Color(0xFFF8FAFC),
    card: Color(0xFF162032),
    border: Color(0xFF1E3048),
    success: Color(0xFF22C55E),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    info: Color(0xFF38BDF8),
    backgroundSecondary: Color(0xFF162032),
    textMuted: Color(0xFF64748B),
  ),
);

// =====================================================
// E-commerce Theme
// =====================================================

/// E-commerce theme - Encourages action and conversion
/// Primary: Orange (#EA580C) - Energy, urgency, call-to-action
/// Accent: Blue (#3B82F6) - Trust, reliability, links
const ecommerceTheme = AppThemeConfig(
  id: 'ecommerce',
  name: 'E-commerce',
  description: 'Optimized for online shopping and marketplace platforms',
  psychology:
      'Encourages action through warm orange while maintaining trust with reliable blue accents',
  lightColors: AppThemeColors(
    primary: Color(0xFFEA580C),
    primaryForeground: Color(0xFFFFFFFF),
    accent: Color(0xFF3B82F6),
    accentForeground: Color(0xFFFFFFFF),
    background: Color(0xFFFAFAF9),
    foreground: Color(0xFF1C1917),
    card: Color(0xFFFFFFFF),
    border: Color(0xFFE7E5E4),
    success: Color(0xFF16A34A),
    warning: Color(0xFFD97706),
    error: Color(0xFFDC2626),
    info: Color(0xFF0284C7),
    backgroundSecondary: Color(0xFFF5F5F4),
    textMuted: Color(0xFFA8A29E),
  ),
  darkColors: AppThemeColors(
    primary: Color(0xFFF97316),
    primaryForeground: Color(0xFFFFFFFF),
    accent: Color(0xFF60A5FA),
    accentForeground: Color(0xFF1C1917),
    background: Color(0xFF1C1917),
    foreground: Color(0xFFFAFAF9),
    card: Color(0xFF292524),
    border: Color(0xFF44403C),
    success: Color(0xFF22C55E),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    info: Color(0xFF38BDF8),
    backgroundSecondary: Color(0xFF292524),
    textMuted: Color(0xFF78716C),
  ),
);

// =====================================================
// Accounting Theme
// =====================================================

/// Accounting theme - Professional and detail-oriented
/// Primary: Slate (#475569) - Precision, professionalism, neutrality
/// Accent: Teal (#0D9488) - Clarity, balance, accuracy
const accountingTheme = AppThemeConfig(
  id: 'accounting',
  name: 'Accounting',
  description: 'Designed for bookkeeping, invoicing, and accounting software',
  psychology:
      'Professional, detail-oriented feel with precision slate and clarity teal',
  lightColors: AppThemeColors(
    primary: Color(0xFF475569),
    primaryForeground: Color(0xFFFFFFFF),
    accent: Color(0xFF0D9488),
    accentForeground: Color(0xFFFFFFFF),
    background: Color(0xFFF8FAFC),
    foreground: Color(0xFF1E293B),
    card: Color(0xFFFFFFFF),
    border: Color(0xFFCBD5E1),
    success: Color(0xFF16A34A),
    warning: Color(0xFFD97706),
    error: Color(0xFFDC2626),
    info: Color(0xFF0284C7),
    backgroundSecondary: Color(0xFFF1F5F9),
    textMuted: Color(0xFF94A3B8),
  ),
  darkColors: AppThemeColors(
    primary: Color(0xFF94A3B8),
    primaryForeground: Color(0xFF0F172A),
    accent: Color(0xFF2DD4BF),
    accentForeground: Color(0xFF0F172A),
    background: Color(0xFF0F172A),
    foreground: Color(0xFFF1F5F9),
    card: Color(0xFF1E293B),
    border: Color(0xFF334155),
    success: Color(0xFF22C55E),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    info: Color(0xFF38BDF8),
    backgroundSecondary: Color(0xFF1E293B),
    textMuted: Color(0xFF64748B),
  ),
);

// =====================================================
// Notes/Productivity Theme
// =====================================================

/// Notes theme - Minimal distractions for flow state
/// Primary: Lime (#65A30D) - Growth, freshness, productivity
/// Accent: Cream (#FEF3C7) - Warmth, comfort, paper-like
const notesTheme = AppThemeConfig(
  id: 'notes',
  name: 'Notes & Productivity',
  description: 'Optimized for note-taking, task management, and productivity apps',
  psychology:
      'Minimal distractions with soft sage for growth and warm cream for comfort to encourage flow state',
  lightColors: AppThemeColors(
    primary: Color(0xFF65A30D),
    primaryForeground: Color(0xFFFFFFFF),
    accent: Color(0xFFFEF3C7),
    accentForeground: Color(0xFF1A1A1A),
    background: Color(0xFFFEFDFB),
    foreground: Color(0xFF1A1A1A),
    card: Color(0xFFFFFFFF),
    border: Color(0xFFE5E5E5),
    success: Color(0xFF16A34A),
    warning: Color(0xFFD97706),
    error: Color(0xFFDC2626),
    info: Color(0xFF0284C7),
    backgroundSecondary: Color(0xFFFAF8F5),
    textMuted: Color(0xFFA3A3A3),
  ),
  darkColors: AppThemeColors(
    primary: Color(0xFF84CC16),
    primaryForeground: Color(0xFF1A1A1A),
    accent: Color(0xFFFDE68A),
    accentForeground: Color(0xFF1A1A1A),
    background: Color(0xFF171717),
    foreground: Color(0xFFFAFAFA),
    card: Color(0xFF262626),
    border: Color(0xFF404040),
    success: Color(0xFF22C55E),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    info: Color(0xFF38BDF8),
    backgroundSecondary: Color(0xFF262626),
    textMuted: Color(0xFF737373),
  ),
);

// =====================================================
// Health/Wellness Theme
// =====================================================

/// Health theme - Promotes relaxation and trust
/// Primary: Teal (#14B8A6) - Healing, calm, balance
/// Accent: Lavender (#A78BFA) - Relaxation, wellness, spirituality
const healthTheme = AppThemeConfig(
  id: 'health',
  name: 'Health & Wellness',
  description: 'Designed for healthcare, fitness, and wellness applications',
  psychology:
      'Promotes relaxation and trust in care through healing teal and calming lavender',
  lightColors: AppThemeColors(
    primary: Color(0xFF14B8A6),
    primaryForeground: Color(0xFFFFFFFF),
    accent: Color(0xFFA78BFA),
    accentForeground: Color(0xFFFFFFFF),
    background: Color(0xFFF0FDFA),
    foreground: Color(0xFF134E4A),
    card: Color(0xFFFFFFFF),
    border: Color(0xFF99F6E4),
    success: Color(0xFF16A34A),
    warning: Color(0xFFD97706),
    error: Color(0xFFDC2626),
    info: Color(0xFF0284C7),
    backgroundSecondary: Color(0xFFE6FFFA),
    textMuted: Color(0xFF5EADA5),
  ),
  darkColors: AppThemeColors(
    primary: Color(0xFF2DD4BF),
    primaryForeground: Color(0xFF0F1F1D),
    accent: Color(0xFFC4B5FD),
    accentForeground: Color(0xFF1E1B4B),
    background: Color(0xFF0F1F1D),
    foreground: Color(0xFFF0FDFA),
    card: Color(0xFF1A2F2C),
    border: Color(0xFF264541),
    success: Color(0xFF22C55E),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    info: Color(0xFF38BDF8),
    backgroundSecondary: Color(0xFF1A2F2C),
    textMuted: Color(0xFF5EEAD4),
  ),
);

// =====================================================
// Social Theme
// =====================================================

/// Social theme - Encourages engagement and community
/// Primary: Blue (#2563EB) - Connection, trust, communication
/// Accent: Orange (#F97316) - Energy, warmth, interaction
const socialTheme = AppThemeConfig(
  id: 'social',
  name: 'Social',
  description:
      'Optimized for social networks, community platforms, and messaging apps',
  psychology:
      'Encourages engagement and community through vibrant connection blue and energetic coral warmth',
  lightColors: AppThemeColors(
    primary: Color(0xFF2563EB),
    primaryForeground: Color(0xFFFFFFFF),
    accent: Color(0xFFF97316),
    accentForeground: Color(0xFFFFFFFF),
    background: Color(0xFFF8FAFC),
    foreground: Color(0xFF0F172A),
    card: Color(0xFFFFFFFF),
    border: Color(0xFFE2E8F0),
    success: Color(0xFF16A34A),
    warning: Color(0xFFD97706),
    error: Color(0xFFDC2626),
    info: Color(0xFF0284C7),
    backgroundSecondary: Color(0xFFF1F5F9),
    textMuted: Color(0xFF94A3B8),
  ),
  darkColors: AppThemeColors(
    primary: Color(0xFF3B82F6),
    primaryForeground: Color(0xFFFFFFFF),
    accent: Color(0xFFFB923C),
    accentForeground: Color(0xFF1C1917),
    background: Color(0xFF0A0F1A),
    foreground: Color(0xFFF9FAFB),
    card: Color(0xFF111827),
    border: Color(0xFF1F2937),
    success: Color(0xFF22C55E),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    info: Color(0xFF38BDF8),
    backgroundSecondary: Color(0xFF111827),
    textMuted: Color(0xFF6B7280),
  ),
);

// =====================================================
// Creative Theme
// =====================================================

/// Creative theme - Sparks creativity and inspiration
/// Primary: Purple (#7C3AED) - Imagination, creativity, innovation
/// Accent: Rose (#FB7185) - Inspiration, passion, warmth
const creativeTheme = AppThemeConfig(
  id: 'creative',
  name: 'Creative',
  description: 'Designed for design tools, art platforms, and creative applications',
  psychology:
      'Sparks creativity and inspiration through imaginative purple and warm inspirational coral',
  lightColors: AppThemeColors(
    primary: Color(0xFF7C3AED),
    primaryForeground: Color(0xFFFFFFFF),
    accent: Color(0xFFFB7185),
    accentForeground: Color(0xFFFFFFFF),
    background: Color(0xFFFAF5FF),
    foreground: Color(0xFF1E1B4B),
    card: Color(0xFFFFFFFF),
    border: Color(0xFFDDD6FE),
    success: Color(0xFF16A34A),
    warning: Color(0xFFD97706),
    error: Color(0xFFDC2626),
    info: Color(0xFF0284C7),
    backgroundSecondary: Color(0xFFF3E8FF),
    textMuted: Color(0xFF7C3AED),
  ),
  darkColors: AppThemeColors(
    primary: Color(0xFFA78BFA),
    primaryForeground: Color(0xFF13111C),
    accent: Color(0xFFFDA4AF),
    accentForeground: Color(0xFF1E1B4B),
    background: Color(0xFF13111C),
    foreground: Color(0xFFF5F3FF),
    card: Color(0xFF1E1B2E),
    border: Color(0xFF2E2844),
    success: Color(0xFF22C55E),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    info: Color(0xFF38BDF8),
    backgroundSecondary: Color(0xFF1E1B2E),
    textMuted: Color(0xFFA78BFA),
  ),
);

// =====================================================
// Theme Registry
// =====================================================

/// Map of all available app themes
const Map<AppThemeType, AppThemeConfig> appThemes = {
  AppThemeType.educational: educationalTheme,
  AppThemeType.finance: financeTheme,
  AppThemeType.ecommerce: ecommerceTheme,
  AppThemeType.accounting: accountingTheme,
  AppThemeType.notes: notesTheme,
  AppThemeType.health: healthTheme,
  AppThemeType.social: socialTheme,
  AppThemeType.creative: creativeTheme,
};

// =====================================================
// Utility Functions
// =====================================================

/// Get theme configuration by app type
AppThemeConfig getThemeByType(AppThemeType type) {
  return appThemes[type] ?? educationalTheme;
}

/// Get theme colors for a specific mode
AppThemeColors getThemeColors(AppThemeType type, Brightness brightness) {
  final theme = getThemeByType(type);
  return brightness == Brightness.dark ? theme.darkColors : theme.lightColors;
}

/// Get all available app theme types
List<AppThemeType> getAvailableThemeTypes() {
  return AppThemeType.values;
}

/// Check if a string is a valid app theme type
bool isValidThemeType(String typeId) {
  return AppThemeTypeExtension.fromId(typeId) != null;
}

/// Generate a complete Flutter ThemeData from app theme configuration
ThemeData generateThemeData(AppThemeType type, Brightness brightness) {
  final colors = getThemeColors(type, brightness);
  final isDark = brightness == Brightness.dark;

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: colors.primary,
      onPrimary: colors.primaryForeground,
      secondary: colors.accent,
      onSecondary: colors.accentForeground,
      error: colors.error,
      onError: Colors.white,
      surface: colors.card,
      onSurface: colors.foreground,
      surfaceContainerHighest: colors.backgroundSecondary,
    ),
    scaffoldBackgroundColor: colors.background,
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: colors.card,
      foregroundColor: colors.foreground,
      iconTheme: IconThemeData(color: colors.foreground),
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.border, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? colors.backgroundSecondary : colors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      hintStyle: TextStyle(color: colors.textMuted),
      labelStyle: TextStyle(color: colors.foreground),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: colors.primary,
        foregroundColor: colors.primaryForeground,
        elevation: 0,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: colors.primary,
        foregroundColor: colors.primaryForeground,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide(color: colors.border),
        foregroundColor: colors.foreground,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colors.primary,
      foregroundColor: colors.primaryForeground,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: colors.backgroundSecondary,
      labelStyle: TextStyle(color: colors.foreground),
      side: BorderSide(color: colors.border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: colors.border,
      thickness: 1,
    ),
    iconTheme: IconThemeData(
      color: colors.textMuted,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: colors.textMuted,
      textColor: colors.foreground,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: colors.card,
      selectedItemColor: colors.primary,
      unselectedItemColor: colors.textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colors.card,
      indicatorColor: colors.primary.withOpacity(0.1),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: colors.primary);
        }
        return IconThemeData(color: colors.textMuted);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(
            color: colors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          );
        }
        return TextStyle(
          color: colors.textMuted,
          fontSize: 12,
        );
      }),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: colors.primary,
      unselectedLabelColor: colors.textMuted,
      indicatorColor: colors.primary,
      dividerColor: colors.border,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: colors.foreground,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: isDark ? colors.card : colors.foreground,
      contentTextStyle: TextStyle(
        color: isDark ? colors.foreground : colors.card,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colors.primary,
      linearTrackColor: colors.border,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colors.primary;
        }
        return colors.textMuted;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colors.primary.withOpacity(0.5);
        }
        return colors.border;
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colors.primary;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(colors.primaryForeground),
      side: BorderSide(color: colors.border, width: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colors.primary;
        }
        return colors.textMuted;
      }),
    ),
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: colors.foreground,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: colors.foreground,
        letterSpacing: -0.25,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: colors.foreground,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: colors.foreground,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colors.foreground,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colors.foreground,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: colors.foreground,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: colors.foreground,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: colors.textMuted,
        height: 1.5,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: colors.foreground,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: colors.foreground,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: colors.textMuted,
        letterSpacing: 0.5,
      ),
    ),
  );
}

// =====================================================
// Theme Provider Helper
// =====================================================

/// A utility class to manage app themes with easy switching
class AppThemeManager {
  /// Current theme type
  final AppThemeType themeType;

  /// Current brightness mode
  final Brightness brightness;

  const AppThemeManager({
    this.themeType = AppThemeType.educational,
    this.brightness = Brightness.light,
  });

  /// Get the current theme configuration
  AppThemeConfig get config => getThemeByType(themeType);

  /// Get the current theme colors
  AppThemeColors get colors => getThemeColors(themeType, brightness);

  /// Get the generated ThemeData
  ThemeData get themeData => generateThemeData(themeType, brightness);

  /// Create a copy with different settings
  AppThemeManager copyWith({
    AppThemeType? themeType,
    Brightness? brightness,
  }) {
    return AppThemeManager(
      themeType: themeType ?? this.themeType,
      brightness: brightness ?? this.brightness,
    );
  }

  /// Get light theme data
  ThemeData get lightTheme => generateThemeData(themeType, Brightness.light);

  /// Get dark theme data
  ThemeData get darkTheme => generateThemeData(themeType, Brightness.dark);
}

// =====================================================
// Theme Color Extensions
// =====================================================

/// Extension to access theme colors from BuildContext
extension ThemeColorsExtension on BuildContext {
  /// Get the current AppThemeColors from the theme
  /// Note: This requires the theme to be generated using generateThemeData
  AppThemeColors get appColors {
    final theme = Theme.of(this);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AppThemeColors(
      primary: colorScheme.primary,
      primaryForeground: colorScheme.onPrimary,
      accent: colorScheme.secondary,
      accentForeground: colorScheme.onSecondary,
      background: theme.scaffoldBackgroundColor,
      foreground: colorScheme.onSurface,
      card: colorScheme.surface,
      border: theme.dividerTheme.color ?? colorScheme.outline,
      success: isDark ? const Color(0xFF22C55E) : const Color(0xFF16A34A),
      warning: isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706),
      error: colorScheme.error,
      info: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
      backgroundSecondary: colorScheme.surfaceContainerHighest,
      textMuted: theme.textTheme.bodySmall?.color ?? colorScheme.onSurface.withOpacity(0.6),
    );
  }
}
