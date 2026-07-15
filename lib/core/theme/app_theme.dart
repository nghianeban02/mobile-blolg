import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';

/// Theme editorial: nền kem, accent nâu, typography Playfair + Inter.
class AppTheme {
  AppTheme._();

  static ThemeData buildLightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryBrown,
      brightness: Brightness.light,
      surface: AppColors.homeBackground,
    );

    final base = ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.homeBackground,
      splashFactory: InkRipple.splashFactory,
    );

    final inter = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: AppColors.homeTextDark,
      displayColor: AppColors.homeTextDark,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.homeBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: inter.copyWith(
        headlineLarge: GoogleFonts.playfairDisplay(
          textStyle: inter.headlineLarge,
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
          color: AppColors.homeTextDark,
        ),
        headlineMedium: GoogleFonts.playfairDisplay(
          textStyle: inter.headlineMedium,
          fontWeight: FontWeight.w600,
          color: AppColors.homeTextDark,
        ),
        titleLarge: GoogleFonts.playfairDisplay(
          textStyle: inter.titleLarge,
          fontWeight: FontWeight.w600,
          color: AppColors.homeTextDark,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        contentTextStyle: GoogleFonts.inter(color: Colors.white),
      ),
    );
  }

  static ThemeData buildDarkTheme() {
    const background = Color(0xFF171411);
    const surface = Color(0xFF231F1B);
    const foreground = Color(0xFFF4EEE8);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryBrown,
      brightness: Brightness.dark,
      surface: surface,
    );
    final base = ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
    );
    final inter = GoogleFonts.interTextTheme(
      base.textTheme,
    ).apply(bodyColor: foreground, displayColor: foreground);
    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: foreground,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: const CardThemeData(color: surface),
      textTheme: inter.copyWith(
        headlineLarge: GoogleFonts.playfairDisplay(
          textStyle: inter.headlineLarge,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
        headlineMedium: GoogleFonts.playfairDisplay(
          textStyle: inter.headlineMedium,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
        titleLarge: GoogleFonts.playfairDisplay(
          textStyle: inter.titleLarge,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        contentTextStyle: GoogleFonts.inter(color: Colors.white),
      ),
    );
  }
}
