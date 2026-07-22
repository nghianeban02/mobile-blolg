import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/i18n/locale_controller.dart';
import 'package:mobile/data/models/engagement_dtos.dart';
import 'package:mobile/data/repositories/engagement_repository.dart';

/// Header streak badge — parity `web-blog/components/streak/streak-badge.tsx`.
class StreakBadge extends StatefulWidget {
  const StreakBadge({super.key});

  @override
  State<StreakBadge> createState() => _StreakBadgeState();
}

class _StreakBadgeState extends State<StreakBadge> {
  final _repo = BeBlogEngagementRepository();
  StreakSnapshotDto? _streak;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await _repo.getStreak();
    if (!mounted || result.data == null) return;
    setState(() => _streak = result.data);
  }

  void _showPanel() {
    final streak = _streak;
    if (streak == null) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkSurface
          : AppColors.surface,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.t('streak.label'),
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.t('streak.days', {'count': streak.currentStreak}),
                style: GoogleFonts.inter(
                  color: AppColors.homeTextLight,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                streak.activeToday
                    ? context.t('streak.activeToday')
                    : context.t('streak.keepAlive'),
                style: GoogleFonts.inter(
                  color: AppColors.homeTextLight,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final day in streak.last7Days)
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: day.active
                            ? const Color(0xFFFFEDD5)
                            : AppColors.hoverWash,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: day.active
                              ? const Color(0xFFFDBA74)
                              : AppColors.borderStrong,
                        ),
                      ),
                      child: Text(
                        day.active ? '🔥' : '·',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final streak = _streak;
    if (streak == null) return const SizedBox.shrink();

    final active = streak.activeToday;
    return Material(
      color: active
          ? const Color(0xFFFFEDD5).withValues(alpha: 0.9)
          : AppColors.hoverWash,
      shape: StadiumBorder(
        side: BorderSide(
          color: active ? const Color(0xFFFDBA74) : AppColors.borderStrong,
        ),
      ),
      child: InkWell(
        onTap: _showPanel,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🔥',
                style: TextStyle(
                  fontSize: 14,
                  color: active ? null : Colors.grey,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${streak.currentStreak}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: active
                      ? const Color(0xFFEA580C)
                      : AppColors.homeTextLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
