import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/brand/site_brand.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/services/chat_realtime_service.dart';
import 'package:mobile/core/widgets/editorial_ui.dart';
import 'package:mobile/features/friends/screens/friends_screen.dart';
import 'package:mobile/features/messages/screens/conversations_screen.dart';
import 'package:mobile/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:mobile/features/notifications/screens/notifications_screen.dart';

/// App bar mobile — wordmark Nook (trái) + bạn bè / tin nhắn / chuông (phải),
/// nền glass + viền dưới giống `app-shell` header trên web.
class MainAppBar extends StatefulWidget {
  const MainAppBar({super.key});

  @override
  MainAppBarState createState() => MainAppBarState();
}

class MainAppBarState extends State<MainAppBar> with WidgetsBindingObserver {
  final _chatRealtime = ChatRealtimeService.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    refreshUnread();
    _chatRealtime.addListener(_onChatState);
    unawaited(_chatRealtime.start());
  }

  void _onChatState() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatRealtime.removeListener(_onChatState);
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
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
    );
    refreshUnread();
  }

  Future<void> _openFriends() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const FriendsScreen()),
    );
    refreshUnread();
  }

  Future<void> _openMessages() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const ConversationsScreen()),
    );
    unawaited(_chatRealtime.refreshUnread());
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
    final chatUnread = _chatRealtime.unreadCount;
    final chatBadgeLabel = chatUnread > 99 ? '99+' : '$chatUnread';

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
                padding: const EdgeInsets.fromLTRB(16, 6, 10, 6),
                child: Row(
                  children: [
                    const Expanded(
                      child: SiteBrand(
                        variant: SiteBrandVariant.mobile,
                        showSlogan: true,
                        showMark: true,
                        markSize: 28,
                      ),
                    ),
                    EditorialHeaderChip(
                      icon: Icons.people_outline_rounded,
                      onPressed: _openFriends,
                    ),
                    const SizedBox(width: 6),
                    EditorialHeaderChip(
                      icon: Icons.chat_bubble_outline_rounded,
                      onPressed: _openMessages,
                      badge: chatUnread > 0
                          ? _countBadge(chatBadgeLabel)
                          : null,
                    ),
                    const SizedBox(width: 6),
                    BlocBuilder<NotificationsBloc, NotificationsState>(
                      buildWhen: (a, b) => a.unreadCount != b.unreadCount,
                      builder: (context, state) {
                        final badgeLabel = state.unreadCount > 99
                            ? '99+'
                            : '${state.unreadCount}';
                        return EditorialHeaderChip(
                          icon: Icons.notifications_outlined,
                          backgroundColor: AppColors.headerIconBg,
                          iconColor: Colors.white,
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
