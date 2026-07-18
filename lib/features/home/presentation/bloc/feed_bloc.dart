import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/cache/session_cache.dart';
import 'package:mobile/core/images/post_image_prefetch.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/data/repositories/feed_repository.dart';

part 'feed_event.dart';
part 'feed_state.dart';

/// Home timeline: page/size pagination, pull-to-refresh, skeleton/error.
class FeedBloc extends Bloc<FeedEvent, FeedState> {
  FeedBloc({BeBlogFeedRepository? repository})
    : _repository = repository ?? BeBlogFeedRepository(),
      super(const FeedState()) {
    on<FeedLoadRequested>(_onLoadRequested);
    on<FeedRefreshRequested>(_onRefreshRequested);
    on<FeedLoadMoreRequested>(_onLoadMoreRequested);
  }

  final BeBlogFeedRepository _repository;
  static const int _pageSize = 30;

  Future<void> _onLoadRequested(
    FeedLoadRequested event,
    Emitter<FeedState> emit,
  ) async {
    if (state.status == FeedStatus.loading) return;
    emit(
      state.copyWith(
        status: FeedStatus.loading,
        clearError: true,
        page: 0,
        hasMore: true,
      ),
    );
    await _fetchPage(emit, page: 0, append: false);
  }

  Future<void> _onRefreshRequested(
    FeedRefreshRequested event,
    Emitter<FeedState> emit,
  ) async {
    emit(
      state.copyWith(
        status: state.items.isEmpty
            ? FeedStatus.loading
            : FeedStatus.refreshing,
        clearError: true,
        page: 0,
        hasMore: true,
      ),
    );
    await _fetchPage(emit, page: 0, append: false, forceRefresh: true);
  }

  Future<void> _onLoadMoreRequested(
    FeedLoadMoreRequested event,
    Emitter<FeedState> emit,
  ) async {
    if (!state.hasMore ||
        state.status == FeedStatus.loadingMore ||
        state.status == FeedStatus.loading) {
      return;
    }
    emit(state.copyWith(status: FeedStatus.loadingMore));
    await _fetchPage(emit, page: state.page + 1, append: true);
  }

  Future<void> _fetchPage(
    Emitter<FeedState> emit, {
    required int page,
    required bool append,
    bool forceRefresh = false,
  }) async {
    try {
      final result = await _repository.getHomeFeed(
        page: page,
        size: _pageSize,
        forceRefresh: forceRefresh || page == 0,
      );
      if (!result.success) {
        emit(
          state.copyWith(
            status: FeedStatus.failure,
            errorMessage:
                result.message ?? 'Không tải được feed. Đăng nhập rồi thử lại.',
          ),
        );
        return;
      }

      final pageItems = result.data ?? const <FeedItemDto>[];
      final items = append
          ? [...state.items, ...pageItems]
          : List<FeedItemDto>.from(pageItems);
      final derived = _derive(items);
      emit(
        state.copyWith(
          status: FeedStatus.success,
          items: items,
          posts: derived.posts,
          reviewFeedItems: derived.reviewFeedItems,
          featuredReview: derived.featuredReview,
          featuredAuthor: derived.featuredAuthor,
          friendReviewIds: derived.friendReviewIds,
          page: page,
          hasMore: pageItems.length >= _pageSize,
          clearError: true,
          clearFeatured: derived.featuredReview == null,
        ),
      );
      PostImagePrefetch.prefetchPostCovers(derived.posts);
    } on NetworkException catch (e) {
      emit(state.copyWith(status: FeedStatus.failure, errorMessage: e.message));
    } on Exception catch (e) {
      emit(
        state.copyWith(status: FeedStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  static ({
    List<PostDto> posts,
    List<FeedItemDto> reviewFeedItems,
    ReviewDto? featuredReview,
    UserPublicDto? featuredAuthor,
    Set<String> friendReviewIds,
  })
  _derive(List<FeedItemDto> items) {
    final posts = postsFromFeedItems(items);
    final reviewItems = reviewFeedItems(items);
    final authors = reviewAuthorsFromFeed(items);
    final partition = partitionCircleReviews(
      reviewItems,
      currentUserId: SessionCache.profile?.id,
    );
    final featured = reviewItems.isNotEmpty ? reviewItems.first.review : null;
    return (
      posts: posts,
      reviewFeedItems: reviewItems,
      featuredReview: featured,
      featuredAuthor: featured != null ? authors[featured.id] : null,
      friendReviewIds: partition.friendReviewIds,
    );
  }
}
