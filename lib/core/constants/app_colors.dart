import 'package:flutter/material.dart';

/// Centralized color palette for the application.
/// Đồng bộ với design tokens của web-blog (globals.css / @theme).
class AppColors {
  static const Color success = Color(0xFF15803D); // --app-success
  static const Color error = Color(0xFFDC2626); // --app-danger
  static const Color warning = Color(0xFFB45309); // --app-warning
  static const Color white = Color(0xFFFFFFFF);

  // Editorial palette (đồng bộ design tokens của web-blog)
  static const Color homeBackground = Color(0xFFF9F8F6); // --app-bg (cream)
  static const Color homeTextDark = Color(0xFF1A1A1A); // --app-fg (ink)
  static const Color homeTextLight = Color(0xFF6B6B6B); // --app-muted
  static const Color primaryBrown = Color(0xFF8D5A47); // --app-accent
  static const Color headerIconBg = Color(0xFFECAE7D);
  static const Color coverTeal = Color(0xFF9CCCBF); // --app-cover-teal
  static const Color coverSand = Color(0xFFE8C496); // --app-cover-sand

  // Surface & border tokens (web: --app-surface / --app-border / --app-hover)
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0x14000000); // rgb(0 0 0 / 0.08)
  static const Color borderStrong = Color(0x1F000000); // rgb(0 0 0 / 0.12)
  static const Color hoverWash = Color(0x0A000000); // rgb(0 0 0 / 0.04)

  // Dark mode tokens (web .dark)
  static const Color darkBackground = Color(0xFF121110);
  static const Color darkSurface = Color(0xFF1C1B19);
  static const Color darkForeground = Color(0xFFEDEAE6);
  static const Color darkMuted = Color(0xFFA3A09A);
  static const Color darkAccent = Color(0xFFC4886F);
  static const Color darkBorder = Color(0x1AFFFFFF); // rgb(255 255 255 / 0.1)
  static const Color darkBorderStrong = Color(0x24FFFFFF); // rgb(255 255 255 / 0.14)
  static const Color darkHover = Color(0x0FFFFFFF); // rgb(255 255 255 / 0.06)
  static const Color darkCoverTeal = Color(0xFF3D5C56);
  static const Color darkCoverSand = Color(0xFF5C4A38);
  static const Color darkSuccess = Color(0xFF4ADE80);
  static const Color darkWarning = Color(0xFFFBBF24);
  static const Color darkDanger = Color(0xFFF87171);
}

/// Border radius tokens — web: --app-radius-sm/md/lg/xl.
class AppRadius {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 22;

  /// Cards / surface panels (rounded-[var(--app-radius-xl)]).
  static BorderRadius get card => BorderRadius.circular(xl);

  /// Inputs (rounded-xl trên web).
  static BorderRadius get input => BorderRadius.circular(md);

  /// Pill buttons / chips (rounded-full).
  static BorderRadius get pill => BorderRadius.circular(999);
}

/// Shadow tokens — web: --app-shadow-soft / --app-shadow-lift.
class AppShadows {
  static List<BoxShadow> get soft => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get lift => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 40,
      offset: const Offset(0, 16),
    ),
  ];

  /// Shadow nâu cho primary button (web: rgba(141,90,71,0.22)).
  static List<BoxShadow> get primaryButton => [
    BoxShadow(
      color: AppColors.primaryBrown.withValues(alpha: 0.22),
      blurRadius: 12,
      offset: const Offset(0, 2),
    ),
  ];
}
