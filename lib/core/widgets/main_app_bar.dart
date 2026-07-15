import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/services/chat_realtime_service.dart';
import 'package:mobile/core/widgets/editorial_ui.dart';
import 'package:mobile/data/repositories/notifications_repository.dart';
import 'package:mobile/features/friends/screens/friends_screen.dart';
import 'package:mobile/features/messages/screens/conversations_screen.dart';
import 'package:mobile/features/notifications/screens/notifications_screen.dart';

/// App bar Home: logo, bạn bè, tin nhắn, chuông thông báo (badge chưa đọc).
class MainAppBar extends StatefulWidget {
  const MainAppBar({super.key});

  @override
  MainAppBarState createState() => MainAppBarState();
}

class MainAppBarState extends State<MainAppBar> with WidgetsBindingObserver {
  final _notificationsRepo = BeBlogNotificationsRepository();
  final _chatRealtime = ChatRealtimeService.instance;
  Timer? _refreshTimer;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    refreshUnread();
    // Web dùng SSE; mobile thay bằng polling nhẹ để badge luôn tươi.
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => refreshUnread(),
    );
    // Badge tin nhắn realtime qua WebSocket của messaging-service.
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
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refreshUnread();
  }

  /// Gọi sau khi quay lại Home hoặc sau thao tác tạo nội dung.
  Future<void> refreshUnread() async {
    final result = await _notificationsRepo.unreadCount();
    if (!mounted) return;
    if (result.success) {
      setState(() => _unreadCount = result.data ?? 0);
    }
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
    await refreshUnread();
  }

  Future<void> _openFriends() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FriendsScreen()),
    );
    await refreshUnread();
  }

  Future<void> _openMessages() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ConversationsScreen()),
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
    final badgeLabel = _unreadCount > 99 ? '99+' : '$_unreadCount';
    final chatUnread = _chatRealtime.unreadCount;
    final chatBadgeLabel = chatUnread > 99 ? '99+' : '$chatUnread';

    return SliverAppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      expandedHeight: 60,
      floating: true,
      pinned: true,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      title: Image.asset(
        'assets/images/app_logo.png',
        height: 40,
        fit: BoxFit.contain,
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Center(
            child: EditorialHeaderChip(
              icon: Icons.people_outline,
              onPressed: _openFriends,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Center(
            child: EditorialHeaderChip(
              icon: Icons.chat_bubble_outline,
              onPressed: _openMessages,
              badge: chatUnread > 0 ? _countBadge(chatBadgeLabel) : null,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: EditorialHeaderChip(
              icon: Icons.notifications_outlined,
              backgroundColor: AppColors.headerIconBg,
              iconColor: Colors.white,
              onPressed: _openNotifications,
              badge: _unreadCount > 0 ? _countBadge(badgeLabel) : null,
            ),
          ),
        ),
      ],
    );
  }
}
