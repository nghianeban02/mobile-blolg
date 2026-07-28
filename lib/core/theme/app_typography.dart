import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_palette.dart';

/// Typography helpers — mirror web `font-vi-title`, `readable-content`, brand serif.
///
/// Important: page/section titles use **Inter** (`.font-vi-title` / sans), not Playfair.
/// Playfair italic is reserved for the Nook wordmark / brand only.
abstract final class AppTypography {
  /// Large page title — web `uiPageTitle`: text-3xl font-semibold tracking-tight.
  static TextStyle pageTitle(BuildContext context, {Color? color}) {
    final p = context.palette;
    return GoogleFonts.inter(
      fontSize: 30,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: -0.4,
      color: color ?? p.foreground,
    );
  }

  /// Section heading — web `uiSectionTitle`: text-xl font-semibold.
  static TextStyle sectionTitle(BuildContext context, {Color? color}) {
    final p = context.palette;
    return GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: -0.2,
      color: color ?? p.foreground,
    );
  }

  /// Card / article title — web `readable-title` text-xl.
  static TextStyle cardTitle(
    BuildContext context, {
    Color? color,
    double size = 20,
  }) {
    final p = context.palette;
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: color ?? p.foreground,
    );
  }

  /// Body / excerpt — web `readable-content` text-sm leading-relaxed.
  static TextStyle body(
    BuildContext context, {
    Color? color,
    double size = 14,
  }) {
    final p = context.palette;
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: FontWeight.w400,
      height: 1.625,
      color: color ?? p.muted,
    );
  }

  /// Muted subtitle under headers — web text-sm leading-relaxed text-muted.
  static TextStyle subtitle(BuildContext context, {Color? color}) {
    final p = context.palette;
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.625,
      color: color ?? p.muted,
    );
  }

  /// Small accent label — web text-xs font-medium text-brown.
  static TextStyle accentLabel(BuildContext context, {Color? color}) {
    final p = context.palette;
    return GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.3,
      color: color ?? p.accent,
    );
  }

  /// Uppercase section eyebrow — web text-sm font-bold uppercase tracking-widest.
  static TextStyle sectionEyebrow(BuildContext context, {Color? color}) {
    final p = context.palette;
    return GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 2.4,
      height: 1.2,
      color: color ?? p.accent,
    );
  }

  /// Meta / date — web text-[10px] uppercase tracking-wide text-muted/70.
  static TextStyle meta(BuildContext context, {Color? color}) {
    final p = context.palette;
    return GoogleFonts.inter(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.8,
      height: 1.3,
      color: color ?? p.muted.withValues(alpha: 0.7),
    );
  }

  /// Field label — web `uiFieldLabel`: text-xs font-medium text-muted.
  static TextStyle fieldLabel(BuildContext context) {
    final p = context.palette;
    return GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: p.muted,
    );
  }

  /// Button label — web text-sm font-medium.
  static TextStyle button(
    BuildContext context, {
    double size = 14,
    Color? color,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: FontWeight.w500,
      height: 1.2,
      color: color,
    );
  }
}
