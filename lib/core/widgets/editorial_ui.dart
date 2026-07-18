import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';

/// Shadow mềm 2 lớp cho surface editorial — web: --app-shadow-soft.
List<BoxShadow> editorialSoftShadow({double opacity = 0.04}) => [
  BoxShadow(
    color: Colors.black.withValues(alpha: opacity),
    blurRadius: 8,
    offset: const Offset(0, 2),
  ),
  BoxShadow(
    color: Colors.black.withValues(alpha: opacity + 0.01),
    blurRadius: 24,
    offset: const Offset(0, 8),
  ),
];

/// Nút icon tròn trên app bar — đồng bộ header pill của web.
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
      width: 38,
      height: 38,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: backgroundColor,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 38,
                height: 38,
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
        borderRadius: AppRadius.pill,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: emphasized ? FontWeight.w600 : FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

/// Avatar chữ cái đầu — tròn, fallback nền sand giống web.
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
    final bg = backgroundColor ?? AppColors.coverSand.withValues(alpha: 0.6);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
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
      color: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkBorder
          : AppColors.border,
    );
  }
}

/// Chip trạng thái pill (published, circle…) — web StatusChip rounded-full.
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primaryBrown.withValues(alpha: 0.1),
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: textColor ?? AppColors.primaryBrown,
        ),
      ),
    );
  }
}

/// Nút pill primary — web EditorialButton variant "primary":
/// nền nâu, chữ trắng, bo tròn hoàn toàn, shadow nâu nhẹ.
class EditorialPillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outline;
  final bool destructive;
  final bool expanded;

  const EditorialPillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.outline = false,
    this.destructive = false,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = destructive
        ? AppColors.error
        : outline
        ? Colors.transparent
        : AppColors.primaryBrown;
    final fg = outline ? AppColors.homeTextDark : Colors.white;

    Widget button = Material(
      color: bg,
      shape: outline
          ? const StadiumBorder(side: BorderSide(color: AppColors.borderStrong))
          : const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!outline && !destructive && onPressed != null) {
      button = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.pill,
          boxShadow: AppShadows.primaryButton,
        ),
        child: button,
      );
    }
    return button;
  }
}
