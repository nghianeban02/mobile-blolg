import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/be_blog_http.dart';
import 'package:mobile/core/network/be_blog_response_parser.dart';
import 'package:mobile/data/models/dtos.dart';

/// Mirrors [CommentController] — threaded comments + replies.
class BeBlogCommentsRepository {
  Future<BeBlogRepoResult<List<CommentDto>>> listByReview(
    String reviewId,
  ) async {
    final response = await BeBlogHttp.get(
      '${ApiConstants.reviews}/$reviewId/comments',
      query: const {'page': '0', 'size': '100'},
    );
    return BeBlogResponseParser.list(response, CommentDto.fromJson);
  }

  /// Top-level comment or reply via {@code parentId} in body.
  Future<BeBlogRepoResult<CommentDto>> create({
    required String reviewId,
    required String content,
    String? parentId,
  }) async {
    final body = <String, dynamic>{'content': content};
    if (parentId != null && parentId.isNotEmpty) {
      body['parentId'] = parentId;
    }
    final response = await BeBlogHttp.postJson(
      '${ApiConstants.reviews}/$reviewId/comments',
      auth: true,
      body: body,
    );
    return BeBlogResponseParser.one(response, CommentDto.fromJson);
  }

  /// `POST /api/reviews/{reviewId}/comments/{commentId}/replies`
  Future<BeBlogRepoResult<CommentDto>> reply({
    required String reviewId,
    required String commentId,
    required String content,
  }) async {
    final response = await BeBlogHttp.postJson(
      '${ApiConstants.reviews}/$reviewId/comments/$commentId/replies',
      auth: true,
      body: {'content': content},
    );
    return BeBlogResponseParser.one(response, CommentDto.fromJson);
  }

  Future<BeBlogRepoResult<CommentDto>> update({
    required String reviewId,
    required String commentId,
    required String content,
  }) async {
    final response = await BeBlogHttp.putJson(
      '${ApiConstants.reviews}/$reviewId/comments/$commentId',
      auth: true,
      body: {'content': content},
    );
    return BeBlogResponseParser.one(response, CommentDto.fromJson);
  }

  Future<BeBlogRepoResult<void>> delete({
    required String reviewId,
    required String commentId,
  }) async {
    final response = await BeBlogHttp.delete(
      '${ApiConstants.reviews}/$reviewId/comments/$commentId',
      auth: true,
    );
    return BeBlogResponseParser.delete(response);
  }
}

/// Total comments including nested replies.
int countCommentsThreaded(List<CommentDto> roots) {
  var n = 0;
  for (final c in roots) {
    n += c.threadSize;
  }
  return n;
}
