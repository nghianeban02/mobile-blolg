import 'package:mobile/core/cache/api_list_cache.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/be_blog_http.dart';
import 'package:mobile/core/network/be_blog_response_parser.dart';
import 'package:mobile/data/models/dtos.dart';

/// Mirrors [ReviewController].
class BeBlogReviewsRepository {
  Future<BeBlogRepoResult<List<ReviewDto>>> getAll({
    String? bookId,
    String? userId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = userId != null && userId.isNotEmpty
        ? '${ApiListCache.reviewsKey}?userId=$userId'
        : ApiListCache.reviewsKeyForBook(bookId);
    return ApiListCache.getOrFetch(
      key: cacheKey,
      forceRefresh: forceRefresh,
      fetch: () async {
        final query = <String, String>{
          'page': '0',
          'size': '100',
          if (bookId != null && bookId.isNotEmpty) 'bookId': bookId,
          if (userId != null && userId.isNotEmpty) 'userId': userId,
        };
        final response = await BeBlogHttp.get(
          ApiConstants.reviews,
          query: query,
        );
        return BeBlogResponseParser.list(response, ReviewDto.fromJson);
      },
    );
  }

  Future<BeBlogRepoResult<ReviewDto>> getOne(String id) async {
    final cached = ApiListCache.peek<ReviewDto>(ApiListCache.reviewsKey);
    if (cached != null) {
      for (final review in cached) {
        if (review.id == id) return BeBlogRepoResult.ok(review);
      }
    }
    final response = await BeBlogHttp.get('${ApiConstants.reviews}/$id');
    return BeBlogResponseParser.one(response, ReviewDto.fromJson);
  }

  Future<BeBlogRepoResult<ReviewDto>> create(ReviewWriteRequest req) async {
    final response = await BeBlogHttp.postJson(
      ApiConstants.reviews,
      auth: true,
      body: req.toJson(),
    );
    final result = BeBlogResponseParser.one(response, ReviewDto.fromJson);
    if (result.success) {
      ApiListCache.invalidateReviews(bookId: req.bookId);
      ApiListCache.invalidateFeed();
    }
    return result;
  }

  Future<BeBlogRepoResult<ReviewDto>> update(
    String id,
    ReviewWriteRequest req,
  ) async {
    final response = await BeBlogHttp.putJson(
      '${ApiConstants.reviews}/$id',
      auth: true,
      body: req.toJson(),
    );
    final result = BeBlogResponseParser.one(response, ReviewDto.fromJson);
    if (result.success) {
      ApiListCache.invalidateReviews();
      ApiListCache.invalidateFeed();
    }
    return result;
  }

  Future<BeBlogRepoResult<void>> delete(String id) async {
    final response = await BeBlogHttp.delete(
      '${ApiConstants.reviews}/$id',
      auth: true,
    );
    final result = BeBlogResponseParser.delete(response);
    if (result.success) {
      ApiListCache.invalidateReviews();
      ApiListCache.invalidateFeed();
    }
    return result;
  }

  Future<BeBlogRepoResult<List<ReviewTagDto>>> getTags(String reviewId) async {
    final response = await BeBlogHttp.get(
      '${ApiConstants.reviews}/$reviewId/tags',
    );
    return BeBlogResponseParser.list(response, ReviewTagDto.fromJson);
  }

  Future<BeBlogRepoResult<ReviewTagDto>> addTag({
    required String reviewId,
    required String tagId,
  }) async {
    final response = await BeBlogHttp.postJson(
      '${ApiConstants.reviews}/$reviewId/tags',
      auth: true,
      body: {'tagId': tagId},
    );
    return BeBlogResponseParser.one(response, ReviewTagDto.fromJson);
  }

  Future<BeBlogRepoResult<void>> removeTag({
    required String reviewId,
    required String tagId,
  }) async {
    final response = await BeBlogHttp.delete(
      '${ApiConstants.reviews}/$reviewId/tags/$tagId',
      auth: true,
    );
    return BeBlogResponseParser.delete(response);
  }
}
