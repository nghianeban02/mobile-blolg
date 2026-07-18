import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/be_blog_http.dart';
import 'package:mobile/core/network/be_blog_response_parser.dart';
import 'package:mobile/data/models/dtos.dart';

/// Mirrors [LikeController] / [PostLikeController]: mọi endpoint likes
/// đều trả về `LikeStatus` (count, likedByMe, myReaction, reactions).
class BeBlogLikesRepository {
  Future<BeBlogRepoResult<LikeStatusDto>> status(String reviewId) =>
      _statusRequest(
        () => BeBlogHttp.get(
          '${ApiConstants.reviews}/$reviewId/likes/count',
          auth: true,
        ),
      );

  /// Thả cảm xúc [type] (HEART/WOW/CLAP/THINKING/SAD). Đổi loại = gọi lại.
  Future<BeBlogRepoResult<LikeStatusDto>> like(
    String reviewId, {
    String type = 'HEART',
  }) => _statusRequest(
    () => BeBlogHttp.postJson(
      '${ApiConstants.reviews}/$reviewId/likes',
      auth: true,
      body: {'type': type},
    ),
  );

  Future<BeBlogRepoResult<LikeStatusDto>> unlike(String reviewId) =>
      _statusRequest(
        () => BeBlogHttp.delete(
          '${ApiConstants.reviews}/$reviewId/likes',
          auth: true,
        ),
      );

  Future<BeBlogRepoResult<LikeStatusDto>> statusPost(String postId) =>
      _statusRequest(
        () => BeBlogHttp.get(
          '${ApiConstants.posts}/$postId/likes/count',
          auth: true,
        ),
      );

  Future<BeBlogRepoResult<LikeStatusDto>> likePost(
    String postId, {
    String type = 'HEART',
  }) => _statusRequest(
    () => BeBlogHttp.postJson(
      '${ApiConstants.posts}/$postId/likes',
      auth: true,
      body: {'type': type},
    ),
  );

  Future<BeBlogRepoResult<LikeStatusDto>> unlikePost(String postId) =>
      _statusRequest(
        () => BeBlogHttp.delete(
          '${ApiConstants.posts}/$postId/likes',
          auth: true,
        ),
      );

  /// Chỉ lấy tổng lượt thích (dùng cho màn API demo).
  Future<BeBlogRepoResult<int>> count(String reviewId) async {
    final result = await status(reviewId);
    if (!result.success) {
      return BeBlogRepoResult.fail(result.statusCode, result.message);
    }
    return BeBlogRepoResult.ok(result.data?.count ?? 0, result.statusCode);
  }

  Future<BeBlogRepoResult<LikeStatusDto>> _statusRequest(
    Future<ApiResponse> Function() request,
  ) async {
    final response = await request();
    if (!BeBlogResponseParser.isSuccess(response.statusCode)) {
      return BeBlogRepoResult.fail(
        response.statusCode,
        BeBlogHttp.extractServerMessage(response.body),
      );
    }
    try {
      final map = BeBlogHttp.decodeJsonObject(
        BeBlogHttp.decodeBody(response.body),
      );
      return BeBlogRepoResult.ok(
        LikeStatusDto.fromJson(map),
        response.statusCode,
      );
    } catch (e) {
      return BeBlogRepoResult.fail(response.statusCode, 'Parse error: $e');
    }
  }
}
