import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/theme/app_palette.dart';
import 'package:mobile/core/theme/app_typography.dart';

/// Button variants — mirror `uiButtonVariants` in web `design-system.ts`.
enum EditorialButtonVariant {
  primary,
  success,
  outline,
  ghost,
  soft,
  danger,
  dangerSolid,
}

enum EditorialButtonSize { sm, md }

/// Pill button — single source for CTA styling across the app.
class EditorialButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final EditorialButtonVariant variant;
  final EditorialButtonSize size;
  final bool loading;
  final bool expanded;
  final Widget? leading;
  final Widget? trailing;
  final IconData? icon;

  const EditorialButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = EditorialButtonVariant.primary,
    this.size = EditorialButtonSize.md,
    this.loading = false,
    this.expanded = false,
    this.leading,
    this.trailing,
    this.icon,
  });

  bool get _enabled => onPressed != null && !loading;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final colors = _colors(p);
    final minH = size == EditorialButtonSize.sm ? 36.0 : 44.0;
    final hPad = size == EditorialButtonSize.sm ? 16.0 : 20.0;
    final vPad = size == EditorialButtonSize.sm ? 6.0 : 10.0;
    final fontSize = size == EditorialButtonSize.sm ? 12.0 : 14.0;

    Widget child = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.fg.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (leading != null) ...[
          leading!,
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          Icon(icon, size: 16, color: colors.fg),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.button(
              context,
              size: fontSize,
              color: colors.fg,
            ),
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 6), trailing!],
      ],
    );

    child = AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: _enabled ? 1 : 0.45,
      child: Material(
        color: colors.bg,
        shape: StadiumBorder(
          side: colors.border != null
              ? BorderSide(color: colors.border!)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        child: InkWell(
          onTap: _enabled ? onPressed : null,
          child: Container(
            constraints: BoxConstraints(minHeight: minH),
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );

    if (variant == EditorialButtonVariant.primary && _enabled) {
      child = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.pill,
          boxShadow: AppShadows.primaryButton,
        ),
        child: child,
      );
    }

    if (expanded) {
      child = SizedBox(width: double.infinity, child: child);
    }
    return child;
  }

  _BtnColors _colors(AppPalette p) {
    switch (variant) {
      case EditorialButtonVariant.primary:
        return _BtnColors(bg: p.accent, fg: Colors.white);
      case EditorialButtonVariant.success:
        return const _BtnColors(bg: Color(0xFF059669), fg: Colors.white);
      case EditorialButtonVariant.outline:
        return _BtnColors(
          bg: p.surface.withValues(alpha: 0.8),
          fg: p.accent,
          border: p.border,
        );
      case EditorialButtonVariant.ghost:
        return _BtnColors(bg: Colors.transparent, fg: p.accent);
      case EditorialButtonVariant.soft:
        return _BtnColors(bg: p.accentSoft, fg: p.accent);
      case EditorialButtonVariant.danger:
        return _BtnColors(
          bg: p.danger.withValues(alpha: 0.08),
          fg: p.danger,
          border: p.danger.withValues(alpha: 0.15),
        );
      case EditorialButtonVariant.dangerSolid:
        return const _BtnColors(bg: Color(0xFFDC2626), fg: Colors.white);
    }
  }
}

class _BtnColors {
  final Color bg;
  final Color fg;
  final Color? border;
  const _BtnColors({required this.bg, required this.fg, this.border});
}
