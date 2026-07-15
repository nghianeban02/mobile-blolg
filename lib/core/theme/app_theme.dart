import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';

/// Theme editorial "Nook" — đồng bộ web-blog: nền kem, accent nâu terracotta,
/// bo góc mềm (radius tokens), nút pill, typography Playfair + Inter.
class AppTheme {
  AppTheme._();

  static ThemeData buildLightTheme() {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primaryBrown,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primaryBrown,
          surface: AppColors.surface,
          onSurface: AppColors.homeTextDark,
          error: AppColors.error,
          outline: AppColors.borderStrong,
          outlineVariant: AppColors.border,
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
      textTheme: _editorialTextTheme(inter, AppColors.homeTextDark),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _pillButtonStyle().copyWith(
          backgroundColor: const WidgetStatePropertyAll(
            AppColors.primaryBrown,
          ),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _pillButtonStyle().copyWith(
          backgroundColor: const WidgetStatePropertyAll(
            AppColors.primaryBrown,
          ),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          elevation: const WidgetStatePropertyAll(0),
          shadowColor: WidgetStatePropertyAll(
            AppColors.primaryBrown.withValues(alpha: 0.22),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _pillButtonStyle().copyWith(
          foregroundColor: const WidgetStatePropertyAll(
            AppColors.homeTextDark,
          ),
          side: const WidgetStatePropertyAll(
            BorderSide(color: AppColors.borderStrong),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryBrown,
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: _inputTheme(
        fill: AppColors.homeTextDark.withValues(alpha: 0.04),
        hintColor: AppColors.homeTextLight,
        accent: AppColors.primaryBrown,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.homeTextDark,
        shape: const StadiumBorder(),
        contentTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData buildDarkTheme() {
    const background = AppColors.darkBackground;
    const surface = AppColors.darkSurface;
    const foreground = AppColors.darkForeground;
    const accent = AppColors.darkAccent;

    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primaryBrown,
          brightness: Brightness.dark,
        ).copyWith(
          primary: accent,
          surface: surface,
          onSurface: foreground,
          error: AppColors.error,
          outline: AppColors.darkBorder,
          outlineVariant: AppColors.darkBorder,
        );

    final base = ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      splashFactory: InkRipple.splashFactory,
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
      textTheme: _editorialTextTheme(inter, foreground),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _pillButtonStyle().copyWith(
          backgroundColor: const WidgetStatePropertyAll(accent),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _pillButtonStyle().copyWith(
          backgroundColor: const WidgetStatePropertyAll(accent),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          elevation: const WidgetStatePropertyAll(0),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _pillButtonStyle().copyWith(
          foregroundColor: const WidgetStatePropertyAll(foreground),
          side: const WidgetStatePropertyAll(
            BorderSide(color: AppColors.darkBorder),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: _inputTheme(
        fill: Colors.white.withValues(alpha: 0.06),
        hintColor: AppColors.darkMuted,
        accent: accent,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surface,
        shape: const StadiumBorder(),
        contentTextStyle: GoogleFonts.inter(
          color: foreground,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// Playfair Display italic cho display / brand, Inter cho phần còn lại —
  /// giống web (--font-playfair chỉ dùng cho brand & page titles).
  static TextTheme _editorialTextTheme(TextTheme inter, Color color) {
    return inter.copyWith(
      headlineLarge: GoogleFonts.playfairDisplay(
        textStyle: inter.headlineLarge,
        fontWeight: FontWeight.w700,
        fontStyle: FontStyle.italic,
        color: color,
      ),
      headlineMedium: GoogleFonts.playfairDisplay(
        textStyle: inter.headlineMedium,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      titleLarge: GoogleFonts.playfairDisplay(
        textStyle: inter.titleLarge,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  /// Pill button chuẩn web: rounded-full, min-height 44, px-5 py-2.5.
  static ButtonStyle _pillButtonStyle() {
    return ButtonStyle(
      shape: const WidgetStatePropertyAll(StadiumBorder()),
      minimumSize: const WidgetStatePropertyAll(Size(44, 44)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      textStyle: WidgetStatePropertyAll(
        GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  /// Input filled chuẩn web (uiField): nền ink/4, bo rounded-xl, không viền,
  /// focus ring accent.
  static InputDecorationTheme _inputTheme({
    required Color fill,
    required Color hintColor,
    required Color accent,
  }) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      hintStyle: GoogleFonts.inter(color: hintColor, fontSize: 15),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: AppRadius.input,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.input,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.input,
        borderSide: BorderSide(
          color: accent.withValues(alpha: 0.45),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.input,
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.input,
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }
}
