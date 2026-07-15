import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_colors.dart';

/// Panel surface editorial — đồng bộ card của web:
/// bo góc radius-xl (22px), viền mảnh, shadow soft 2 lớp.
class EditorialSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool showAccentBar;
  final Color? accentColor;
  final EdgeInsetsGeometry? margin;
  final bool elevated;

  const EditorialSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.showAccentBar = false,
    this.accentColor,
    this.margin,
    this.elevated = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barColor =
        accentColor ??
        (isDark ? AppColors.darkAccent : AppColors.primaryBrown);
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    Widget inner = Padding(padding: padding, child: child);
    if (showAccentBar) {
      inner = Stack(
        children: [
          inner,
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.xl),
                  bottomLeft: Radius.circular(AppRadius.xl),
                ),
              ),
            ),
          ),
        ],
      );
    }

    Widget content = Container(
      width: double.infinity,
      margin: margin,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: AppRadius.card,
        border: Border.all(color: borderColor),
        boxShadow: elevated && !isDark ? AppShadows.soft : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: inner,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.card,
          child: content,
        ),
      );
    }

    return content;
  }
}
