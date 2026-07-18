import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/navigation/open_user_profile.dart';
import 'package:mobile/core/widgets/async_loading_view.dart';
import 'package:mobile/core/widgets/detail_app_bar.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/features/friends/screens/friends_screen.dart';
import 'package:mobile/features/notifications/presentation/bloc/notifications_bloc.dart';
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
  @override
  void initState() {
    super.initState();
    context.read<NotificationsBloc>().add(const NotificationsListRequested());
  }

  Future<void> _onTap(NotificationDto n) async {
    final bloc = context.read<NotificationsBloc>();
    if (!n.read) {
      bloc.add(NotificationsMarkReadRequested(n.id));
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
          MaterialPageRoute<void>(
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
          MaterialPageRoute<void>(
            builder: (_) => PostDetailScreen(postId: postId),
          ),
        );
      case NotificationType.friendRequest:
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => const FriendsScreen(initialTab: 1),
          ),
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
            MaterialPageRoute<void>(builder: (_) => const FriendsScreen()),
          );
        }
      case NotificationType.unknown:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<NotificationsBloc, NotificationsState>(
          builder: (context, state) {
            final unreadCount = state.items.where((n) => !n.read).length;
            return RefreshIndicator(
              color: AppColors.primaryBrown,
              onRefresh: () async {
                context.read<NotificationsBloc>().add(
                  const NotificationsListRequested(),
                );
                await context.read<NotificationsBloc>().stream.firstWhere(
                  (s) =>
                      s.status == NotificationsStatus.success ||
                      s.status == NotificationsStatus.failure,
                );
              },
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
                          if (unreadCount > 0) ...[
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => context
                                    .read<NotificationsBloc>()
                                    .add(
                                      const NotificationsMarkAllReadRequested(),
                                    ),
                                child: Text(
                                  'Đánh dấu tất cả đã đọc',
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
                  if (state.status == NotificationsStatus.loading &&
                      state.items.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryBrown,
                        ),
                      ),
                    )
                  else if (state.status == NotificationsStatus.failure)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: AsyncLoadingView(
                        isLoading: false,
                        errorMessage: state.errorMessage,
                        onRetry: () => context.read<NotificationsBloc>().add(
                          const NotificationsListRequested(),
                        ),
                      ),
                    )
                  else if (state.items.isEmpty)
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
                          final n = state.items[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: NotificationTile(
                              notification: n,
                              onTap: () => _onTap(n),
                            ),
                          );
                        }, childCount: state.items.length),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
