import 'package:mobile/core/network/be_blog_http.dart';

/// Shared JSON response parsing for be-blog repositories.
class BeBlogResponseParser {
  BeBlogResponseParser._();

  static bool isSuccess(int statusCode) =>
      statusCode >= 200 && statusCode < 300;

  static BeBlogRepoResult<List<T>> list<T>(
    ApiResponse response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final statusCode = response.statusCode;
    if (!isSuccess(statusCode)) {
      return BeBlogRepoResult.fail(
        statusCode,
        BeBlogHttp.extractServerMessage(response.body),
      );
    }
    try {
      final raw = BeBlogHttp.decodeJsonList(
        BeBlogHttp.decodeBody(response.body),
      );
      return BeBlogRepoResult.ok(raw.map(fromJson).toList(), statusCode);
    } catch (e) {
      return BeBlogRepoResult.fail(statusCode, 'Parse error: $e');
    }
  }

  static BeBlogRepoResult<T> one<T>(
    ApiResponse response,
    T Function(Map<String, dynamic>) fromJson, {
    bool notFoundOn404 = true,
  }) {
    final statusCode = response.statusCode;
    if (notFoundOn404 && statusCode == 404) {
      return BeBlogRepoResult.fail(404, 'Not found');
    }
    if (!isSuccess(statusCode)) {
      return BeBlogRepoResult.fail(
        statusCode,
        BeBlogHttp.extractServerMessage(response.body),
      );
    }
    try {
      final json = BeBlogHttp.decodeJsonObject(
        BeBlogHttp.decodeBody(response.body),
      );
      return BeBlogRepoResult.ok(fromJson(json), statusCode);
    } catch (e) {
      return BeBlogRepoResult.fail(statusCode, 'Parse error: $e');
    }
  }

  static BeBlogRepoResult<void> delete(ApiResponse response) {
    final statusCode = response.statusCode;
    if (statusCode == 204 || statusCode == 200) {
      return BeBlogRepoResult.okEmpty(statusCode);
    }
    return BeBlogRepoResult.fail(
      statusCode,
      BeBlogHttp.extractServerMessage(response.body),
    );
  }
}
