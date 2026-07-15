import 'package:mobile/core/cache/api_list_cache.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/be_blog_http.dart';
import 'package:mobile/core/network/be_blog_response_parser.dart';
import 'package:mobile/data/models/dtos.dart';

/// Mirrors [PostModerationController] — `/api/admin/posts` (ADMIN only).
class BeBlogPostModerationRepository {
  /// `GET /api/admin/posts/pending` — hàng chờ duyệt.
  Future<BeBlogRepoResult<List<PostDto>>> pending({
    int page = 0,
    int size = 50,
  }) async {
    final response = await BeBlogHttp.get(
      ApiConstants.adminPostsPending,
      query: {'page': '$page', 'size': '$size'},
    );
    return BeBlogResponseParser.list(response, PostDto.fromJson);
  }

  /// `POST /api/admin/posts/{id}/approve`.
  Future<BeBlogRepoResult<PostDto>> approve(String id) async {
    final response = await BeBlogHttp.postEmpty(
      ApiConstants.adminPostApprove(id),
    );
    final result = BeBlogResponseParser.one(response, PostDto.fromJson);
    if (result.success) _invalidate();
    return result;
  }

  /// `POST /api/admin/posts/{id}/reject` — [reason] tùy chọn.
  Future<BeBlogRepoResult<PostDto>> reject(String id, {String? reason}) async {
    final trimmed = reason?.trim();
    final hasReason = trimmed != null && trimmed.isNotEmpty;
    final response = hasReason
        ? await BeBlogHttp.postJson(
            ApiConstants.adminPostReject(id),
            body: {'reason': trimmed},
          )
        : await BeBlogHttp.postEmpty(ApiConstants.adminPostReject(id));
    final result = BeBlogResponseParser.one(response, PostDto.fromJson);
    if (result.success) _invalidate();
    return result;
  }

  void _invalidate() {
    ApiListCache.invalidatePosts();
    ApiListCache.invalidateFeed();
  }
}
