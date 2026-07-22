import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Cấu hình môi trường hợp nhất — đọc từ `--dart-define` /
/// `--dart-define-from-file` (xem `config/*.example.json`).
///
/// Chạy dev:  `flutter run --dart-define-from-file=config/dev.json`
/// Build prod: `flutter build apk --dart-define-from-file=config/production.json`
abstract final class AppConfig {
  // --- Environment ---

  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'production',
  );

  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => !isDevelopment;

  /// Tên hiển thị kèm suffix môi trường (chỉ dùng cho debug UI / log).
  static String get appLabel => isDevelopment ? 'Nook Dev' : 'Nook';

  // --- be-blog API ---

  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
  );
  static const bool _useLocalApi = bool.fromEnvironment('USE_LOCAL_API');

  /// Backend production (Railway) — cùng URL với web-blog `NEXT_PUBLIC_API_URL`.
  static const String productionApiBaseUrl =
      'https://be-blog-production.up.railway.app';

  /// IP LAN máy dev — dùng khi `USE_LOCAL_API=true` trên thiết bị thật.
  static const String devLanHost = String.fromEnvironment(
    'DEV_LAN_HOST',
    defaultValue: '192.168.1.3',
  );

  static const int _apiPort = 8080;

  static String get apiBaseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;
    if (!_useLocalApi) return productionApiBaseUrl;
    return _localHostBase(_apiPort);
  }

  // --- messaging-service ---

  static const String _messagingBaseUrlOverride = String.fromEnvironment(
    'MESSAGING_BASE_URL',
  );
  static const bool _useLocalMessaging = bool.fromEnvironment(
    'USE_LOCAL_MESSAGING',
  );

  static const bool messagingEnabled = bool.fromEnvironment(
    'MESSAGING_ENABLED',
    defaultValue: true,
  );

  static const String productionMessagingBaseUrl =
      'https://messages-blog-production.up.railway.app';

  static const int _messagingPort = 8081;

  static String get messagingBaseUrl {
    if (_messagingBaseUrlOverride.isNotEmpty) return _messagingBaseUrlOverride;
    if (!_useLocalMessaging) return productionMessagingBaseUrl;
    return _localHostBase(_messagingPort);
  }

  static String get messagingWsBaseUrl =>
      messagingBaseUrl.replaceFirst(RegExp('^http'), 'ws');

  /// Public web origin — dùng cho share link `/p/posts|reviews/...`.
  static const String siteUrl = String.fromEnvironment(
    'SITE_URL',
    defaultValue: 'https://nooknh.com',
  );

  static String publicPostUrl(String id) => '$siteUrl/p/posts/$id';

  static String publicReviewUrl(String id) => '$siteUrl/p/reviews/$id';

  // --- Timeouts ---

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Host local theo nền tảng: emulator Android dùng 10.0.2.2,
  /// iOS simulator dùng loopback, iPhone thật dùng IP LAN.
  static String _localHostBase(int port) {
    if (kIsWeb) return 'http://localhost:$port';
    if (Platform.isAndroid) return 'http://10.0.2.2:$port';
    if (Platform.isIOS && !_isIosSimulator) return 'http://$devLanHost:$port';
    return 'http://127.0.0.1:$port';
  }

  static bool get _isIosSimulator {
    if (kIsWeb || !Platform.isIOS) return false;
    final env = Platform.environment;
    return env.containsKey('SIMULATOR_DEVICE_NAME') ||
        env.containsKey('SIMULATOR_RUNTIME_VERSION') ||
        env.containsKey('SIMULATOR_MODEL_IDENTIFIER');
  }
}
