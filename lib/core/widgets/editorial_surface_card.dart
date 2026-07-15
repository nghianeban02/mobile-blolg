import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/widgets/editorial_ui.dart';

/// White editorial panel used across social / profile screens.
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
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.showAccentBar = false,
    this.accentColor,
    this.margin,
    this.elevated = true,
  });

  @override
  Widget build(BuildContext context) {
    final barColor = accentColor ?? AppColors.primaryBrown;

    Widget content = Container(
      width: double.infinity,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: elevated ? editorialSoftShadow() : null,
        border: Border(
          left: showAccentBar
              ? BorderSide(color: barColor, width: 3)
              : BorderSide.none,
          top: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
          right: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
          bottom: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, child: content),
      );
    }

    return content;
  }
}
