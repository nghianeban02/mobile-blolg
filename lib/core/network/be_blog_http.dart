import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/images/image_auth_headers.dart';

/// Shared JWT storage key — matches [AuthRepository].
const String kAuthTokenPrefsKey = 'auth_token';

/// HTTP helpers for the Spring **be-blog** API (`application/json`, optional Bearer token).
class BeBlogHttp {
  BeBlogHttp._();

  static final Future<SharedPreferences> _prefs =
      SharedPreferences.getInstance();

  /// Bearer headers for `/api/images/**` (required by [SecurityConfig]).
  static Future<Map<String, String>> imageAuthHeaders() =>
      ImageAuthHeaders.get();

  static void invalidateImageAuthHeaders() => ImageAuthHeaders.invalidate();

  static Future<void> _applyBearerAuth(
    Map<String, String> headers, {
    required bool auth,
  }) async {
    if (!auth) return;
    final prefs = await _prefs;
    final token = prefs.getString(kAuthTokenPrefsKey);
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
  }

  static Future<Map<String, String>> jsonHeaders({bool auth = true}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    await _applyBearerAuth(headers, auth: auth);
    return headers;
  }

  /// Multipart POST must not set Content-Type (boundary is added by [http]).
  static Future<Map<String, String>> multipartHeaders({
    bool auth = true,
  }) async {
    final headers = <String, String>{'Accept': 'application/json'};
    await _applyBearerAuth(headers, auth: auth);
    return headers;
  }

  static Uri uri(String path, [Map<String, String>? query]) {
    final base = Uri.parse('${ApiConstants.baseUrl}$path');
    if (query == null || query.isEmpty) return base;
    return base.replace(queryParameters: query);
  }

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

  static Future<http.Response> get(
    String path, {
    bool auth = true,
    Map<String, String>? query,
  }) async {
    final headers = await jsonHeaders(auth: auth);
    return http
        .get(uri(path, query), headers: headers)
        .timeout(ApiConstants.receiveTimeout);
  }

  static Future<http.Response> postJson(
    String path, {
    bool auth = true,
    Object? body,
    Map<String, String>? query,
  }) async {
    final headers = await jsonHeaders(auth: auth);
    return http
        .post(
          uri(path, query),
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(ApiConstants.receiveTimeout);
  }

  /// POST without JSON body (e.g. Spring endpoints with no `@RequestBody`).
  static Future<http.Response> postEmpty(
    String path, {
    bool auth = true,
    Map<String, String>? query,
  }) async {
    final headers = await jsonHeaders(auth: auth);
    headers.remove('Content-Type');
    return http
        .post(uri(path, query), headers: headers)
        .timeout(ApiConstants.receiveTimeout);
  }

  static Future<http.Response> patchJson(
    String path, {
    bool auth = true,
    Object? body,
    Map<String, String>? query,
  }) async {
    final headers = await jsonHeaders(auth: auth);
    return http
        .patch(
          uri(path, query),
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(ApiConstants.receiveTimeout);
  }

  static Future<http.Response> putJson(
    String path, {
    bool auth = true,
    Object? body,
    Map<String, String>? query,
  }) async {
    final headers = await jsonHeaders(auth: auth);
    return http
        .put(
          uri(path, query),
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(ApiConstants.receiveTimeout);
  }

  static Future<http.Response> delete(
    String path, {
    bool auth = true,
    Map<String, String>? query,
  }) async {
    final headers = await jsonHeaders(auth: auth);
    return http
        .delete(uri(path, query), headers: headers)
        .timeout(ApiConstants.receiveTimeout);
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
