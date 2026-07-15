import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/be_blog_http.dart';
import 'package:mobile/core/network/be_blog_response_parser.dart';
import 'package:mobile/data/models/engagement_dtos.dart';

class BeBlogEngagementRepository {
  Future<BeBlogRepoResult<List<BookmarkItemDto>>> getBookmarks({
    int page = 0,
    int size = 50,
  }) async {
    final response = await BeBlogHttp.get(
      ApiConstants.bookmarksMe,
      query: {'page': '$page', 'size': '$size'},
    );
    return BeBlogResponseParser.list(response, BookmarkItemDto.fromJson);
  }

  Future<BeBlogRepoResult<bool>> getBookmarkStatus(
    BookmarkEntityType type,
    String entityId,
  ) async {
    final response = await BeBlogHttp.get(
      ApiConstants.bookmarkStatus,
      query: {'entityType': type.apiValue, 'entityId': entityId},
    );
    return _boolResult(response.statusCode, response.body, 'bookmarked');
  }

  Future<BeBlogRepoResult<bool>> addBookmark(
    BookmarkEntityType type,
    String entityId,
  ) async {
    final response = await BeBlogHttp.postJson(
      ApiConstants.bookmarks,
      body: {'entityType': type.apiValue, 'entityId': entityId},
    );
    return _boolResult(response.statusCode, response.body, 'bookmarked');
  }

  Future<BeBlogRepoResult<bool>> removeBookmark(
    BookmarkEntityType type,
    String entityId,
  ) async {
    final response = await BeBlogHttp.delete(
      ApiConstants.bookmarks,
      query: {'entityType': type.apiValue, 'entityId': entityId},
    );
    return _boolResult(response.statusCode, response.body, 'bookmarked');
  }

  Future<BeBlogRepoResult<StreakSnapshotDto>> getStreak() async {
    final response = await BeBlogHttp.get(ApiConstants.streakMe);
    return BeBlogResponseParser.one(response, StreakSnapshotDto.fromJson);
  }

  /// `POST /api/public/newsletter/subscribe` — trả về message từ server.
  Future<BeBlogRepoResult<String>> subscribeNewsletter(String email) async {
    final response = await BeBlogHttp.postJson(
      '/api/public/newsletter/subscribe',
      auth: false,
      body: {'email': email.trim()},
    );
    if (!BeBlogResponseParser.isSuccess(response.statusCode)) {
      return BeBlogRepoResult.fail(
        response.statusCode,
        BeBlogHttp.extractServerMessage(response.body),
      );
    }
    try {
      final body = BeBlogHttp.decodeJsonObject(
        BeBlogHttp.decodeBody(response.body),
      );
      return BeBlogRepoResult.ok(
        body['message']?.toString() ?? 'Đăng ký nhận bản tin thành công.',
        response.statusCode,
      );
    } catch (_) {
      return BeBlogRepoResult.ok(
        'Đăng ký nhận bản tin thành công.',
        response.statusCode,
      );
    }
  }

  BeBlogRepoResult<bool> _boolResult(
    int statusCode,
    String responseBody,
    String key,
  ) {
    if (!BeBlogResponseParser.isSuccess(statusCode)) {
      return BeBlogRepoResult.fail(
        statusCode,
        BeBlogHttp.extractServerMessage(responseBody),
      );
    }
    try {
      final body = BeBlogHttp.decodeJsonObject(
        BeBlogHttp.decodeBody(responseBody),
      );
      return BeBlogRepoResult.ok(body[key] as bool? ?? false, statusCode);
    } catch (e) {
      return BeBlogRepoResult.fail(statusCode, 'Parse error: $e');
    }
  }
}
