part of 'feed_bloc.dart';

enum FeedStatus { initial, loading, refreshing, loadingMore, success, failure }

final class FeedState extends Equatable {
  final FeedStatus status;
  final List<FeedItemDto> items;
  final List<PostDto> posts;
  final List<FeedItemDto> reviewFeedItems;
  final ReviewDto? featuredReview;
  final UserPublicDto? featuredAuthor;
  final Set<String> friendReviewIds;
  final int page;
  final bool hasMore;
  final String? errorMessage;

  const FeedState({
    this.status = FeedStatus.initial,
    this.items = const [],
    this.posts = const [],
    this.reviewFeedItems = const [],
    this.featuredReview,
    this.featuredAuthor,
    this.friendReviewIds = const {},
    this.page = 0,
    this.hasMore = true,
    this.errorMessage,
  });

  bool get isInitialLoading =>
      status == FeedStatus.loading || status == FeedStatus.initial;

  FeedState copyWith({
    FeedStatus? status,
    List<FeedItemDto>? items,
    List<PostDto>? posts,
    List<FeedItemDto>? reviewFeedItems,
    ReviewDto? featuredReview,
    UserPublicDto? featuredAuthor,
    Set<String>? friendReviewIds,
    int? page,
    bool? hasMore,
    String? errorMessage,
    bool clearError = false,
    bool clearFeatured = false,
  }) {
    return FeedState(
      status: status ?? this.status,
      items: items ?? this.items,
      posts: posts ?? this.posts,
      reviewFeedItems: reviewFeedItems ?? this.reviewFeedItems,
      featuredReview: clearFeatured
          ? null
          : (featuredReview ?? this.featuredReview),
      featuredAuthor: clearFeatured
          ? null
          : (featuredAuthor ?? this.featuredAuthor),
      friendReviewIds: friendReviewIds ?? this.friendReviewIds,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    items,
    posts,
    reviewFeedItems,
    featuredReview?.id,
    featuredAuthor?.id,
    friendReviewIds,
    page,
    hasMore,
    errorMessage,
  ];
}
