import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';

/// Shadow nhẹ cho surface editorial (hiện đại, không bo tròn).
List<BoxShadow> editorialSoftShadow({double opacity = 0.06}) => [
  BoxShadow(
    color: Colors.black.withValues(alpha: opacity),
    blurRadius: 16,
    offset: const Offset(0, 4),
  ),
];

/// Nút icon vuông góc trên app bar — đồng bộ Home / Detail.
class EditorialHeaderChip extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color iconColor;
  final Widget? badge;

  const EditorialHeaderChip({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor = AppColors.coverSand,
    this.iconColor = AppColors.primaryBrown,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: backgroundColor,
            child: InkWell(
              onTap: onPressed,
              child: SizedBox(
                width: 36,
                height: 36,
                child: Icon(icon, size: 18, color: iconColor),
              ),
            ),
          ),
          if (badge != null) Positioned(right: -4, top: -4, child: badge!),
        ],
      ),
    );
  }
}

/// Link text kiểu editorial (comment, meta actions).
class EditorialLinkButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool emphasized;
  final bool destructive;

  const EditorialLinkButton({
    super.key,
    required this.label,
    this.onPressed,
    this.emphasized = false,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final color = destructive
        ? AppColors.error
        : disabled
        ? AppColors.homeTextLight
        : AppColors.primaryBrown;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: emphasized ? FontWeight.w600 : FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

/// Avatar chữ cái đầu — comment / danh sách.
class EditorialAvatarInitial extends StatelessWidget {
  final String name;
  final double size;
  final Color? backgroundColor;

  const EditorialAvatarInitial({
    super.key,
    required this.name,
    this.size = 28,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    final bg =
        backgroundColor ?? AppColors.primaryBrown.withValues(alpha: 0.12);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: bg,
      child: Text(
        initial,
        style: GoogleFonts.playfairDisplay(
          fontSize: size * 0.45,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryBrown,
        ),
      ),
    );
  }
}

/// Đường kẻ mảnh phân tách section.
class EditorialDivider extends StatelessWidget {
  const EditorialDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: AppColors.homeTextDark.withValues(alpha: 0.08),
    );
  }
}

/// Chip trạng thái vuông (published, circle…).
class EditorialStatusChip extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;

  const EditorialStatusChip({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      color: backgroundColor ?? AppColors.primaryBrown.withValues(alpha: 0.1),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: textColor ?? AppColors.primaryBrown,
        ),
      ),
    );
  }
}
