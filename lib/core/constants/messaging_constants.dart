import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mobile/core/constants/api_constants.dart';

abstract final class MessagingConstants {
  static const String productionBaseUrl =
      'https://messaging-production.up.railway.app';
  static const int localPort = 8081;

  static bool get enabled {
    const value = String.fromEnvironment(
      'MESSAGING_ENABLED',
      defaultValue: 'true',
    );
    return value.toLowerCase() != 'false';
  }

  static String get baseUrl {
    const configured = String.fromEnvironment('MESSAGING_API_URL');
    if (configured.isNotEmpty) return _trimSlash(configured);

    const useLocal = bool.fromEnvironment('USE_LOCAL_API');
    if (!useLocal) return productionBaseUrl;
    if (kIsWeb) return 'http://localhost:$localPort';
    if (Platform.isAndroid) return 'http://10.0.2.2:$localPort';
    if (Platform.isIOS) {
      final simulator = Platform.environment.containsKey(
        'SIMULATOR_DEVICE_NAME',
      );
      return simulator
          ? 'http://127.0.0.1:$localPort'
          : 'http://${ApiConstants.devLanHost}:$localPort';
    }
    return 'http://localhost:$localPort';
  }

  static String _trimSlash(String value) =>
      value.endsWith('/') ? value.substring(0, value.length - 1) : value;
}
