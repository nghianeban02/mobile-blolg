import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/be_blog_http.dart';
import 'package:mobile/core/network/be_blog_response_parser.dart';
import 'package:mobile/data/models/dtos.dart';

/// `POST /api/posts/{postId}/comments` — threaded comments + replies.
class BeBlogPostCommentsRepository {
  Future<BeBlogRepoResult<List<CommentDto>>> listByPost(String postId) async {
    final response = await BeBlogHttp.get(
      '${ApiConstants.posts}/$postId/comments',
      query: const {'page': '0', 'size': '100'},
    );
    return BeBlogResponseParser.list(response, CommentDto.fromJson);
  }

  Future<BeBlogRepoResult<CommentDto>> create({
    required String postId,
    required String content,
    String? parentId,
  }) async {
    final body = <String, dynamic>{'content': content};
    if (parentId != null && parentId.isNotEmpty) {
      body['parentId'] = parentId;
    }
    final response = await BeBlogHttp.postJson(
      '${ApiConstants.posts}/$postId/comments',
      auth: true,
      body: body,
    );
    return BeBlogResponseParser.one(response, CommentDto.fromJson);
  }

  Future<BeBlogRepoResult<CommentDto>> reply({
    required String postId,
    required String commentId,
    required String content,
  }) async {
    final response = await BeBlogHttp.postJson(
      '${ApiConstants.posts}/$postId/comments/$commentId/replies',
      auth: true,
      body: {'content': content},
    );
    return BeBlogResponseParser.one(response, CommentDto.fromJson);
  }

  Future<BeBlogRepoResult<CommentDto>> update({
    required String postId,
    required String commentId,
    required String content,
  }) async {
    final response = await BeBlogHttp.putJson(
      '${ApiConstants.posts}/$postId/comments/$commentId',
      auth: true,
      body: {'content': content},
    );
    return BeBlogResponseParser.one(response, CommentDto.fromJson);
  }

  Future<BeBlogRepoResult<void>> delete({
    required String postId,
    required String commentId,
  }) async {
    final response = await BeBlogHttp.delete(
      '${ApiConstants.posts}/$postId/comments/$commentId',
      auth: true,
    );
    return BeBlogResponseParser.delete(response);
  }
}
