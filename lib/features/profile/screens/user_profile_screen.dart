import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/network/be_blog_http.dart';
import 'package:mobile/core/widgets/async_loading_view.dart';
import 'package:mobile/core/widgets/detail_app_bar.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/data/repositories/users_repository.dart';
import 'package:mobile/features/posts/screens/post_detail_screen.dart';
import 'package:mobile/features/profile/widgets/profile_post_card.dart';
import 'package:mobile/features/profile/widgets/profile_private_feed_banner.dart';
import 'package:mobile/features/profile/widgets/profile_review_card.dart';
import 'package:mobile/features/profile/widgets/user_profile_header.dart';
import 'package:mobile/features/review/screens/book_detail_screen.dart';

/// Trang công khai user khác: profile + bài đăng + review sách.
class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String? initialDisplayName;

  const UserProfileScreen({
    super.key,
    required this.userId,
    this.initialDisplayName,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  final _usersRepo = BeBlogUsersRepository();
  late final TabController _tabs;

  bool _loading = true;
  String? _error;
  UserProfileViewDto? _profile;
  List<PostDto> _posts = const [];
  List<ReviewDto> _reviews = const [];
  bool _isOwnProfile = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final profileResult = await _usersRepo.getProfile(widget.userId);
    if (!mounted) return;

    if (!profileResult.success || profileResult.data == null) {
      setState(() {
        _loading = false;
        _error = profileResult.message ?? 'Không tải được hồ sơ.';
      });
      return;
    }

    final profile = profileResult.data!;
    if (!profile.canViewFeed) {
      setState(() {
        _loading = false;
        _profile = profile;
        _posts = const [];
        _reviews = const [];
      });
      return;
    }

    final isOwnProfile = profile.relationStatus == 'SELF';

    final results = await Future.wait([
      _usersRepo.getUserPosts(widget.userId, forceRefresh: forceRefresh),
      _usersRepo.getProfileReviews(
        widget.userId,
        isOwnProfile: isOwnProfile,
        forceRefresh: forceRefresh,
      ),
    ]);
    if (!mounted) return;

    setState(() {
      _loading = false;
      _profile = profile;
      _isOwnProfile = isOwnProfile;
      _posts = (results[0] as BeBlogRepoResult<List<PostDto>>).data ?? const [];
      _reviews =
          (results[1] as BeBlogRepoResult<List<ReviewDto>>).data ?? const [];
    });
  }

  bool get _showTabs =>
      !_loading && _error == null && (_profile?.canViewFeed ?? false);

  @override
  Widget build(BuildContext context) {
    final profile = _profile;

    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primaryBrown,
          onRefresh: () => _load(forceRefresh: true),
          child: NestedScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            headerSliverBuilder: (context, _) => [
              const DetailSliverAppBar(),
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
                    onRetry: () => _load(forceRefresh: true),
                  ),
                )
              else if (profile != null) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: UserProfileHeader(
                      profile: profile,
                      postCount: _posts.length,
                      reviewCount: _reviews.length,
                      onFriendshipChanged: () => _load(forceRefresh: true),
                    ),
                  ),
                ),
                if (!profile.canViewFeed)
                  const SliverToBoxAdapter(child: ProfilePrivateFeedBanner())
                else
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _ProfileTabBarDelegate(
                      tabBar: TabBar(
                        controller: _tabs,
                        labelColor: AppColors.primaryBrown,
                        unselectedLabelColor: AppColors.homeTextLight,
                        indicatorColor: AppColors.primaryBrown,
                        labelStyle: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                        tabs: [
                          Tab(text: 'BÀI ĐĂNG (${_posts.length})'),
                          Tab(text: 'REVIEW (${_reviews.length})'),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
            body: _showTabs
                ? TabBarView(
                    controller: _tabs,
                    children: [
                      _PostsTab(
                        posts: _posts,
                        onOpen: (p) => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                PostDetailScreen(postId: p.id, initialPost: p),
                          ),
                        ),
                      ),
                      _ReviewsTab(
                        reviews: _reviews,
                        isOwnProfile: _isOwnProfile,
                        onOpen: (r) {
                          final profile = _profile;
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => BookDetailScreen(
                                reviewId: r.id,
                                initialReview: r,
                                authorId: widget.userId,
                                authorDisplayName: profile?.displayName,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

class _ProfileTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _ProfileTabBarDelegate({required this.tabBar});

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(color: AppColors.homeBackground, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant _ProfileTabBarDelegate oldDelegate) =>
      tabBar != oldDelegate.tabBar;
}

class _PostsTab extends StatelessWidget {
  final List<PostDto> posts;
  final void Function(PostDto) onOpen;

  const _PostsTab({required this.posts, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 48),
          Center(
            child: Text(
              'Chưa có bài đăng nào.',
              style: GoogleFonts.inter(
                color: AppColors.homeTextLight,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      itemCount: posts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (_, i) => ProfilePostCard(
        key: ValueKey(posts[i].id),
        post: posts[i],
        onTap: () => onOpen(posts[i]),
      ),
    );
  }
}

class _ReviewsTab extends StatelessWidget {
  final List<ReviewDto> reviews;
  final bool isOwnProfile;
  final void Function(ReviewDto) onOpen;

  const _ReviewsTab({
    required this.reviews,
    required this.isOwnProfile,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 48),
          Text(
            isOwnProfile
                ? 'Chưa có review sách nào.'
                : 'Chưa có review published trên trang công khai.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppColors.homeTextLight,
              fontSize: 13,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
          if (!isOwnProfile) ...[
            const SizedBox(height: 12),
            Text(
              'Review ở trạng thái draft chỉ hiển thị với chủ tài khoản. '
              'Cần chuyển sang Published để bạn bè thấy.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.homeTextLight,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ],
        ],
      );
    }
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      itemCount: reviews.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (_, i) => ProfileReviewCard(
        key: ValueKey(reviews[i].id),
        review: reviews[i],
        onTap: () => onOpen(reviews[i]),
      ),
    );
  }
}
