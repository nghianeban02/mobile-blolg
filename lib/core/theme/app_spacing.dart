/// Spacing scale — mirror web Tailwind spacing used across Nook UI.
///
/// Prefer these over magic numbers. Page gutters match web `app-main`
/// (`px` = 1rem / 16 on mobile).
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double section = 32;
  static const double sectionLg = 40;
  static const double sectionXl = 48;

  /// Horizontal page padding — web `max(1rem, safe-area)`.
  static const double pageX = 16;

  /// Vertical page padding — web `py-5` (1.25rem).
  static const double pageY = 20;

  /// Gap under [PageHeader] — web `mb-6`.
  static const double pageHeaderBottom = 24;

  /// Gap under section titles before grids — web `mb-6`.
  static const double sectionTitleBottom = 24;

  /// Gap between major home sections — web `mb-12`.
  static const double homeSectionGap = 48;

  /// Content card inner padding — web `p-5`.
  static const double cardPadding = 20;

  /// Mobile bottom nav height — web `--mobile-nav-height: 3.5rem`.
  static const double mobileNavHeight = 56;
}
