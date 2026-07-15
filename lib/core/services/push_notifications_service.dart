import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/be_blog_http.dart';

/// Đăng ký thiết bị nhận thông báo đẩy (FCM) từ **be-blog**
/// (`DeviceTokenController` — `POST/DELETE /api/notifications/devices`).
///
/// Tự vô hiệu hoá (no-op) khi thiếu cấu hình Firebase native
/// (`android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`)
/// nên app vẫn chạy bình thường trước khi Firebase được thiết lập.
class PushNotificationsService {
  PushNotificationsService._();

  static final PushNotificationsService instance = PushNotificationsService._();

  static const String _lastTokenPrefsKey = 'push_device_token';

  bool _initialized = false;
  StreamSubscription<String>? _tokenRefreshSubscription;

  /// `true` khi Firebase đã khởi tạo thành công trên thiết bị này.
  bool get isAvailable => _initialized;

  /// Khởi tạo Firebase + lắng nghe token refresh, rồi đồng bộ đăng ký
  /// nếu người dùng đã đăng nhập. Gọi một lần từ `main()`.
  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    try {
      await Firebase.initializeApp();
      _initialized = true;
    } catch (e) {
      debugPrint('Push notifications disabled (Firebase not configured): $e');
      return;
    }
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh
        .listen((token) {
          unawaited(_registerToken(token));
        });
    await syncRegistration();
  }

  /// Xin quyền và đăng ký token với be-blog — gọi sau khi đăng nhập
  /// thành công hoặc khi mở app với phiên đăng nhập sẵn có.
  Future<void> syncRegistration() async {
    if (!_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final auth = prefs.getString(kAuthTokenPrefsKey);
      if (auth == null || auth.isEmpty) return;

      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;
      await _registerToken(token);
    } catch (e) {
      debugPrint('Push registration failed: $e');
    }
  }

  /// Gỡ token trên be-blog và xoá token cục bộ — gọi TRƯỚC khi logout
  /// (cần JWT còn hiệu lực để xác thực yêu cầu gỡ).
  Future<void> unregister() async {
    if (!_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token =
          prefs.getString(_lastTokenPrefsKey) ??
          await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        final encoded = Uri.encodeQueryComponent(token);
        await BeBlogHttp.delete(
          '${ApiConstants.notificationDevices}?token=$encoded',
        );
      }
      await prefs.remove(_lastTokenPrefsKey);
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('Push token unregister failed: $e');
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final auth = prefs.getString(kAuthTokenPrefsKey);
      if (auth == null || auth.isEmpty) return;

      final platform = Platform.isIOS ? 'IOS' : 'ANDROID';
      final response = await BeBlogHttp.postJson(
        ApiConstants.notificationDevices,
        body: {'token': token, 'platform': platform},
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await prefs.setString(_lastTokenPrefsKey, token);
      }
    } catch (e) {
      debugPrint('Push token register failed: $e');
    }
  }
}
