import 'package:flutter/material.dart';
import 'package:mobile/core/cache/session_cache.dart';
import 'package:mobile/core/images/post_image_prefetch.dart';
import 'package:mobile/core/widgets/async_loading_view.dart';
import 'package:mobile/core/widgets/main_app_bar.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/data/repositories/feed_repository.dart';
import 'package:mobile/features/home/widgets/editorial_circle_entry.dart';
import 'package:mobile/features/home/widgets/feed_reviews_section.dart';
import 'package:mobile/features/home/widgets/newsletter_section.dart';
import 'package:mobile/features/home/widgets/recent_archives.dart';
import 'package:mobile/features/home/widgets/review_of_the_day.dart';

/// Home tab: personal timeline from `GET /api/feed` (posts + reviews).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final _feedRepo = BeBlogFeedRepository();
  final _appBarKey = GlobalKey<MainAppBarState>();

  bool _isLoading = true;
  String? _error;
  List<FeedItemDto> _feedItems = const [];
  List<PostDto> _posts = const [];
  List<FeedItemDto> _reviewFeedItems = const [];
  ReviewDto? _featuredReview;
  UserPublicDto? _featuredAuthor;
  Set<String> _friendReviewIds = const {};

  @override
  void initState() {
    super.initState();
    _loadHomeData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _appBarKey.currentState?.refreshUnread();
    });
  }

  /// Reload feed (e.g. after admin creates a post or review).
  void refresh() {
    _loadHomeData(forceRefresh: true);
    _appBarKey.currentState?.refreshUnread();
  }

  void _applyFeedItems(List<FeedItemDto> items) {
    final posts = postsFromFeedItems(items);
    final reviewItems = reviewFeedItems(items);
    final authors = reviewAuthorsFromFeed(items);
    final partition = partitionCircleReviews(
      reviewItems,
      currentUserId: SessionCache.profile?.id,
    );
    final featured = reviewItems.isNotEmpty ? reviewItems.first.review : null;

    _feedItems = items;
    _posts = posts;
    _reviewFeedItems = reviewItems;
    _friendReviewIds = partition.friendReviewIds;
    _featuredReview = featured;
    _featuredAuthor = _featuredReview != null
        ? authors[_featuredReview!.id]
        : null;
  }

  Future<void> _loadHomeData({bool forceRefresh = false}) async {
    final showLoadingOverlay = _feedItems.isEmpty;
    if (showLoadingOverlay) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    final feedResult = await _feedRepo.getHomeFeed(forceRefresh: forceRefresh);
    if (!mounted) return;

    if (!feedResult.success) {
      setState(() {
        _isLoading = false;
        _error =
            feedResult.message ?? 'Không tải được feed. Đăng nhập rồi thử lại.';
      });
      return;
    }

    final items = feedResult.data ?? const [];
    setState(() {
      _applyFeedItems(items);
      _isLoading = false;
      _error = null;
    });

    PostImagePrefetch.prefetchPostCovers(_posts);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          MainAppBar(key: _appBarKey),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 24),
                AsyncLoadingView(
                  isLoading: _isLoading,
                  errorMessage: _error,
                  onRetry: () => _loadHomeData(forceRefresh: true),
                ),
                if (!_isLoading) ...[
                  const RepaintBoundary(child: EditorialCircleEntry()),
                  const SizedBox(height: 32),
                  RepaintBoundary(
                    child: ReviewOfTheDay(
                      review: _featuredReview,
                      author: _featuredAuthor,
                    ),
                  ),
                  const SizedBox(height: 40),
                  RepaintBoundary(
                    child: FeedReviewsSection(
                      reviewItems: _reviewFeedItems,
                      friendReviewIds: _friendReviewIds,
                    ),
                  ),
                  const SizedBox(height: 48),
                  RepaintBoundary(
                    child: RecentArchives(
                      posts: _posts,
                      onPostChanged: refresh,
                    ),
                  ),
                  const SizedBox(height: 48),
                  const RepaintBoundary(child: NewsletterSection()),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
