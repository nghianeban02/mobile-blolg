import 'package:mobile/core/network/be_blog_http.dart';

/// In-memory cache for list `GET` responses (shared across tabs/screens).
class ApiListCache {
  ApiListCache._();

  static const Duration defaultTtl = Duration(minutes: 2);

  static final Map<String, _Entry> _entries = {};

  static const String postsKey = 'posts';
  static const String reviewsKey = 'reviews';
  static const String booksKey = 'books';
  static const String feedKey = 'feed';
  static const String myBooksKey = 'books/me';
  static const String myPostsKey = 'users/me/posts';

  static String userBooksKey(String userId) => 'users/$userId/books';
  static String userPostsKey(String userId) => 'users/$userId/posts';
  static String userReviewsKey(String userId) => 'users/$userId/reviews';

  static String reviewsKeyForBook(String? bookId) =>
      bookId == null || bookId.isEmpty
      ? reviewsKey
      : '$reviewsKey?bookId=$bookId';

  /// Returns cached list when fresh; otherwise runs [fetch] and stores the result.
  static Future<BeBlogRepoResult<List<T>>> getOrFetch<T>({
    required String key,
    required Future<BeBlogRepoResult<List<T>>> Function() fetch,
    Duration ttl = defaultTtl,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final hit = peek<T>(key);
      if (hit != null) {
        return BeBlogRepoResult.ok(hit, 200);
      }
    }

    final result = await fetch();
    if (result.success && result.data != null) {
      put(key, result.data!, ttl: ttl);
    }
    return result;
  }

  static List<T>? peek<T>(String key) {
    final entry = _entries[key];
    if (entry == null || entry.isExpired) {
      _entries.remove(key);
      return null;
    }
    return entry.data as List<T>?;
  }

  static void put<T>(String key, List<T> data, {Duration ttl = defaultTtl}) {
    _entries[key] = _Entry(data, DateTime.now().add(ttl));
  }

  static void invalidate(String key) => _entries.remove(key);

  static void invalidatePosts() {
    invalidate(postsKey);
    invalidate(myPostsKey);
  }

  static void invalidateReviews({String? bookId}) {
    invalidate(reviewsKey);
    if (bookId != null && bookId.isNotEmpty) {
      invalidate(reviewsKeyForBook(bookId));
    }
  }

  static void invalidateBooks() {
    invalidate(booksKey);
    invalidate(myBooksKey);
  }

  static void invalidateFeed() => invalidate(feedKey);

  static void invalidateUserLibrary(String userId) {
    invalidate(userBooksKey(userId));
    invalidate(userPostsKey(userId));
    invalidate(userReviewsKey(userId));
  }

  static void clear() => _entries.clear();
}

class _Entry {
  final List<dynamic> data;
  final DateTime expiresAt;

  _Entry(this.data, this.expiresAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
