import 'package:mobile/core/auth/token_store.dart';

/// Shared JWT headers for protected image URLs (one load per session).
class ImageAuthHeaders {
  ImageAuthHeaders._();

  static Future<Map<String, String>>? _future;

  static Future<Map<String, String>> get() {
    return _future ??= _load();
  }

  static Future<Map<String, String>> _load() async {
    final token = await TokenStore.instance.read();
    if (token != null && token.isNotEmpty) {
      return {'Authorization': 'Bearer $token'};
    }
    return const {};
  }

  static void invalidate() {
    _future = null;
  }
}
