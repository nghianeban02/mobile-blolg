import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/constants/messaging_constants.dart';
import 'package:mobile/core/network/be_blog_http.dart';
import 'package:mobile/data/models/messaging_dtos.dart';

class MessagingRepository {
  /// Ticket một lần dùng cho kết nối WebSocket (`/ws?ticket=…`).
  Future<BeBlogRepoResult<String>> wsTicket() async {
    final result = await _request('POST', '/api/chat/ws-ticket');
    return _stringFieldResult(result, 'ticket');
  }

  Future<BeBlogRepoResult<List<ChatFriendDto>>> getFriends() async {
    final result = await _request('GET', '/api/chat/friends');
    return _listResult(result, ChatFriendDto.fromJson);
  }

  Future<BeBlogRepoResult<List<ChatConversationDto>>> getConversations({
    int size = 50,
  }) async {
    final result = await _request(
      'GET',
      '/api/chat/conversations',
      query: {'size': '$size'},
    );
    return _listResult(
      result,
      ChatConversationDto.fromJson,
      envelopeKey: 'items',
    );
  }

  Future<BeBlogRepoResult<String>> createDirect(String recipientId) async {
    final result = await _request(
      'POST',
      '/api/chat/conversations/direct',
      body: {'recipientId': recipientId},
    );
    return _stringFieldResult(result, 'id');
  }

  Future<BeBlogRepoResult<String>> createGroup(
    String title,
    List<String> memberIds,
  ) async {
    final result = await _request(
      'POST',
      '/api/chat/conversations/group',
      body: {'title': title.trim(), 'memberIds': memberIds},
    );
    return _stringFieldResult(result, 'id');
  }

  Future<BeBlogRepoResult<List<ChatMessageDto>>> getMessages(
    String conversationId, {
    int size = 100,
  }) async {
    final result = await _request(
      'GET',
      '/api/chat/conversations/$conversationId/messages',
      query: {'size': '$size'},
    );
    return _listResult(result, ChatMessageDto.fromJson, envelopeKey: 'items');
  }

  Future<BeBlogRepoResult<List<ChatMessageDto>>> searchMessages(
    String query, {
    String? conversationId,
  }) async {
    final result = await _request(
      'GET',
      '/api/chat/search',
      query: {
        'q': query.trim(),
        'size': '50',
        'conversationId': ?conversationId,
      },
    );
    return _listResult(result, ChatMessageDto.fromJson, envelopeKey: 'items');
  }

  Future<BeBlogRepoResult<ChatMessageDto>> sendMessage(
    String conversationId,
    String content, {
    String type = 'TEXT',
    String? attachmentId,
  }) async {
    final result = await _request(
      'POST',
      '/api/chat/conversations/$conversationId/messages',
      body: {
        'clientId': '${DateTime.now().microsecondsSinceEpoch}',
        'type': type,
        'content': content.trim().isEmpty ? null : content.trim(),
        'attachmentId': attachmentId,
      },
    );
    return _oneResult(result, ChatMessageDto.fromJson);
  }

  Future<BeBlogRepoResult<void>> markRead(
    String conversationId,
    int sequence,
  ) async {
    final result = await _request(
      'POST',
      '/api/chat/conversations/$conversationId/read',
      body: {'sequence': sequence},
    );
    return _emptyResult(result);
  }

  Future<BeBlogRepoResult<void>> revokeMessage(String messageId) async {
    final result = await _request('DELETE', '/api/chat/messages/$messageId');
    return _emptyResult(result);
  }

  Future<BeBlogRepoResult<void>> react(String messageId, String emoji) async {
    final result = await _request(
      'PUT',
      '/api/chat/messages/$messageId/reactions',
      body: {'value': emoji},
    );
    return _emptyResult(result);
  }

  Future<BeBlogRepoResult<void>> unreact(String messageId, String emoji) async {
    final result = await _request(
      'DELETE',
      '/api/chat/messages/$messageId/reactions',
      query: {'value': emoji},
    );
    return _emptyResult(result);
  }

  Future<BeBlogRepoResult<String>> uploadImage(
    String conversationId,
    File file,
  ) async {
    final bytes = await file.readAsBytes();
    final name = file.uri.pathSegments.isEmpty
        ? 'image.jpg'
        : file.uri.pathSegments.last;
    final ticketResult = await _request(
      'POST',
      '/api/chat/conversations/$conversationId/attachments/presign',
      body: {
        'name': name,
        'mimeType': _imageMime(name),
        'sizeBytes': bytes.length,
      },
    );
    if (!ticketResult.success || ticketResult.data is! Map) {
      return BeBlogRepoResult.fail(
        ticketResult.statusCode,
        ticketResult.message,
      );
    }
    final ticket = Map<String, dynamic>.from(ticketResult.data as Map);
    final attachmentId = ticket['attachmentId']?.toString() ?? '';
    final uploadUrl = ticket['uploadUrl']?.toString() ?? '';
    if (attachmentId.isEmpty || uploadUrl.isEmpty) {
      return BeBlogRepoResult.fail(500, 'Dịch vụ không trả URL tải ảnh.');
    }
    final headers = ticket['headers'] is Map
        ? Map<String, String>.from(
            (ticket['headers'] as Map).map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            ),
          )
        : <String, String>{};
    final upload = await http
        .put(Uri.parse(uploadUrl), headers: headers, body: bytes)
        .timeout(ApiConstants.receiveTimeout);
    if (upload.statusCode < 200 || upload.statusCode >= 300) {
      return BeBlogRepoResult.fail(
        upload.statusCode,
        'Không tải được ảnh chat.',
      );
    }
    final complete = await _request(
      'POST',
      '/api/chat/attachments/$attachmentId/complete',
    );
    if (!complete.success) {
      return BeBlogRepoResult.fail(complete.statusCode, complete.message);
    }
    return BeBlogRepoResult.ok(attachmentId);
  }

  Future<BeBlogRepoResult<String>> attachmentDownloadUrl(
    String attachmentId,
  ) async {
    final result = await _request(
      'GET',
      '/api/chat/attachments/$attachmentId/download',
    );
    return _stringFieldResult(result, 'url');
  }

  String _imageMime(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  Future<BeBlogRepoResult<dynamic>> _request(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
  }) async {
    if (!MessagingConstants.enabled) {
      return BeBlogRepoResult.fail(503, 'Tính năng nhắn tin đang tắt.');
    }
    try {
      final base = Uri.parse('${MessagingConstants.baseUrl}$path');
      final uri = query == null ? base : base.replace(queryParameters: query);
      final request = http.Request(method, uri);
      request.headers.addAll(await BeBlogHttp.jsonHeaders());
      if (body != null) request.body = jsonEncode(body);
      final streamed = await request.send().timeout(
        ApiConstants.connectTimeout,
      );
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return BeBlogRepoResult.fail(
          response.statusCode,
          BeBlogHttp.extractServerMessage(response.body) ??
              'Dịch vụ nhắn tin đang bận.',
        );
      }
      if (response.body.isEmpty) {
        return BeBlogRepoResult.ok(null, response.statusCode);
      }
      return BeBlogRepoResult.ok(
        jsonDecode(response.body),
        response.statusCode,
      );
    } on Exception catch (error) {
      return BeBlogRepoResult.fail(
        0,
        'Không kết nối được dịch vụ nhắn tin: $error',
      );
    }
  }

  BeBlogRepoResult<List<T>> _listResult<T>(
    BeBlogRepoResult<dynamic> result,
    T Function(Map<String, dynamic>) fromJson, {
    String? envelopeKey,
  }) {
    if (!result.success) {
      return BeBlogRepoResult.fail(result.statusCode, result.message);
    }
    try {
      dynamic raw = result.data;
      if (envelopeKey != null && raw is Map) raw = raw[envelopeKey];
      if (raw is! List) throw const FormatException('Expected list');
      return BeBlogRepoResult.ok(
        raw
            .whereType<Map>()
            .map((item) => fromJson(Map<String, dynamic>.from(item)))
            .toList(),
        result.statusCode,
      );
    } catch (error) {
      return BeBlogRepoResult.fail(
        result.statusCode,
        'Dữ liệu nhắn tin không hợp lệ: $error',
      );
    }
  }

  BeBlogRepoResult<T> _oneResult<T>(
    BeBlogRepoResult<dynamic> result,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (!result.success) {
      return BeBlogRepoResult.fail(result.statusCode, result.message);
    }
    try {
      return BeBlogRepoResult.ok(
        fromJson(Map<String, dynamic>.from(result.data as Map)),
        result.statusCode,
      );
    } catch (error) {
      return BeBlogRepoResult.fail(result.statusCode, 'Parse error: $error');
    }
  }

  BeBlogRepoResult<String> _stringFieldResult(
    BeBlogRepoResult<dynamic> result,
    String field,
  ) {
    if (!result.success) {
      return BeBlogRepoResult.fail(result.statusCode, result.message);
    }
    final value = result.data is Map
        ? (result.data as Map)[field]?.toString()
        : null;
    return value == null || value.isEmpty
        ? BeBlogRepoResult.fail(
            result.statusCode,
            'Thiếu $field trong phản hồi.',
          )
        : BeBlogRepoResult.ok(value, result.statusCode);
  }

  BeBlogRepoResult<void> _emptyResult(BeBlogRepoResult<dynamic> result) =>
      result.success
      ? BeBlogRepoResult.okEmpty(result.statusCode)
      : BeBlogRepoResult.fail(result.statusCode, result.message);
}
