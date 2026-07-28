import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/theme/app_palette.dart';
import 'package:mobile/core/theme/app_spacing.dart';

class EditorialFilterTab {
  final String id;
  final String label;
  final int? count;

  const EditorialFilterTab({required this.id, required this.label, this.count});
}

/// Segmented filter tabs — mirror web `FilterTabs` / `uiSegmentTrack`.
class EditorialFilterTabs extends StatelessWidget {
  final List<EditorialFilterTab> tabs;
  final String activeId;
  final ValueChanged<String> onChanged;
  final EdgeInsetsGeometry? padding;

  const EditorialFilterTabs({
    super.key,
    required this.tabs,
    required this.activeId,
    required this.onChanged,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding:
          padding ??
          const EdgeInsets.fromLTRB(
            AppSpacing.pageX,
            0,
            AppSpacing.pageX,
            AppSpacing.pageHeaderBottom,
          ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: p.segmentTrack,
            borderRadius: AppRadius.pill,
          ),
          child: Row(
            children: [
              for (final tab in tabs) ...[
                _Segment(
                  label: tab.count != null
                      ? '${tab.label} ${tab.count}'
                      : tab.label,
                  active: tab.id == activeId,
                  onTap: () => onChanged(tab.id),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Material(
        color: active ? p.surface : Colors.transparent,
        shape: const StadiumBorder(),
        elevation: 0,
        shadowColor: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.pill,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: AppRadius.pill,
              boxShadow: active && !p.isDark ? AppShadows.soft : null,
              border: active
                  ? Border.all(color: p.border.withValues(alpha: 0.4))
                  : null,
            ),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: active ? p.foreground : p.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
