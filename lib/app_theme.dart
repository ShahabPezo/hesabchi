import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF1463D9);
  static const primaryDark = Color(0xFF0D47A1);
  static const navy = Color(0xFF0F2B55);
  static const canvas = Color(0xFFF6F8FC);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF15233A);
  static const mutedText = Color(0xFF66758C);
  static const success = Color(0xFF16834A);
  static const warning = Color(0xFFB86900);
  static const danger = Color(0xFFC33434);
  static const outline = Color(0xFFD9E1EE);
}

abstract final class AppTheme {
  static const fontFamily = 'Vazirmatn';

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      primary: AppColors.primary,
      surface: isDark ? const Color(0xFF121A29) : AppColors.surface,
      error: AppColors.danger,
    );
    final baseText = ThemeData(brightness: brightness).textTheme.apply(
      fontFamily: fontFamily,
      bodyColor: isDark ? const Color(0xFFF0F4FC) : AppColors.text,
      displayColor: isDark ? const Color(0xFFF0F4FC) : AppColors.text,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF0B1220)
          : AppColors.canvas,
      textTheme: baseText.copyWith(
        displaySmall: baseText.displaySmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        headlineSmall: baseText.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        titleLarge: baseText.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: baseText.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseText.bodyLarge?.copyWith(height: 1.65),
        bodyMedium: baseText.bodyMedium?.copyWith(height: 1.6),
        labelLarge: baseText.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? const Color(0xFFF0F4FC) : AppColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: baseText.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? const Color(0xFF172235) : AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark ? const Color(0xFF24344E) : AppColors.outline,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF172235) : AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF24344E) : AppColors.outline,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF24344E) : AppColors.outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF121A29) : AppColors.surface,
        indicatorColor: isDark
            ? const Color(0xFF1D427C)
            : const Color(0xFFDDEAFF),
        labelTextStyle: WidgetStatePropertyAll(
          baseText.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? const Color(0xFF24344E) : AppColors.outline,
        space: 1,
      ),
    );
  }
}
