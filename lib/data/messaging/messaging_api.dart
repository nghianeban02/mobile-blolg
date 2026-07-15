import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/core/network/be_blog_http.dart' show kAuthTokenPrefsKey;
import 'package:mobile/data/messaging/chat_models.dart';

/// Lỗi từ messaging-service — message đã thân thiện để hiển thị trực tiếp.
class MessagingApiException implements Exception {
  final int statusCode;
  final String message;

  const MessagingApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

/// REST client cho **messaging-service** (`nook-messaging` trên Railway) —
/// mirror `web-blog/lib/api/messaging.ts`.
///
/// Dev local: `flutter run --dart-define=USE_LOCAL_MESSAGING=true`
/// Override:  `--dart-define=MESSAGING_BASE_URL=http://192.168.1.5:8081`
class MessagingApi {
  MessagingApi._();

  static const String productionBaseUrl =
      'https://messages-blog-production.up.railway.app';

  static String get baseUrl {
    const fromEnv = String.fromEnvironment('MESSAGING_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    const useLocal = bool.fromEnvironment('USE_LOCAL_MESSAGING');
    if (!useLocal) return productionBaseUrl;
    if (kIsWeb) return 'http://localhost:8081';
    if (Platform.isAndroid) return 'http://10.0.2.2:8081';
    return 'http://127.0.0.1:8081';
  }

  static String get wsBaseUrl =>
      baseUrl.replaceFirst(RegExp('^http'), 'ws');

  static const Duration _timeout = Duration(seconds: 15);

  static Future<String?> authToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(kAuthTokenPrefsKey);
    return (token == null || token.isEmpty) ? null : token;
  }

  static Future<dynamic> _request(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
  }) async {
    final token = await authToken();
    if (token == null) {
      throw const MessagingApiException(401, 'Bạn cần đăng nhập để nhắn tin.');
    }
    var uri = Uri.parse('$baseUrl$path');
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: query);
    }
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
    };
    final encoded = body == null ? null : jsonEncode(body);
    final http.Response response;
    switch (method) {
      case 'POST':
        response =
            await http.post(uri, headers: headers, body: encoded).timeout(_timeout);
      case 'PUT':
        response =
            await http.put(uri, headers: headers, body: encoded).timeout(_timeout);
      case 'PATCH':
        response = await http
            .patch(uri, headers: headers, body: encoded)
            .timeout(_timeout);
      case 'DELETE':
        response =
            await http.delete(uri, headers: headers).timeout(_timeout);
      default:
        response = await http.get(uri, headers: headers).timeout(_timeout);
    }
    if (response.statusCode == 204) return null;
    final dynamic decoded;
    try {
      decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    } catch (_) {
      throw MessagingApiException(
          response.statusCode, 'Dịch vụ nhắn tin đang bận. Vui lòng thử lại.');
    }
    if (response.statusCode >= 200 && response.statusCode < 300) return decoded;
    final message = decoded is Map
        ? (decoded['error'] as String? ?? decoded['message'] as String?)
        : null;
    throw MessagingApiException(response.statusCode,
        message ?? 'Dịch vụ nhắn tin đang bận. Vui lòng thử lại.');
  }

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map<String, dynamic> ? value : <String, dynamic>{};

  // --- Realtime ---

  static Future<String> wsTicket() async {
    final result = _map(await _request('POST', '/api/chat/ws-ticket'));
    return result['ticket'] as String? ?? '';
  }

  // --- Conversations ---

  static Future<List<ChatConversation>> conversations({int size = 100}) async {
    final result = _map(await _request('GET', '/api/chat/conversations',
        query: {'size': '$size'}));
    return (result['items'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ChatConversation.fromJson)
        .toList();
  }

  static Future<int> unreadCount() async {
    final result = _map(await _request('GET', '/api/chat/unread-count'));
    return (result['unreadCount'] as num?)?.toInt() ?? 0;
  }

  static Future<List<ChatFriend>> friends() async {
    final result = await _request('GET', '/api/chat/friends');
    return (result as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ChatFriend.fromJson)
        .toList();
  }

  static Future<String> createDirect(String recipientId) async {
    final result = _map(await _request('POST', '/api/chat/conversations/direct',
        body: {'recipientId': recipientId}));
    return result['id'] as String? ?? '';
  }

  static Future<String> createGroup(String title, List<String> memberIds) async {
    final result = _map(await _request('POST', '/api/chat/conversations/group',
        body: {'title': title, 'memberIds': memberIds}));
    return result['id'] as String? ?? '';
  }

  // --- Messages ---

  static Future<({List<ChatMessage> items, int? nextCursor})> messages(
    String conversationId, {
    int? before,
    int size = 50,
  }) async {
    final result = _map(await _request(
      'GET',
      '/api/chat/conversations/$conversationId/messages',
      query: {'size': '$size', if (before != null) 'before': '$before'},
    ));
    final items = (result['items'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ChatMessage.fromJson)
        .toList();
    return (
      items: items,
      nextCursor: (result['nextCursor'] as num?)?.toInt(),
    );
  }

  static Future<ChatMessage> sendMessage(
    String conversationId, {
    required String clientId,
    String type = 'TEXT',
    String? content,
    String? replyToId,
  }) async {
    final result = _map(await _request(
      'POST',
      '/api/chat/conversations/$conversationId/messages',
      body: {
        'clientId': clientId,
        'type': type,
        'content': ?content,
        'replyToId': ?replyToId,
      },
    ));
    return ChatMessage.fromJson({...result, 'conversationId': conversationId});
  }

  static Future<void> markRead(String conversationId, int sequence) =>
      _request('POST', '/api/chat/conversations/$conversationId/read',
          body: {'sequence': sequence});

  static Future<void> revoke(String messageId) =>
      _request('DELETE', '/api/chat/messages/$messageId');

  static Future<({String content, DateTime? editedAt})> editMessage(
      String messageId, String content) async {
    final result = _map(await _request(
        'PATCH', '/api/chat/messages/$messageId',
        body: {'content': content}));
    return (
      content: result['content'] as String? ?? content,
      editedAt: DateTime.tryParse(result['editedAt'] as String? ?? '')?.toLocal(),
    );
  }

  static Future<void> react(String messageId, String emoji) =>
      _request('PUT', '/api/chat/messages/$messageId/reactions',
          body: {'value': emoji});

  static Future<void> unreact(String messageId, String emoji) =>
      _request('DELETE', '/api/chat/messages/$messageId/reactions',
          query: {'value': emoji});

  // --- Attachments ---

  static Future<String> attachmentDownloadUrl(String attachmentId) async {
    final result = _map(
        await _request('GET', '/api/chat/attachments/$attachmentId/download'));
    return result['url'] as String? ?? '';
  }
}
