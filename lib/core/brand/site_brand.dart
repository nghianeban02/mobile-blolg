import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';

/// Hằng số thương hiệu — mirror `web-blog/lib/constants/site-brand.ts`.
abstract final class SiteBrandConstants {
  static const name = 'Nook';
  static const slogan = 'Read Deep. Plan Smart. Grow Daily.';
  static const markAsset = 'assets/brand/icon.svg';
  static const markPng = 'assets/brand/nook_mark.png';
}

enum SiteBrandVariant { sidebar, header, hero, mobile }

/// Wordmark "Nook" (Playfair italic) + slogan tùy chọn — như `SiteBrand` trên web.
class SiteBrand extends StatelessWidget {
  final SiteBrandVariant variant;
  final bool showSlogan;
  final String? slogan;
  final Color? color;
  final bool showMark;
  final double? markSize;

  const SiteBrand({
    super.key,
    this.variant = SiteBrandVariant.header,
    this.showSlogan = false,
    this.slogan,
    this.color,
    this.showMark = false,
    this.markSize,
  });

  @override
  Widget build(BuildContext context) {
    final ink = color ??
        (Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkForeground
            : AppColors.homeTextDark);
    final accent = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkAccent
        : AppColors.primaryBrown;

    final nameStyle = switch (variant) {
      SiteBrandVariant.sidebar => GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.italic,
          height: 1.15,
          color: ink,
        ),
      SiteBrandVariant.header => GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.italic,
          height: 1.0,
          color: ink,
        ),
      SiteBrandVariant.hero => GoogleFonts.playfairDisplay(
          fontSize: 40,
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.italic,
          height: 1.15,
          color: ink,
        ),
      SiteBrandVariant.mobile => GoogleFonts.playfairDisplay(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.italic,
          height: 1.0,
          color: ink,
        ),
    };

    final sloganStyle = switch (variant) {
      SiteBrandVariant.sidebar => GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          height: 1.3,
          letterSpacing: 0.2,
          color: accent.withValues(alpha: 0.85),
        ),
      SiteBrandVariant.header => GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w500,
          height: 1.3,
          letterSpacing: 0.3,
          color: accent.withValues(alpha: 0.8),
        ),
      SiteBrandVariant.hero => GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.4,
          color: accent,
        ),
      SiteBrandVariant.mobile => GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w500,
          height: 1.2,
          letterSpacing: 0.4,
          color: accent.withValues(alpha: 0.8),
        ),
    };

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          SiteBrandConstants.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: nameStyle,
        ),
        if (showSlogan) ...[
          SizedBox(height: variant == SiteBrandVariant.hero ? 12 : 2),
          Text(
            slogan ?? SiteBrandConstants.slogan,
            maxLines: variant == SiteBrandVariant.hero ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: sloganStyle,
          ),
        ],
      ],
    );

    if (!showMark) return text;

    final size = markSize ?? (variant == SiteBrandVariant.hero ? 48.0 : 28.0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        NookMark(size: size),
        const SizedBox(width: 10),
        Flexible(child: text),
      ],
    );
  }
}

/// Icon sách mở — `public/brand/icon.svg` của web.
class NookMark extends StatelessWidget {
  final double size;

  const NookMark({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      SiteBrandConstants.markAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

/// Tiêu đề trang editorial — mirror `PageHeader` web.
class EditorialPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  const EditorialPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 20),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.darkForeground : AppColors.homeTextDark;
    final muted = isDark ? AppColors.darkMuted : AppColors.homeTextLight;

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                    color: ink,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      height: 1.5,
                      color: muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: 12),
            action!,
          ],
        ],
      ),
    );
  }
}
