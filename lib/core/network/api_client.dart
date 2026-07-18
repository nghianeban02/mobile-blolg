import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile/core/auth/session_events.dart';
import 'package:mobile/core/auth/token_store.dart';
import 'package:mobile/core/config/app_config.dart';

/// Lỗi mạng (mất kết nối / timeout) — message thân thiện, hiển thị được ngay.
class NetworkException implements Exception {
  final String message;

  const NetworkException(this.message);

  @override
  String toString() => message;
}

/// Response tối giản cho tầng repository: [statusCode] + [body] (JSON string).
/// Giữ cùng shape với `http.Response` để repositories không phải đổi logic.
class ApiResponse {
  final int statusCode;
  final String body;

  const ApiResponse({required this.statusCode, required this.body});
}

/// HTTP client dùng Dio cho be-blog và messaging-service.
///
/// - Gắn `Authorization: Bearer` từ [TokenStore] (tùy chọn per-request).
/// - 4xx/5xx trả về như [ApiResponse] bình thường (repositories tự xét
///   statusCode), riêng 401 của request có auth sẽ phát [SessionEvents].
/// - Timeout / mất mạng ném [NetworkException] với message tiếng Việt.
/// - Log request khi debug, không bao giờ log body (tránh lộ mật khẩu/token).
class ApiClient {
  ApiClient({Dio? dio, TokenStore? tokenStore, SessionEvents? sessionEvents})
    : _tokenStore = tokenStore ?? TokenStore.instance,
      _sessionEvents = sessionEvents ?? SessionEvents.instance,
      dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: AppConfig.connectTimeout,
              receiveTimeout: AppConfig.receiveTimeout,
              // Không throw cho 4xx/5xx — trả response để repo xử lý.
              validateStatus: (_) => true,
              responseType: ResponseType.plain,
            ),
          ) {
    this.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final needsAuth = options.extra['auth'] != false;
          if (needsAuth) {
            final token = await _tokenStore.read();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          options.headers['Accept'] = 'application/json';
          if (kDebugMode) {
            debugPrint('[api] ${options.method} ${options.uri.path}');
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          final needsAuth = response.requestOptions.extra['auth'] != false;
          if (needsAuth && response.statusCode == 401) {
            _sessionEvents.notifySessionExpired();
          }
          handler.next(response);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient();

  final Dio dio;
  final TokenStore _tokenStore;
  final SessionEvents _sessionEvents;

  Future<ApiResponse> request(
    String method,
    String url, {
    bool auth = true,
    Map<String, String>? query,
    Object? jsonBody,
    FormData? formData,
    ProgressCallback? onSendProgress,
    Duration? sendTimeout,
  }) async {
    try {
      final response = await dio.request<String>(
        url,
        queryParameters: query,
        data: formData ?? (jsonBody == null ? null : jsonEncode(jsonBody)),
        onSendProgress: onSendProgress,
        options: Options(
          method: method,
          sendTimeout: sendTimeout,
          extra: {'auth': auth},
          contentType: formData != null
              ? null
              : (jsonBody != null ? 'application/json' : null),
        ),
      );
      return ApiResponse(
        statusCode: response.statusCode ?? 0,
        body: response.data ?? '',
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Exception _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(
          'Kết nối quá thời gian chờ. Vui lòng thử lại.',
        );
      case DioExceptionType.connectionError:
        return const NetworkException(
          'Không kết nối được máy chủ. Kiểm tra mạng trên thiết bị.',
        );
      default:
        if (e.error is SocketException) {
          return const NetworkException(
            'Không kết nối được máy chủ. Kiểm tra mạng trên thiết bị.',
          );
        }
        return e;
    }
  }
}
