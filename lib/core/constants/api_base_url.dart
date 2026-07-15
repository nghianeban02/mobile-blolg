import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:mobile/core/constants/api_constants.dart';

/// Resolves [ApiConstants.baseUrl] — production mặc định, local khi dev.
abstract final class ApiBaseUrl {
  static String get current {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;

    const useLocal = bool.fromEnvironment('USE_LOCAL_API');
    if (!useLocal) return ApiConstants.productionBaseUrl;

    if (kIsWeb) return 'http://localhost:${ApiConstants.apiPort}';

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:${ApiConstants.apiPort}';
    }

    if (Platform.isIOS) {
      if (_isIosSimulator) {
        return 'http://127.0.0.1:${ApiConstants.apiPort}';
      }
      return 'http://${ApiConstants.devLanHost}:${ApiConstants.apiPort}';
    }

    return 'http://localhost:${ApiConstants.apiPort}';
  }

  /// True when running on iOS Simulator (not physical iPhone/iPad).
  static bool get _isIosSimulator {
    if (!Platform.isIOS) return false;
    final env = Platform.environment;
    return env.containsKey('SIMULATOR_DEVICE_NAME') ||
        env.containsKey('SIMULATOR_RUNTIME_VERSION') ||
        env.containsKey('SIMULATOR_MODEL_IDENTIFIER');
  }
}
