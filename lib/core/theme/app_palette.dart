import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_colors.dart';

/// Theme-aware color tokens — mirror CSS `--app-*` light/dark.
class AppPalette {
  final Brightness brightness;
  final Color background;
  final Color foreground;
  final Color muted;
  final Color accent;
  final Color surface;
  final Color border;
  final Color borderStrong;
  final Color hover;
  final Color coverTeal;
  final Color coverSand;
  final Color success;
  final Color warning;
  final Color danger;

  const AppPalette._({
    required this.brightness,
    required this.background,
    required this.foreground,
    required this.muted,
    required this.accent,
    required this.surface,
    required this.border,
    required this.borderStrong,
    required this.hover,
    required this.coverTeal,
    required this.coverSand,
    required this.success,
    required this.warning,
    required this.danger,
  });

  bool get isDark => brightness == Brightness.dark;

  static const light = AppPalette._(
    brightness: Brightness.light,
    background: AppColors.homeBackground,
    foreground: AppColors.homeTextDark,
    muted: AppColors.homeTextLight,
    accent: AppColors.primaryBrown,
    surface: AppColors.surface,
    border: AppColors.border,
    borderStrong: AppColors.borderStrong,
    hover: AppColors.hoverWash,
    coverTeal: AppColors.coverTeal,
    coverSand: AppColors.coverSand,
    success: AppColors.success,
    warning: AppColors.warning,
    danger: AppColors.error,
  );

  static const dark = AppPalette._(
    brightness: Brightness.dark,
    background: AppColors.darkBackground,
    foreground: AppColors.darkForeground,
    muted: AppColors.darkMuted,
    accent: AppColors.darkAccent,
    surface: AppColors.darkSurface,
    border: AppColors.darkBorder,
    borderStrong: AppColors.darkBorderStrong,
    hover: AppColors.darkHover,
    coverTeal: AppColors.darkCoverTeal,
    coverSand: AppColors.darkCoverSand,
    success: AppColors.darkSuccess,
    warning: AppColors.darkWarning,
    danger: AppColors.darkDanger,
  );

  static AppPalette of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }

  /// Soft field fill — web `bg-ink/[0.04]` / dark `bg-white/[0.05]`.
  Color get fieldFill => isDark
      ? Colors.white.withValues(alpha: 0.05)
      : foreground.withValues(alpha: 0.04);

  /// Empty-state wash — web `bg-ink/[0.02]`.
  Color get emptyWash => foreground.withValues(alpha: 0.02);

  /// Soft accent chip — web `bg-brown/10`.
  Color get accentSoft => accent.withValues(alpha: 0.10);

  /// Segment track — web `bg-ink/[0.05]`.
  Color get segmentTrack => foreground.withValues(alpha: 0.05);
}

extension AppPaletteX on BuildContext {
  AppPalette get palette => AppPalette.of(this);
}
