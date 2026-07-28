import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/i18n/locale_controller.dart';
import 'package:mobile/core/theme/app_palette.dart';
import 'package:mobile/core/theme/app_spacing.dart';
import 'package:mobile/core/theme/app_typography.dart';
import 'package:mobile/core/widgets/editorial_filter_tabs.dart';
import 'package:mobile/core/widgets/editorial_page_header.dart';
import 'package:mobile/core/widgets/editorial_states.dart';
import 'package:mobile/core/widgets/main_app_bar.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mobile/features/friends/screens/friends_screen.dart';
import 'package:mobile/features/home/presentation/bloc/feed_bloc.dart';
import 'package:mobile/features/home/widgets/currently_reading_strip.dart';
import 'package:mobile/features/home/widgets/feed_cards.dart';
import 'package:mobile/features/home/widgets/home_write_menu.dart';
import 'package:mobile/features/home/widgets/trending_section.dart';
import 'package:mobile/features/posts/screens/create_post_screen.dart';
import 'package:mobile/features/review/screens/create_book_review_screen.dart';

/// Home tab — structure mirrors web `/home` (PageHeader → strip → tabs → feed).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final _appBarKey = GlobalKey<MainAppBarState>();
  final _scrollController = ScrollController();
  late final FeedBloc _feedBloc;
  String _feedTab = 'all';

  @override
  void initState() {
    super.initState();
    _feedBloc = FeedBloc()..add(const FeedLoadRequested());
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _appBarKey.currentState?.refreshUnread();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _feedBloc.close();
    super.dispose();
  }

  void refresh() {
    _feedBloc.add(const FeedRefreshRequested());
    _appBarKey.currentState?.refreshUnread();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      _feedBloc.add(const FeedLoadMoreRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthBloc>().state.profile;
    final isGuest = profile?.isGuest ?? false;
    final isAdmin = profile?.isAdmin ?? false;
    final greeting = isGuest
        ? context.t('home.guestGreeting')
        : (profile?.username.isNotEmpty == true
              ? context.t('home.hello', {'name': profile!.username})
              : context.t('home.timeline'));
    final subtitle = isGuest
        ? context.t('home.guestSubtitle')
        : context.t('home.feedSubtitle');

    return BlocProvider.value(
      value: _feedBloc,
      child: SafeArea(
        child: RefreshIndicator(
          color: context.palette.accent,
          onRefresh: () async {
            _feedBloc.add(const FeedRefreshRequested());
            await _feedBloc.stream.firstWhere(
              (s) =>
                  s.status == FeedStatus.success ||
                  s.status == FeedStatus.failure,
            );
          },
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              MainAppBar(key: _appBarKey),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.pageY),
                  child: BlocBuilder<FeedBloc, FeedState>(
                    builder: (context, state) {
                      final showSkeleton =
                          state.isInitialLoading && state.items.isEmpty;
                      final reviewItems = state.reviewFeedItems;
                      final posts = state.items
                          .where(
                            (i) =>
                                i.type == FeedItemType.post && i.post != null,
                          )
                          .toList();
                      // Fall back to derived posts list from bloc if needed.
                      final postCards = posts.isNotEmpty
                          ? posts
                          : state.posts
                                .map(
                                  (p) => FeedItemDto(
                                    id: p.id,
                                    type: FeedItemType.post,
                                    post: p,
                                  ),
                                )
                                .toList();

                      final reviewsVisible =
                          !isGuest &&
                          (_feedTab == 'all' || _feedTab == 'reviews');
                      final postsVisible =
                          _feedTab == 'all' || _feedTab == 'posts';
                      final showFeatured =
                          reviewsVisible && state.featuredReview != null;
                      final showTrending =
                          !showFeatured &&
                          (_feedTab == 'all' || _feedTab == 'posts');

                      final hasFriendReviews = state.friendReviewIds.isNotEmpty;
                      final circleReviews = () {
                        final friends = reviewItems
                            .where(
                              (i) =>
                                  i.review != null &&
                                  state.friendReviewIds.contains(i.review!.id),
                            )
                            .toList();
                        final source = friends.isNotEmpty
                            ? friends
                            : reviewItems;
                        return source.take(8).toList();
                      }();

                      final tabs = isGuest
                          ? [
                              EditorialFilterTab(
                                id: 'all',
                                label: context.t('home.filterAll'),
                              ),
                              EditorialFilterTab(
                                id: 'posts',
                                label: context.t('home.filterPosts'),
                                count: postCards.length,
                              ),
                            ]
                          : [
                              EditorialFilterTab(
                                id: 'all',
                                label: context.t('home.filterAll'),
                              ),
                              EditorialFilterTab(
                                id: 'reviews',
                                label: context.t('home.filterReviews'),
                                count: reviewItems.length,
                              ),
                              EditorialFilterTab(
                                id: 'posts',
                                label: context.t('home.filterPosts'),
                                count: postCards.length,
                              ),
                            ];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          EditorialPageHeader(
                            title: greeting,
                            subtitle: subtitle,
                            action: isGuest ? null : const HomeWriteMenu(),
                          ),
                          if (!isGuest) const CurrentlyReadingStrip(),
                          EditorialFilterTabs(
                            tabs: tabs,
                            activeId: _feedTab,
                            onChanged: (id) => setState(() => _feedTab = id),
                          ),
                          if (showTrending) const TrendingSection(),
                          if (showSkeleton)
                            const EditorialFeedSkeleton(count: 3)
                          else if (state.status == FeedStatus.failure &&
                              state.items.isEmpty)
                            EditorialErrorState(
                              message:
                                  state.errorMessage ??
                                  context.t('errors.loadFailed'),
                              onRetry: () =>
                                  _feedBloc.add(const FeedRefreshRequested()),
                            )
                          else if (!showSkeleton &&
                              state.status != FeedStatus.failure &&
                              state.items.isEmpty)
                            EditorialEmptyState(
                              title: isGuest
                                  ? context.t('home.emptyGuestTitle')
                                  : context.t('home.emptyFeedTitle'),
                              message: isGuest
                                  ? context.t('home.emptyGuestMessage')
                                  : context.t('home.emptyFeedMessage'),
                              actionLabel: isGuest
                                  ? null
                                  : context.t('home.findReaders'),
                              onAction: isGuest
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute<void>(
                                          builder: (_) => const FriendsScreen(),
                                        ),
                                      );
                                    },
                              icon: EditorialEmptyIcon.feed,
                            )
                          else ...[
                            if (showFeatured && state.featuredReview != null)
                              FeaturedReviewCard(
                                review: state.featuredReview!,
                                author: state.featuredAuthor,
                              ),
                            if (reviewsVisible) ...[
                              EditorialSectionTitle(
                                title: hasFriendReviews
                                    ? context.t('home.friendReviews')
                                    : context.t('home.recentReviews'),
                                subtitle: hasFriendReviews
                                    ? context.t('home.friendReviewsSub')
                                    : context.t('home.yourReviewsSub'),
                              ),
                              if (circleReviews.isEmpty)
                                EditorialEmptyState(
                                  message: context.t('home.noReviews'),
                                  actionLabel: context.t('home.firstReview'),
                                  onAction: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const CreateBookReviewScreen(),
                                      ),
                                    );
                                  },
                                )
                              else
                                ...circleReviews.map(
                                  (item) => FeedReviewCard(item: item),
                                ),
                              const SizedBox(height: AppSpacing.homeSectionGap),
                            ],
                            if (postsVisible) ...[
                              EditorialSectionTitle(
                                title: isAdmin
                                    ? context.t('home.allPostsTitle')
                                    : context.t('home.postsTitle'),
                                subtitle: isGuest
                                    ? context.t('home.postsGuestSub')
                                    : isAdmin
                                    ? context.t('home.allPostsSub')
                                    : context.t('home.postsSub'),
                                action:
                                    !isGuest && !isAdmin && postCards.length > 6
                                    ? Text(
                                        context.t('home.viewAllPosts', {
                                          'count': postCards.length,
                                        }),
                                        style:
                                            AppTypography.accentLabel(
                                              context,
                                            ).copyWith(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                              letterSpacing: 0.4,
                                            ),
                                      )
                                    : null,
                              ),
                              if (postCards.isEmpty)
                                EditorialEmptyState(
                                  message: context.t('home.noPosts'),
                                  actionLabel: isGuest
                                      ? null
                                      : context.t('home.createPost'),
                                  onAction: isGuest
                                      ? null
                                      : () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute<void>(
                                              builder: (_) =>
                                                  const CreatePostScreen(),
                                            ),
                                          );
                                        },
                                )
                              else
                                ...postCards.map(
                                  (item) => FeedPostCard(
                                    item: item,
                                    onChanged: refresh,
                                  ),
                                ),
                              if (state.status == FeedStatus.loadingMore)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 32,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: context.palette.accent,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        context.t('home.loadingMore'),
                                        style: AppTypography.body(context),
                                      ),
                                    ],
                                  ),
                                )
                              else if (!state.hasMore && postCards.length > 6)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 32,
                                  ),
                                  child: Center(
                                    child: Text(
                                      context.t('home.endOfFeed').toUpperCase(),
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        letterSpacing: 0.8,
                                        color: context.palette.muted.withValues(
                                          alpha: 0.7,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ],
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
