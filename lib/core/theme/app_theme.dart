import 'package:flutter/material.dart';

/// Design tokens for Mamny (Manajemen Uang Kos)
/// Flat Minimalist design system without gradients to prevent visual fatigue.
class AppColors {
  AppColors._();

  // Background & Surfaces
  static const Color background = Color(0xFFF8F9FA); // Soft Off-White
  static const Color surface = Color(0xFFFFFFFF); // Pure White
  static const Color card = Color(0xFFFFFFFF); // Pure White

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0); // Thin Slate Border (1px)
  static const Color divider = Color(0xFFE2E8F0);

  // Typography Colors
  static const Color textPrimary = Color(0xFF0F172A); // Deep Slate (High Contrast)
  static const Color textSecondary = Color(0xFF475569); // Muted Slate
  static const Color textTertiary = Color(0xFF94A3B8); // Light Slate for subtle hints

  // Primary Accent Colors (Calm Teal / Emerald)
  static const Color accent = Color(0xFF0D9488); // Calm Teal / Emerald
  static const Color accentDark = Color(0xFF0F766E); // Darker Teal for pressed states
  static const Color accentLight = Color(0xFFCCFBF1); // Soft Teal Tint
  static const Color accentBackground = Color(0xFFF0FDFA); // Subtle Teal Surface

  // Warning & Danger (Solid Coral Red)
  static const Color danger = Color(0xFFE11D48); // Solid Coral Red
  static const Color dangerBadgeBg = Color(0xFFFFE4E6); // Soft Coral Pink for "Kesenangan Sementara" badge
  static const Color dangerText = Color(0xFFBE123C); // High contrast red for text on badge

  // Success / Need Badge (Calm Green / Teal)
  static const Color success = Color(0xFF0D9488);
  static const Color successBadgeBg = Color(0xFFCCFBF1);
  static const Color successText = Color(0xFF0F766E);
}

/// Typography hierarchy tailored for financial clarity & high readability.
class AppTypography {
  AppTypography._();

  static const String? defaultFontFamily = null; // System sans-serif (Roboto on Android, San Francisco on iOS)

  /// Nominal uang utama: 28sp, Bold
  static const TextStyle mainAmount = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  /// Judul Section: 18sp, SemiBold
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
    height: 1.3,
  );

  /// Body Text: 15sp, Regular (nyaman dibaca semua kalangan)
  static const TextStyle body = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.45,
  );

  /// Body Text Muted: 15sp, Regular
  static const TextStyle bodySecondary = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.45,
  );

  /// Caption / Label: 13sp, Medium
  static const TextStyle caption = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.1,
    height: 1.3,
  );

  /// Small Badge / Tag: 12sp, SemiBold
  static const TextStyle badge = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    height: 1.2,
  );
}

/// Spatial and border radius tokens to maintain clean visual balance.
class AppSpacing {
  AppSpacing._();

  /// Standar padding luar layar: 20px
  static const double screenPaddingValue = 20.0;
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: screenPaddingValue,
    vertical: screenPaddingValue,
  );
  static const EdgeInsets screenPaddingHorizontal = EdgeInsets.symmetric(
    horizontal: screenPaddingValue,
  );

  /// Jarak standar antar elemen: 16px
  static const double elementSpacingValue = 16.0;
  static const SizedBox gap16 = SizedBox(
    height: elementSpacingValue,
    width: elementSpacingValue,
  );
  static const SizedBox gap8 = SizedBox(height: 8.0, width: 8.0);
  static const SizedBox gap12 = SizedBox(height: 12.0, width: 12.0);
  static const SizedBox gap20 = SizedBox(height: 20.0, width: 20.0);
  static const SizedBox gap24 = SizedBox(height: 24.0, width: 24.0);

  /// Border radius konsisten: 12px
  static const double radiusValue = 12.0;
  static final BorderRadius radius12 = BorderRadius.circular(radiusValue);
  static final RoundedRectangleBorder shapeRounded12 = RoundedRectangleBorder(
    borderRadius: radius12,
  );

  /// Thin border (1px) consistent definition
  static const BorderSide thinBorderSide = BorderSide(
    color: AppColors.border,
    width: 1.0,
  );

  static final RoundedRectangleBorder borderedCardShape = RoundedRectangleBorder(
    borderRadius: radius12,
    side: thinBorderSide,
  );
}

/// Theme configuration with zero gradients and zero elevation.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.accent,

      colorScheme: const ColorScheme.light(
        primary: AppColors.accent,
        onPrimary: Colors.white,
        primaryContainer: AppColors.accentLight,
        onPrimaryContainer: AppColors.accentDark,
        secondary: AppColors.textSecondary,
        onSecondary: Colors.white,
        error: AppColors.danger,
        onError: Colors.white,
        errorContainer: AppColors.dangerBadgeBg,
        onErrorContainer: AppColors.dangerText,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        outline: AppColors.border,
      ),

      // App Bar Theme (Clean flat)
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),

      // Card Theme (Elevation: 0, 1px border, 12px radius)
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: AppSpacing.borderedCardShape,
        clipBehavior: Clip.antiAlias,
      ),

      // Elevated Button Theme (Primary Calm Teal action button)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: AppSpacing.shapeRounded12,
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: AppSpacing.thinBorderSide,
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: AppSpacing.shapeRounded12,
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: AppSpacing.shapeRounded12,
        ),
      ),

      // Input Decoration (Flat, 12px radius, 1px border)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: AppTypography.caption,
        labelStyle: AppTypography.caption,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.radius12,
          borderSide: AppSpacing.thinBorderSide,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.radius12,
          borderSide: AppSpacing.thinBorderSide,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.radius12,
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.radius12,
          borderSide: const BorderSide(color: AppColors.danger, width: 1.0),
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // Text Theme with required hierarchy
      textTheme: const TextTheme(
        displayLarge: AppTypography.mainAmount,
        headlineMedium: AppTypography.sectionTitle,
        bodyLarge: AppTypography.body,
        bodyMedium: AppTypography.bodySecondary,
        labelMedium: AppTypography.caption,
        labelSmall: AppTypography.badge,
      ),
    );
  }
}
