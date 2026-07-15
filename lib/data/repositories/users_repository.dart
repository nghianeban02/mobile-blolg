import 'package:mobile/core/cache/api_list_cache.dart';
import 'package:mobile/core/cache/session_cache.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/be_blog_http.dart';
import 'package:mobile/core/network/be_blog_response_parser.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/data/repositories/reviews_repository.dart';

/// Mirrors [UserController].
class BeBlogUsersRepository {
  /// `GET /api/users/search?q=...`
  Future<BeBlogRepoResult<List<UserPublicDto>>> searchUsers(
    String query, {
    int page = 0,
    int size = 50,
  }) async {
    final q = query.trim();
    if (q.isEmpty) {
      return BeBlogRepoResult.ok(const []);
    }
    final response = await BeBlogHttp.get(
      ApiConstants.usersSearch,
      query: {'q': q, 'page': '$page', 'size': '$size'},
    );
    return BeBlogResponseParser.list(response, UserPublicDto.fromJson);
  }

  Future<BeBlogRepoResult<UserProfileDto>> me({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = SessionCache.profile;
      if (cached != null) return BeBlogRepoResult.ok(cached);
    }
    final response = await BeBlogHttp.get('${ApiConstants.users}/me');
    final result = BeBlogResponseParser.one(response, UserProfileDto.fromJson);
    if (result.success && result.data != null) {
      SessionCache.setProfile(result.data!);
    }
    return result;
  }

  Future<BeBlogRepoResult<UserProfileViewDto>> getProfile(String userId) async {
    final response = await BeBlogHttp.get(ApiConstants.userProfile(userId));
    return BeBlogResponseParser.one(response, UserProfileViewDto.fromJson);
  }

  Future<BeBlogRepoResult<List<PostDto>>> getUserPosts(
    String userId, {
    bool forceRefresh = false,
  }) async {
    return ApiListCache.getOrFetch(
      key: ApiListCache.userPostsKey(userId),
      forceRefresh: forceRefresh,
      fetch: () async {
        final response = await BeBlogHttp.get(
          ApiConstants.userPosts(userId),
          query: const {'page': '0', 'size': '100'},
        );
        return BeBlogResponseParser.list(response, PostDto.fromJson);
      },
    );
  }

  Future<BeBlogRepoResult<List<BookDto>>> getUserBooks(
    String userId, {
    bool forceRefresh = false,
  }) async {
    return ApiListCache.getOrFetch(
      key: ApiListCache.userBooksKey(userId),
      forceRefresh: forceRefresh,
      fetch: () async {
        final response = await BeBlogHttp.get(
          ApiConstants.userBooks(userId),
          query: const {'page': '0', 'size': '100'},
        );
        return BeBlogResponseParser.list(response, BookDto.fromJson);
      },
    );
  }

  /// Public profile: chỉ review `published` (be-blog `listForUserProfile`).
  Future<BeBlogRepoResult<List<ReviewDto>>> getUserReviews(
    String userId, {
    bool forceRefresh = false,
  }) async {
    return ApiListCache.getOrFetch(
      key: ApiListCache.userReviewsKey(userId),
      forceRefresh: forceRefresh,
      fetch: () async {
        final response = await BeBlogHttp.get(
          ApiConstants.userReviews(userId),
          query: const {'page': '0', 'size': '100'},
        );
        return BeBlogResponseParser.list(response, ReviewDto.fromJson);
      },
    );
  }

  /// Trang profile: của mình → mọi trạng thái; người khác → chỉ published.
  Future<BeBlogRepoResult<List<ReviewDto>>> getProfileReviews(
    String userId, {
    required bool isOwnProfile,
    bool forceRefresh = false,
  }) async {
    if (isOwnProfile) {
      return BeBlogReviewsRepository().getAll(forceRefresh: forceRefresh);
    }
    return getUserReviews(userId, forceRefresh: forceRefresh);
  }

  Future<BeBlogRepoResult<UserProfileDto>> updateMe({
    String? avatarUrl,
    String? bio,
    String? title,
    String? feedVisibility,
  }) async {
    final body = <String, dynamic>{
      'avatarUrl': ?avatarUrl,
      'bio': ?bio,
      'title': ?title,
      'feedVisibility': ?feedVisibility,
    };
    final response = await BeBlogHttp.putJson(
      '${ApiConstants.users}/me',
      body: body,
    );
    return BeBlogResponseParser.one(response, UserProfileDto.fromJson);
  }

  /// `PUT /api/users/me/password` — đổi mật khẩu.
  Future<BeBlogRepoResult<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await BeBlogHttp.putJson(
      ApiConstants.usersMePassword,
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
    if (BeBlogResponseParser.isSuccess(response.statusCode)) {
      return BeBlogRepoResult.okEmpty(response.statusCode);
    }
    return BeBlogRepoResult.fail(
      response.statusCode,
      BeBlogHttp.extractServerMessage(response.body) ??
          'Không thể đổi mật khẩu.',
    );
  }
}
