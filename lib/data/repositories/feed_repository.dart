import 'package:mobile/core/cache/api_list_cache.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/be_blog_http.dart';
import 'package:mobile/core/network/be_blog_response_parser.dart';
import 'package:mobile/data/models/dtos.dart';

/// Home timeline: `GET /api/feed` (Spring `Page` → items in `content`).
class BeBlogFeedRepository {
  Future<BeBlogRepoResult<List<FeedItemDto>>> getHomeFeed({
    int page = 0,
    int size = 100,
    bool forceRefresh = false,
  }) async {
    return ApiListCache.getOrFetch(
      key: ApiListCache.feedKey,
      forceRefresh: forceRefresh,
      fetch: () async {
        final response = await BeBlogHttp.get(
          ApiConstants.feed,
          query: {'page': '$page', 'size': '$size'},
        );
        return BeBlogResponseParser.list(response, FeedItemDto.fromJson);
      },
    );
  }

  /// `GET /api/feed/users/{userId}` — timeline of a specific user.
  Future<BeBlogRepoResult<List<FeedItemDto>>> getUserFeed(
    String userId, {
    int page = 0,
    int size = 100,
  }) async {
    final response = await BeBlogHttp.get(
      ApiConstants.feedForUser(userId),
      query: {'page': '$page', 'size': '$size'},
    );
    return BeBlogResponseParser.list(response, FeedItemDto.fromJson);
  }
}

/// Extract posts/reviews from feed items for existing home widgets.
List<PostDto> postsFromFeedItems(List<FeedItemDto> items) {
  return items
      .where((i) => i.type == FeedItemType.post && i.post != null)
      .map((i) => i.post!)
      .toList();
}

List<ReviewDto> reviewsFromFeedItems(List<FeedItemDto> items) {
  return items
      .where((i) => i.type == FeedItemType.review && i.review != null)
      .map((i) => i.review!)
      .toList();
}

List<FeedItemDto> reviewFeedItems(List<FeedItemDto> items) {
  return items.where((i) => i.type == FeedItemType.review).toList();
}

/// Map review id → author from feed rows (O(n), built once per load).
Map<String, UserPublicDto> reviewAuthorsFromFeed(List<FeedItemDto> items) {
  final map = <String, UserPublicDto>{};
  for (final item in items) {
    final review = item.review;
    final author = item.author;
    if (item.type == FeedItemType.review && review != null && author != null) {
      map[review.id] = author;
    }
  }
  return map;
}

/// Friend reviews on feed (exclude current user); falls back to all reviews.
({List<FeedItemDto> display, Set<String> friendReviewIds})
partitionCircleReviews(List<FeedItemDto> reviewItems, {String? currentUserId}) {
  final friendReviews = reviewItems.where((item) {
    final review = item.review;
    if (review == null) return false;
    final authorId = item.authorId ?? review.userId;
    if (currentUserId == null || currentUserId.isEmpty) return true;
    return authorId != currentUserId;
  }).toList();

  final display = friendReviews.isNotEmpty ? friendReviews : reviewItems;
  final friendIds = friendReviews.map((i) => i.review!.id).toSet();

  return (display: display, friendReviewIds: friendIds);
}
