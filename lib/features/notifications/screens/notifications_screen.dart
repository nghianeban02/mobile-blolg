import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/navigation/open_user_profile.dart';
import 'package:mobile/core/widgets/async_loading_view.dart';
import 'package:mobile/core/widgets/detail_app_bar.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/data/repositories/notifications_repository.dart';
import 'package:mobile/features/friends/screens/friends_screen.dart';
import 'package:mobile/features/notifications/widgets/notification_tile.dart';
import 'package:mobile/features/posts/screens/post_detail_screen.dart';
import 'package:mobile/features/posts/widgets/post_section_label.dart';
import 'package:mobile/features/review/screens/book_detail_screen.dart';

/// Danh sách thông báo — `GET /api/notifications`.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _repo = BeBlogNotificationsRepository();

  bool _loading = true;
  bool _markingAll = false;
  String? _error;
  List<NotificationDto> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repo.list();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.success) {
        _items = result.data ?? const [];
        _error = null;
      } else {
        final code = result.statusCode;
        final hint = code == 401
            ? 'Phiên đăng nhập hết hạn hoặc backend chưa có API thông báo — hãy đăng nhập lại và khởi động lại be-blog.'
            : code == 404
            ? 'API thông báo chưa có trên server. Khởi động lại be-blog bản mới nhất.'
            : result.message;
        _error = hint ?? 'Không tải được thông báo (HTTP $code).';
      }
    });
  }

  Future<void> _markAllRead() async {
    setState(() => _markingAll = true);
    final result = await _repo.markAllRead();
    if (!mounted) return;
    setState(() => _markingAll = false);
    if (result.success) {
      await _load();
    }
  }

  Future<void> _onTap(NotificationDto n) async {
    if (!n.read) {
      await _repo.markRead(n.id);
      if (mounted) {
        setState(() {
          _items = _items
              .map(
                (item) => item.id == n.id
                    ? NotificationDto(
                        id: item.id,
                        type: item.type,
                        actor: item.actor,
                        reviewId: item.reviewId,
                        postId: item.postId,
                        commentId: item.commentId,
                        friendshipId: item.friendshipId,
                        message: item.message,
                        read: true,
                        createdAt: item.createdAt,
                      )
                    : item,
              )
              .toList();
        });
      }
    }
    if (!mounted) return;
    await _openTarget(n);
  }

  Future<void> _openTarget(NotificationDto n) async {
    switch (n.type) {
      case NotificationType.reviewLike:
      case NotificationType.reviewComment:
      case NotificationType.reviewCommentReply:
        final reviewId = n.reviewId;
        if (reviewId == null || reviewId.isEmpty) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookDetailScreen(
              reviewId: reviewId,
              authorId: n.actor?.id,
              authorDisplayName: n.actor?.displayName,
            ),
          ),
        );
      case NotificationType.postLike:
      case NotificationType.postComment:
      case NotificationType.postCommentReply:
        final postId = n.postId;
        if (postId == null || postId.isEmpty) return;
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PostDetailScreen(postId: postId)),
        );
      case NotificationType.friendRequest:
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FriendsScreen(initialTab: 1)),
        );
      case NotificationType.friendRequestAccepted:
        final actor = n.actor;
        if (actor != null) {
          await openUserProfile(
            context,
            userId: actor.id,
            displayName: actor.displayName,
          );
        } else {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FriendsScreen()),
          );
        }
      case NotificationType.unknown:
        break;
    }
  }

  int get _unreadCount => _items.where((n) => !n.read).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primaryBrown,
          onRefresh: _load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              const DetailSliverAppBar(title: 'THÔNG BÁO'),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const PostSectionLabel(text: 'HOẠT ĐỘNG'),
                      const SizedBox(height: 8),
                      Text(
                        'Like, bình luận và lời mời kết bạn từ vòng đọc của bạn.',
                        style: GoogleFonts.inter(
                          color: AppColors.homeTextLight,
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                      if (_unreadCount > 0) ...[
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _markingAll ? null : _markAllRead,
                            child: Text(
                              _markingAll
                                  ? 'Đang cập nhật…'
                                  : 'Đánh dấu tất cả đã đọc',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryBrown,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBrown,
                    ),
                  ),
                )
              else if (_error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: AsyncLoadingView(
                    isLoading: false,
                    errorMessage: _error,
                    onRetry: _load,
                  ),
                )
              else if (_items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Chưa có thông báo nào.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: AppColors.homeTextLight,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final n = _items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: NotificationTile(
                          notification: n,
                          onTap: () => _onTap(n),
                        ),
                      );
                    }, childCount: _items.length),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
