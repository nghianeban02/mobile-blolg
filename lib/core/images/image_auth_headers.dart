import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/core/network/be_blog_http.dart';

/// Shared JWT headers for protected image URLs (one load per session).
class ImageAuthHeaders {
  ImageAuthHeaders._();

  static final Future<SharedPreferences> _prefs =
      SharedPreferences.getInstance();
  static Future<Map<String, String>>? _future;

  static Future<Map<String, String>> get() {
    return _future ??= _load();
  }

  static Future<Map<String, String>> _load() async {
    final prefs = await _prefs;
    final token = prefs.getString(kAuthTokenPrefsKey);
    if (token != null && token.isNotEmpty) {
      return {'Authorization': 'Bearer $token'};
    }
    return const {};
  }

  static void invalidate() {
    _future = null;
  }
}
