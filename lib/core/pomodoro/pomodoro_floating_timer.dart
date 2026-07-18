import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/pomodoro/pomodoro_timer_controller.dart';
import 'package:mobile/core/router/app_router.dart';

/// Floating timer toàn app — ẩn khi đang ở `/calendar` (giống web).
class PomodoroFloatingTimer extends StatelessWidget {
  const PomodoroFloatingTimer({super.key});

  static String _format(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final timer = PomodoroTimerController.instance;
    return ListenableBuilder(
      listenable: timer,
      builder: (context, _) {
        if (!timer.isActive) return const SizedBox.shrink();

        final location = GoRouterState.of(context).uri.path;
        if (location == AppRoutes.calendar ||
            location.startsWith('${AppRoutes.calendar}/')) {
          return const SizedBox.shrink();
        }

        final bottomInset = MediaQuery.paddingOf(context).bottom;
        final progress = timer.progress;
        final accent = timer.isRunning
            ? AppColors.primaryBrown
            : const Color(0xFFD97706);

        return Positioned(
          left: 12,
          right: 12,
          bottom: bottomInset + 72,
          child: Material(
            color: Colors.transparent,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: AppColors.borderStrong),
                boxShadow: AppShadows.lift,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 3,
                            backgroundColor: AppColors.homeTextDark.withValues(
                              alpha: 0.06,
                            ),
                            color: accent,
                          ),
                          Text(
                            _format(timer.remainingSeconds),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => context.push(AppRoutes.calendar),
                        borderRadius: BorderRadius.circular(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              timer.isPaused ? 'Đã tạm dừng' : 'Đang tập trung',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: AppColors.homeTextLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              timer.entryMeta?.title ?? 'Pomodoro',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.homeTextDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (timer.isRunning)
                      IconButton(
                        tooltip: 'Tạm dừng',
                        onPressed: timer.pauseTimer,
                        icon: const Icon(Icons.pause_rounded),
                        color: AppColors.primaryBrown,
                      )
                    else if (timer.isPaused)
                      IconButton(
                        tooltip: 'Tiếp tục',
                        onPressed: timer.resumeTimer,
                        icon: const Icon(Icons.play_arrow_rounded),
                        color: AppColors.primaryBrown,
                      ),
                    IconButton(
                      tooltip: 'Đóng',
                      onPressed: timer.stopTimer,
                      icon: const Icon(Icons.close_rounded),
                      color: AppColors.homeTextLight,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
