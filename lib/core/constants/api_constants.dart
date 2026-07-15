import 'package:mobile/core/constants/api_base_url.dart';

/// REST paths aligned with [be-blog] Spring controllers.
///
/// **Base URL** ([baseUrl]): mặc định [productionBaseUrl] — xem [ApiBaseUrl].
///
/// Dev local: `flutter run --dart-define=USE_LOCAL_API=true`
/// Override: `flutter run --dart-define=API_BASE_URL=http://192.168.1.5:8080`
class ApiConstants {
  /// Backend production (Railway) — cùng URL với web-blog `NEXT_PUBLIC_API_URL`.
  static const String productionBaseUrl =
      'https://be-blog-production.up.railway.app';

  /// IP LAN Mac — chỉ dùng khi `USE_LOCAL_API=true` trên iPhone/iPad thật.
  static const String devLanHost = '192.168.1.3';

  static const int apiPort = 8080;

  static String get baseUrl => ApiBaseUrl.current;

  // --- Auth ---
  static const String authLogin = '/api/auth/login';
  static const String authGuest = '/api/auth/guest';
  static const String authRegister = '/api/auth/register';
  static const String authVerifyEmail = '/api/auth/verify-email';
  static const String authResendVerification = '/api/auth/resend-verification';
  static const String authForgotPassword = '/api/auth/forgot-password';
  static const String authResetPassword = '/api/auth/reset-password';

  /// Alias kept for existing [AuthRepository] imports.
  static const String login = authLogin;

  // --- Feed (home timeline; requires JWT) ---
  static const String feed = '/api/feed';
  static String feedForUser(String userId) => '/api/feed/users/$userId';

  // --- Posts ---
  static const String posts = '/api/posts';

  // --- Admin post moderation ---
  static const String adminPostsPending = '/api/admin/posts/pending';
  static String adminPostApprove(String id) => '/api/admin/posts/$id/approve';
  static String adminPostReject(String id) => '/api/admin/posts/$id/reject';

  // --- Books ---
  static const String books = '/api/books';
  static const String booksMe = '/api/books/me';

  // --- Reviews (Spring domain API; not legacy /api/book-reviews) ---
  static const String reviews = '/api/reviews';

  // --- Reading list (current user) ---
  static const String readingListMe = '/api/reading-list/me';

  // --- Personal productivity ---
  static const String notesMe = '/api/notes/me';
  static const String noteFolders = '/api/notes/me/folders';
  static const String noteLabels = '/api/notes/me/labels';
  static const String calendarMe = '/api/calendar/me';

  // --- Engagement ---
  static const String bookmarks = '/api/bookmarks';
  static const String bookmarksMe = '/api/bookmarks/me';
  static const String bookmarkStatus = '/api/bookmarks/status';
  static const String streakMe = '/api/streak/me';
  static const String trendingFeed = '/api/feed/trending';

  // --- Server-side archive search ---
  static const String search = '/api/search';

  // --- Catalog ---
  static const String tags = '/api/tags';
  static const String genres = '/api/genres';
  static const String authors = '/api/authors';

  // --- Users ---
  static const String users = '/api/users';
  static const String usersSearch = '/api/users/search';
  static const String usersMePosts = '/api/users/me/posts';
  static const String usersMePassword = '/api/users/me/password';

  // --- Notifications ---
  static const String notifications = '/api/notifications';
  static const String notificationsUnreadCount =
      '/api/notifications/unread-count';
  static String notificationMarkRead(String id) =>
      '/api/notifications/$id/read';
  static const String notificationsMarkAllRead = '/api/notifications/read-all';
  static const String notificationDevices = '/api/notifications/devices';

  // --- Friends ---
  static const String friends = '/api/friends';
  static const String friendsRequestsIncoming =
      '/api/friends/requests/incoming';
  static const String friendsRequestsOutgoing =
      '/api/friends/requests/outgoing';

  static String userProfile(String userId) => '/api/users/$userId/profile';
  static String userPosts(String userId) => '/api/users/$userId/posts';
  static String userBooks(String userId) => '/api/users/$userId/books';
  static String userReviews(String userId) => '/api/users/$userId/reviews';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
