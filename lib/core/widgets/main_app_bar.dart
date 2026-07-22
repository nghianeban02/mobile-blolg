import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/i18n/locale_controller.dart';
import 'package:mobile/core/router/app_router.dart';
import 'package:mobile/core/widgets/editorial_ui.dart';
import 'package:mobile/core/widgets/streak_badge.dart';
import 'package:mobile/features/notifications/presentation/bloc/notifications_bloc.dart';

/// App bar mobile — parity web AppShell header:
/// menu + search | streak + notifications.
class MainAppBar extends StatefulWidget {
  const MainAppBar({super.key});

  @override
  MainAppBarState createState() => MainAppBarState();
}

class MainAppBarState extends State<MainAppBar> with WidgetsBindingObserver {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    refreshUnread();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refreshUnread();
  }

  void refreshUnread() {
    if (!mounted) return;
    context.read<NotificationsBloc>().add(
      const NotificationsUnreadRefreshRequested(),
    );
  }

  Future<void> _openNotifications() async {
    await context.push(AppRoutes.notifications);
    refreshUnread();
  }

  void _submitSearch(String raw) {
    final q = raw.trim();
    if (q.isEmpty) {
      context.go(AppRoutes.search);
      return;
    }
    context.go('${AppRoutes.search}?q=${Uri.encodeQueryComponent(q)}');
  }

  Widget _countBadge(String label) => Container(
    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
    padding: const EdgeInsets.symmetric(horizontal: 4),
    decoration: BoxDecoration(
      color: AppColors.error,
      borderRadius: AppRadius.pill,
      border: Border.all(
        color: Theme.of(context).scaffoldBackgroundColor,
        width: 1.5,
      ),
    ),
    alignment: Alignment.center,
    child: Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 9,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        height: 1,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barColor = (isDark ? AppColors.darkBackground : AppColors.surface)
        .withValues(alpha: 0.88);
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final muted = isDark ? AppColors.darkMuted : AppColors.homeTextLight;

    return SliverAppBar(
      backgroundColor: Colors.transparent,
      expandedHeight: 64,
      toolbarHeight: 64,
      floating: true,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: barColor,
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 10, 6),
                child: Row(
                  children: [
                    EditorialHeaderChip(
                      icon: Icons.menu_rounded,
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : AppColors.homeTextDark.withValues(alpha: 0.05),
                          borderRadius: AppRadius.pill,
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search_rounded, size: 18, color: muted),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                textInputAction: TextInputAction.search,
                                onSubmitted: _submitSearch,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  color: isDark
                                      ? AppColors.darkForeground
                                      : AppColors.homeTextDark,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  hintText: context.t(
                                    'search.headerPlaceholder',
                                  ),
                                  hintStyle: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: muted.withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const StreakBadge(),
                    const SizedBox(width: 6),
                    BlocBuilder<NotificationsBloc, NotificationsState>(
                      buildWhen: (a, b) => a.unreadCount != b.unreadCount,
                      builder: (context, state) {
                        final badgeLabel = state.unreadCount > 99
                            ? '99+'
                            : '${state.unreadCount}';
                        return EditorialHeaderChip(
                          icon: Icons.notifications_outlined,
                          onPressed: _openNotifications,
                          badge: state.unreadCount > 0
                              ? _countBadge(badgeLabel)
                              : null,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
