import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/widgets/async_loading_view.dart';
import 'package:mobile/core/widgets/main_app_bar.dart';
import 'package:mobile/features/home/presentation/bloc/feed_bloc.dart';
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
  final _appBarKey = GlobalKey<MainAppBarState>();
  final _scrollController = ScrollController();
  late final FeedBloc _feedBloc;

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

  /// Reload feed (e.g. after admin creates a post or review).
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
    return BlocProvider.value(
      value: _feedBloc,
      child: SafeArea(
        child: RefreshIndicator(
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
                child: BlocBuilder<FeedBloc, FeedState>(
                  builder: (context, state) {
                    final showSkeleton =
                        state.isInitialLoading && state.items.isEmpty;
                    return Column(
                      children: [
                        const SizedBox(height: 24),
                        AsyncLoadingView(
                          isLoading: showSkeleton,
                          errorMessage: state.status == FeedStatus.failure
                              ? state.errorMessage
                              : null,
                          onRetry: () =>
                              _feedBloc.add(const FeedRefreshRequested()),
                        ),
                        if (!showSkeleton &&
                            state.status != FeedStatus.failure) ...[
                          const RepaintBoundary(child: EditorialCircleEntry()),
                          const SizedBox(height: 32),
                          RepaintBoundary(
                            child: ReviewOfTheDay(
                              review: state.featuredReview,
                              author: state.featuredAuthor,
                            ),
                          ),
                          const SizedBox(height: 40),
                          RepaintBoundary(
                            child: FeedReviewsSection(
                              reviewItems: state.reviewFeedItems,
                              friendReviewIds: state.friendReviewIds,
                            ),
                          ),
                          const SizedBox(height: 48),
                          RepaintBoundary(
                            child: RecentArchives(
                              posts: state.posts,
                              onPostChanged: refresh,
                            ),
                          ),
                          const SizedBox(height: 48),
                          const RepaintBoundary(child: NewsletterSection()),
                          if (state.status == FeedStatus.loadingMore)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          const SizedBox(height: 24),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
