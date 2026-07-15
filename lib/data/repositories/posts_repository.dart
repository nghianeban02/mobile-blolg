import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:mobile/core/cache/api_list_cache.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/be_blog_http.dart';
import 'package:mobile/core/network/be_blog_response_parser.dart';
import 'package:mobile/data/models/dtos.dart';

/// Mirrors [PostController]: multipart create with title image + gallery images.
class BeBlogPostsRepository {
  Future<BeBlogRepoResult<List<PostDto>>> getAll({
    bool forceRefresh = false,
    String scope = 'mine',
  }) async {
    final cacheKey = scope == 'network'
        ? '${ApiListCache.postsKey}:network'
        : ApiListCache.postsKey;
    return ApiListCache.getOrFetch(
      key: cacheKey,
      forceRefresh: forceRefresh,
      fetch: () async {
        final response = await BeBlogHttp.get(
          ApiConstants.posts,
          query: {'page': '0', 'size': '100', 'scope': scope},
        );
        return BeBlogResponseParser.list(response, PostDto.fromJson);
      },
    );
  }

  /// Posts from me + friends (`scope=network`).
  Future<BeBlogRepoResult<List<PostDto>>> getNetwork({
    bool forceRefresh = false,
  }) => getAll(forceRefresh: forceRefresh, scope: 'network');

  /// Current user's posts: `GET /api/users/me/posts`.
  Future<BeBlogRepoResult<List<PostDto>>> getMine({
    bool forceRefresh = false,
  }) async {
    return ApiListCache.getOrFetch(
      key: ApiListCache.myPostsKey,
      forceRefresh: forceRefresh,
      fetch: () async {
        final response = await BeBlogHttp.get(
          ApiConstants.usersMePosts,
          query: const {'page': '0', 'size': '100'},
        );
        return BeBlogResponseParser.list(response, PostDto.fromJson);
      },
    );
  }

  Future<BeBlogRepoResult<PostDto>> getOne(String id) async {
    final cached = ApiListCache.peek<PostDto>(ApiListCache.postsKey);
    if (cached != null) {
      for (final post in cached) {
        if (post.id == id) return BeBlogRepoResult.ok(post);
      }
    }
    final response = await BeBlogHttp.get('${ApiConstants.posts}/$id');
    return BeBlogResponseParser.one(response, PostDto.fromJson);
  }

  /// Requires JWT (owner). Multipart: `title`, `content`, optional `titleImage`, `images[]`.
  Future<BeBlogRepoResult<PostDto>> createMultipart({
    required String title,
    required String content,
    File? titleImageFile,
    List<File> galleryImageFiles = const [],
  }) async {
    final uri = BeBlogHttp.uri(ApiConstants.posts);
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(await BeBlogHttp.multipartHeaders(auth: true));
    request.fields['title'] = title;
    request.fields['content'] = content;

    if (titleImageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('titleImage', titleImageFile.path),
      );
    }

    for (final file in galleryImageFiles) {
      request.files.add(await http.MultipartFile.fromPath('images', file.path));
    }

    try {
      final streamed = await request.send().timeout(
        ApiConstants.connectTimeout,
      );
      final response = await http.Response.fromStream(streamed);
      final result = BeBlogResponseParser.one(response, PostDto.fromJson);
      if (result.success) {
        ApiListCache.invalidatePosts();
        ApiListCache.invalidateFeed();
        ApiListCache.invalidate(ApiListCache.myPostsKey);
      }
      return result;
    } catch (e) {
      return BeBlogRepoResult.fail(0, e.toString());
    }
  }

  /// `PUT /api/posts/{id}` (multipart) — owner or ADMIN.
  ///
  /// Chỉ gửi field nào có thay đổi. [replaceGallery] = true sẽ thay toàn bộ
  /// gallery bằng [galleryImageFiles]; ngược lại giữ ảnh cũ.
  Future<BeBlogRepoResult<PostDto>> updateMultipart({
    required String id,
    String? title,
    String? content,
    File? titleImageFile,
    List<File> galleryImageFiles = const [],
    bool replaceGallery = false,
  }) async {
    final uri = BeBlogHttp.uri('${ApiConstants.posts}/$id');
    final request = http.MultipartRequest('PUT', uri);
    request.headers.addAll(await BeBlogHttp.multipartHeaders(auth: true));

    if (title != null) request.fields['title'] = title;
    if (content != null) request.fields['content'] = content;
    request.fields['replaceGallery'] = replaceGallery.toString();

    if (titleImageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('titleImage', titleImageFile.path),
      );
    }
    for (final file in galleryImageFiles) {
      request.files.add(await http.MultipartFile.fromPath('images', file.path));
    }

    try {
      final streamed = await request.send().timeout(
        ApiConstants.connectTimeout,
      );
      final response = await http.Response.fromStream(streamed);
      final result = BeBlogResponseParser.one(response, PostDto.fromJson);
      if (result.success) _invalidatePostCaches();
      return result;
    } catch (e) {
      return BeBlogRepoResult.fail(0, e.toString());
    }
  }

  /// `POST /api/posts/{id}/gallery` — thêm ảnh vào gallery (không đụng title/content).
  Future<BeBlogRepoResult<PostDto>> appendGalleryImages({
    required String id,
    required List<File> imageFiles,
  }) async {
    if (imageFiles.isEmpty) {
      return BeBlogRepoResult.fail(0, 'Không có ảnh nào để thêm.');
    }
    final uri = BeBlogHttp.uri('${ApiConstants.posts}/$id/gallery');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(await BeBlogHttp.multipartHeaders(auth: true));
    for (final file in imageFiles) {
      request.files.add(await http.MultipartFile.fromPath('images', file.path));
    }
    try {
      final streamed = await request.send().timeout(
        ApiConstants.connectTimeout,
      );
      final response = await http.Response.fromStream(streamed);
      final result = BeBlogResponseParser.one(response, PostDto.fromJson);
      if (result.success) _invalidatePostCaches();
      return result;
    } catch (e) {
      return BeBlogRepoResult.fail(0, e.toString());
    }
  }

  /// `DELETE /api/posts/{id}/gallery/{imageId}` — xóa 1 ảnh gallery → 204.
  Future<BeBlogRepoResult<void>> deleteGalleryImage({
    required String id,
    required String imageId,
  }) async {
    final response = await BeBlogHttp.delete(
      '${ApiConstants.posts}/$id/gallery/$imageId',
      auth: true,
    );
    final result = BeBlogResponseParser.delete(response);
    if (result.success) _invalidatePostCaches();
    return result;
  }

  void _invalidatePostCaches() {
    ApiListCache.invalidatePosts();
    ApiListCache.invalidateFeed();
    ApiListCache.invalidate(ApiListCache.myPostsKey);
  }

  /// `DELETE /api/posts/{id}` — owner (or admin) → 204.
  Future<BeBlogRepoResult<void>> delete(String id) async {
    final response = await BeBlogHttp.delete(
      '${ApiConstants.posts}/$id',
      auth: true,
    );
    final result = BeBlogResponseParser.delete(response);
    if (result.success) {
      ApiListCache.invalidatePosts();
      ApiListCache.invalidateFeed();
    }
    return result;
  }
}
