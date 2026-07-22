import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/brand/site_brand.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/i18n/locale_controller.dart';
import 'package:mobile/core/router/app_router.dart';
import 'package:mobile/core/services/chat_realtime_service.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mobile/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:mobile/features/posts/screens/create_post_screen.dart';
import 'package:mobile/features/reading_list/screens/create_book_screen.dart';
import 'package:mobile/features/review/screens/create_book_review_screen.dart';

/// Sidebar drawer — parity `web-blog` AppShell sidebar (mobile hamburger).
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatUnread = ChatRealtimeService.instance.unreadCount;

    return Drawer(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: SiteBrand(
                      variant: SiteBrandVariant.sidebar,
                      showSlogan: true,
                      showMark: true,
                      markSize: 28,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    color: isDark
                        ? AppColors.darkMuted
                        : AppColors.homeTextLight,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 10,
                ),
                children: [
                  _NavTile(
                    icon: Icons.home_outlined,
                    label: context.t('nav.home'),
                    onTap: () => _go(context, AppRoutes.home),
                  ),
                  _NavTile(
                    icon: Icons.search_rounded,
                    label: context.t('nav.search'),
                    onTap: () => _go(context, AppRoutes.search),
                  ),
                  _NavTile(
                    icon: Icons.auto_stories_outlined,
                    label: context.t('nav.library'),
                    onTap: () => _go(context, AppRoutes.library),
                  ),
                  _NavTile(
                    icon: Icons.bookmark_outline_rounded,
                    label: context.t('nav.saved'),
                    onTap: () => _push(context, AppRoutes.saved),
                  ),
                  _NavTile(
                    icon: Icons.sticky_note_2_outlined,
                    label: context.t('nav.notes'),
                    onTap: () => _push(context, AppRoutes.notes),
                  ),
                  _NavTile(
                    icon: Icons.calendar_month_outlined,
                    label: context.t('nav.calendar'),
                    onTap: () => _push(context, AppRoutes.calendar),
                  ),
                  _NavTile(
                    icon: Icons.people_outline_rounded,
                    label: context.t('nav.friends'),
                    onTap: () => _push(context, AppRoutes.friends),
                  ),
                  _NavTile(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: context.t('nav.messages'),
                    badge: chatUnread,
                    onTap: () => _push(context, AppRoutes.messages),
                  ),
                  BlocBuilder<NotificationsBloc, NotificationsState>(
                    buildWhen: (a, b) => a.unreadCount != b.unreadCount,
                    builder: (context, state) => _NavTile(
                      icon: Icons.notifications_outlined,
                      label: context.t('nav.notifications'),
                      badge: state.unreadCount,
                      onTap: () => _push(context, AppRoutes.notifications),
                    ),
                  ),
                  _NavTile(
                    icon: Icons.settings_outlined,
                    label: context.t('nav.settings'),
                    onTap: () => _push(context, AppRoutes.settings),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                context.t('nav.createNew'),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkMuted : AppColors.homeTextLight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
              child: Column(
                children: [
                  _CreateTile(
                    label: context.t('nav.newPost'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const CreatePostScreen(),
                        ),
                      );
                    },
                  ),
                  _CreateTile(
                    label: context.t('nav.newReview'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const CreateBookReviewScreen(),
                        ),
                      );
                    },
                  ),
                  _CreateTile(
                    label: context.t('nav.addBook'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const CreateBookScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final profile = state.profile;
                final name = profile?.title?.trim().isNotEmpty == true
                    ? profile!.title!.trim()
                    : (profile?.username ?? 'Nook');
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.coverSand,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: GoogleFonts.playfairDisplay(
                        color: AppColors.primaryBrown,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  title: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkForeground
                          : AppColors.homeTextDark,
                    ),
                  ),
                  subtitle: Text(
                    context.t('settings.viewProfile'),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkMuted
                          : AppColors.homeTextLight,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    if (profile == null) return;
                    context.push(AppRoutes.user(profile.id));
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _go(BuildContext context, String route) {
    Navigator.pop(context);
    context.go(route);
  }

  void _push(BuildContext context, String route) {
    Navigator.pop(context);
    context.push(route);
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int badge;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Icon(
        icon,
        size: 22,
        color: isDark ? AppColors.darkMuted : AppColors.homeTextLight,
      ),
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.darkForeground : AppColors.homeTextDark,
        ),
      ),
      trailing: badge > 0
          ? Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: AppRadius.pill,
              ),
              alignment: Alignment.center,
              child: Text(
                badge > 99 ? '99+' : '$badge',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            )
          : null,
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _CreateTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _CreateTile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: AppColors.primaryBrown.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.add, size: 12, color: AppColors.primaryBrown),
      ),
      title: Text(
        label,
        style: GoogleFonts.inter(fontSize: 14, color: AppColors.homeTextDark),
      ),
      onTap: onTap,
    );
  }
}
