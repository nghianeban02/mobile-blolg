import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/images/image_auth_headers.dart';
import 'package:mobile/core/network/api_client.dart';

export 'package:mobile/core/network/api_client.dart' show ApiResponse;

/// Façade cho be-blog API — mọi request đi qua [ApiClient] (Dio) với
/// interceptor gắn Bearer, map lỗi mạng và phát tín hiệu 401.
class BeBlogHttp {
  BeBlogHttp._();

  static ApiClient get _client => ApiClient.instance;

  /// Bearer headers for `/api/images/**` (required by [SecurityConfig]).
  static Future<Map<String, String>> imageAuthHeaders() =>
      ImageAuthHeaders.get();

  static void invalidateImageAuthHeaders() => ImageAuthHeaders.invalidate();

  static Uri uri(String path, [Map<String, String>? query]) {
    final base = Uri.parse('${ApiConstants.baseUrl}$path');
    if (query == null || query.isEmpty) return base;
    return base.replace(queryParameters: query);
  }

  static String _url(String path) => '${ApiConstants.baseUrl}$path';

  static dynamic decodeBody(String body) {
    if (body.isEmpty) return null;
    return jsonDecode(body);
  }

  /// Raw JSON array, or Spring Data `Page` (`{ "content": [ ... ] }`).
  static List<Map<String, dynamic>> decodeJsonList(dynamic decoded) {
    if (decoded is List) {
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    if (decoded is Map) {
      final content = decoded['content'];
      if (content is List) {
        return content.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    }
    throw FormatException(
      'Expected JSON array or paginated page with "content", got ${decoded.runtimeType}',
    );
  }

  static Map<String, dynamic> decodeJsonObject(dynamic decoded) {
    if (decoded is! Map) {
      throw FormatException('Expected JSON object, got ${decoded.runtimeType}');
    }
    return Map<String, dynamic>.from(decoded);
  }

  static String? extractServerMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        return decoded['error']?.toString() ?? decoded['message']?.toString();
      }
    } catch (_) {}
    return null;
  }

  static Future<ApiResponse> get(
    String path, {
    bool auth = true,
    Map<String, String>? query,
  }) => _client.request('GET', _url(path), auth: auth, query: query);

  static Future<ApiResponse> postJson(
    String path, {
    bool auth = true,
    Object? body,
    Map<String, String>? query,
  }) => _client.request(
    'POST',
    _url(path),
    auth: auth,
    query: query,
    jsonBody: body,
  );

  /// POST without JSON body (e.g. Spring endpoints with no `@RequestBody`).
  static Future<ApiResponse> postEmpty(
    String path, {
    bool auth = true,
    Map<String, String>? query,
  }) => _client.request('POST', _url(path), auth: auth, query: query);

  static Future<ApiResponse> patchJson(
    String path, {
    bool auth = true,
    Object? body,
    Map<String, String>? query,
  }) => _client.request(
    'PATCH',
    _url(path),
    auth: auth,
    query: query,
    jsonBody: body,
  );

  static Future<ApiResponse> putJson(
    String path, {
    bool auth = true,
    Object? body,
    Map<String, String>? query,
  }) => _client.request(
    'PUT',
    _url(path),
    auth: auth,
    query: query,
    jsonBody: body,
  );

  static Future<ApiResponse> delete(
    String path, {
    bool auth = true,
    Map<String, String>? query,
  }) => _client.request('DELETE', _url(path), auth: auth, query: query);

  /// Multipart POST/PUT với tiến trình upload ([onSendProgress] 0.0 → 1.0).
  ///
  /// [files]: field name → danh sách file (be-blog nhận `titleImage`,
  /// `coverImage`, `images`, `image` tùy endpoint).
  static Future<ApiResponse> multipart(
    String method,
    String path, {
    Map<String, String> fields = const {},
    Map<String, List<File>> files = const {},
    void Function(double progress)? onSendProgress,
  }) async {
    final formData = FormData();
    fields.forEach((key, value) {
      formData.fields.add(MapEntry(key, value));
    });
    for (final entry in files.entries) {
      for (final file in entry.value) {
        formData.files.add(
          MapEntry(
            entry.key,
            await MultipartFile.fromFile(
              file.path,
              filename: file.uri.pathSegments.isNotEmpty
                  ? file.uri.pathSegments.last
                  : 'upload',
            ),
          ),
        );
      }
    }
    return ApiClient.instance.request(
      method,
      _url(path),
      formData: formData,
      onSendProgress: onSendProgress == null
          ? null
          : (sent, total) {
              if (total > 0) onSendProgress(sent / total);
            },
      // Upload ảnh lớn cần thời gian gửi dài hơn timeout mặc định.
      sendTimeout: const Duration(minutes: 3),
    );
  }
}

/// Typed outcome for repository calls (no exceptions for 4xx/5xx — inspect [message]).
class BeBlogRepoResult<T> {
  final bool success;
  final int statusCode;
  final T? data;
  final String? message;

  const BeBlogRepoResult({
    required this.success,
    required this.statusCode,
    this.data,
    this.message,
  });

  factory BeBlogRepoResult.ok(T data, [int code = 200]) =>
      BeBlogRepoResult(success: true, statusCode: code, data: data);

  factory BeBlogRepoResult.fail(int code, [String? message]) =>
      BeBlogRepoResult(success: false, statusCode: code, message: message);

  /// Successful DELETE / 204-style responses (no parsed body).
  static BeBlogRepoResult<void> okEmpty(int statusCode) =>
      BeBlogRepoResult<void>(success: true, statusCode: statusCode);
}
