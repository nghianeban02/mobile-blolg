import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lưu JWT trong secure storage (Keychain / EncryptedSharedPreferences).
///
/// Trước đây token nằm trong [SharedPreferences] (key `auth_token`) — lần đọc
/// đầu tiên sẽ tự migrate sang secure storage rồi xóa bản cũ.
class TokenStore {
  TokenStore._();

  static final TokenStore instance = TokenStore._();

  static const String _storageKey = 'auth_token';

  /// Key cũ trong SharedPreferences — chỉ dùng cho bước migrate.
  static const String legacyPrefsKey = 'auth_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );

  String? _cached;
  bool _loaded = false;

  /// Token hiện tại (null nếu chưa đăng nhập). Có cache in-memory.
  Future<String?> read() async {
    if (_loaded) return _cached;
    await _migrateFromPrefsIfNeeded();
    try {
      _cached = await _storage.read(key: _storageKey);
    } catch (_) {
      // Platform channel không sẵn sàng (unit test / thiết bị lỗi keystore).
      _cached = null;
    }
    _loaded = true;
    return _cached;
  }

  Future<void> write(String token) async {
    _cached = token;
    _loaded = true;
    try {
      await _storage.write(key: _storageKey, value: token);
    } catch (_) {}
  }

  Future<void> clear() async {
    _cached = null;
    _loaded = true;
    try {
      await _storage.delete(key: _storageKey);
    } catch (_) {}
  }

  Future<void> _migrateFromPrefsIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final legacy = prefs.getString(legacyPrefsKey);
      if (legacy != null && legacy.isNotEmpty) {
        await _storage.write(key: _storageKey, value: legacy);
        await prefs.remove(legacyPrefsKey);
      }
    } catch (_) {
      // Migrate lỗi thì bỏ qua — người dùng đăng nhập lại là có token mới.
    }
  }
}
