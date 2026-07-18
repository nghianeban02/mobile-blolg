import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:mobile/core/auth/token_store.dart';
import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/core/network/api_client.dart';
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

  static String get baseUrl => AppConfig.messagingBaseUrl;

  static String get wsBaseUrl => AppConfig.messagingWsBaseUrl;

  static Future<String?> authToken() async {
    final token = await TokenStore.instance.read();
    return (token == null || token.isEmpty) ? null : token;
  }

  static Future<dynamic> _request(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
  }) async {
    if (!AppConfig.messagingEnabled) {
      throw const MessagingApiException(503, 'Tính năng nhắn tin đang tắt.');
    }
    final token = await authToken();
    if (token == null) {
      throw const MessagingApiException(401, 'Bạn cần đăng nhập để nhắn tin.');
    }
    final ApiResponse response;
    try {
      response = await ApiClient.instance.request(
        method,
        '$baseUrl$path',
        query: query,
        jsonBody: body,
      );
    } on NetworkException catch (e) {
      throw MessagingApiException(0, e.message);
    }
    if (response.statusCode == 204) return null;
    final dynamic decoded;
    try {
      decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    } catch (_) {
      throw MessagingApiException(
        response.statusCode,
        'Dịch vụ nhắn tin đang bận. Vui lòng thử lại.',
      );
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    final message = decoded is Map
        ? (decoded['error'] as String? ?? decoded['message'] as String?)
        : null;
    throw MessagingApiException(
      response.statusCode,
      message ?? 'Dịch vụ nhắn tin đang bận. Vui lòng thử lại.',
    );
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
    final result = _map(
      await _request(
        'GET',
        '/api/chat/conversations',
        query: {'size': '$size'},
      ),
    );
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
    final result = _map(
      await _request(
        'POST',
        '/api/chat/conversations/direct',
        body: {'recipientId': recipientId},
      ),
    );
    return result['id'] as String? ?? '';
  }

  static Future<String> createGroup(
    String title,
    List<String> memberIds,
  ) async {
    final result = _map(
      await _request(
        'POST',
        '/api/chat/conversations/group',
        body: {'title': title, 'memberIds': memberIds},
      ),
    );
    return result['id'] as String? ?? '';
  }

  // --- Messages ---

  static Future<({List<ChatMessage> items, int? nextCursor})> messages(
    String conversationId, {
    int? before,
    int size = 50,
  }) async {
    final result = _map(
      await _request(
        'GET',
        '/api/chat/conversations/$conversationId/messages',
        query: {'size': '$size', if (before != null) 'before': '$before'},
      ),
    );
    final items = (result['items'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ChatMessage.fromJson)
        .toList();
    return (items: items, nextCursor: (result['nextCursor'] as num?)?.toInt());
  }

  static Future<ChatMessage> sendMessage(
    String conversationId, {
    required String clientId,
    String type = 'TEXT',
    String? content,
    String? replyToId,
    String? attachmentId,
  }) async {
    final result = _map(
      await _request(
        'POST',
        '/api/chat/conversations/$conversationId/messages',
        body: {
          'clientId': clientId,
          'type': type,
          'content': ?content,
          'replyToId': ?replyToId,
          'attachmentId': ?attachmentId,
        },
      ),
    );
    return ChatMessage.fromJson({...result, 'conversationId': conversationId});
  }

  static Future<void> markRead(String conversationId, int sequence) => _request(
    'POST',
    '/api/chat/conversations/$conversationId/read',
    body: {'sequence': sequence},
  );

  static Future<void> revoke(String messageId) =>
      _request('DELETE', '/api/chat/messages/$messageId');

  /// Xóa tin nhắn chỉ phía mình.
  static Future<void> hideMessage(String messageId) =>
      _request('POST', '/api/chat/messages/$messageId/hide');

  static Future<({String content, DateTime? editedAt})> editMessage(
    String messageId,
    String content,
  ) async {
    final result = _map(
      await _request(
        'PATCH',
        '/api/chat/messages/$messageId',
        body: {'content': content},
      ),
    );
    return (
      content: result['content'] as String? ?? content,
      editedAt: DateTime.tryParse(
        result['editedAt'] as String? ?? '',
      )?.toLocal(),
    );
  }

  static Future<void> react(String messageId, String emoji) => _request(
    'PUT',
    '/api/chat/messages/$messageId/reactions',
    body: {'value': emoji},
  );

  static Future<void> unreact(String messageId, String emoji) => _request(
    'DELETE',
    '/api/chat/messages/$messageId/reactions',
    query: {'value': emoji},
  );

  // --- Attachments (presign → PUT bytes → complete → send message) ---

  static Future<
    ({
      String attachmentId,
      String? uploadPath,
      String uploadUrl,
      String method,
      Map<String, String> headers,
    })
  >
  presignAttachment(
    String conversationId, {
    required String name,
    required String mimeType,
    required int sizeBytes,
  }) async {
    final result = _map(
      await _request(
        'POST',
        '/api/chat/conversations/$conversationId/attachments/presign',
        body: {'name': name, 'mimeType': mimeType, 'sizeBytes': sizeBytes},
      ),
    );
    final headers = <String, String>{};
    final rawHeaders = result['headers'];
    if (rawHeaders is Map) {
      rawHeaders.forEach((key, value) {
        if (key != null && value != null) headers['$key'] = '$value';
      });
    }
    final uploadPath = result['uploadPath'] as String?;
    return (
      attachmentId: result['attachmentId'] as String? ?? '',
      uploadPath: (uploadPath != null && uploadPath.isNotEmpty)
          ? uploadPath
          : null,
      uploadUrl: result['uploadUrl'] as String? ?? '',
      method: (result['method'] as String? ?? 'PUT').toUpperCase(),
      headers: headers,
    );
  }

  static Future<void> completeAttachment(String attachmentId) async {
    await _request('POST', '/api/chat/attachments/$attachmentId/complete');
  }

  /// Upload file qua messaging API có JWT (ưu tiên), fallback presigned URL.
  static Future<String> uploadAttachment(
    String conversationId,
    File file, {
    String? mimeType,
    void Function(double progress)? onProgress,
  }) async {
    final bytes = await file.length();
    if (bytes <= 0) {
      throw const MessagingApiException(400, 'Tệp ảnh trống.');
    }
    final name = file.uri.pathSegments.isEmpty
        ? 'image.jpg'
        : file.uri.pathSegments.last;
    final type = (mimeType != null && mimeType.isNotEmpty)
        ? mimeType
        : _guessMimeType(name);
    final ticket = await presignAttachment(
      conversationId,
      name: name,
      mimeType: type,
      sizeBytes: bytes,
    );
    if (ticket.attachmentId.isEmpty) {
      throw const MessagingApiException(
        500,
        'Không tạo được liên kết tải lên.',
      );
    }
    final useDirect = ticket.uploadPath != null;
    final url = useDirect ? '$baseUrl${ticket.uploadPath}' : ticket.uploadUrl;
    if (url.isEmpty) {
      throw const MessagingApiException(
        500,
        'Không tạo được liên kết tải lên.',
      );
    }
    try {
      final response = await ApiClient.instance.dio.request<List<int>>(
        url,
        data: file.openRead(),
        options: Options(
          method: ticket.method,
          headers: {...ticket.headers, Headers.contentLengthHeader: bytes},
          contentType: type,
          // Direct path cần JWT; presigned thì tắt auth.
          extra: {'auth': useDirect},
          responseType: ResponseType.bytes,
          sendTimeout: const Duration(minutes: 2),
          receiveTimeout: const Duration(minutes: 2),
          validateStatus: (_) => true,
        ),
        onSendProgress: onProgress == null
            ? null
            : (sent, total) {
                if (total > 0) onProgress(sent / total);
              },
      );
      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        throw MessagingApiException(status, 'Không tải được ảnh lên.');
      }
    } on DioException catch (e) {
      if (e.error is SocketException) {
        throw const MessagingApiException(
          0,
          'Không kết nối được máy chủ. Kiểm tra mạng trên thiết bị.',
        );
      }
      throw const MessagingApiException(0, 'Không tải được ảnh lên.');
    }
    if (!useDirect) await completeAttachment(ticket.attachmentId);
    onProgress?.call(1);
    return ticket.attachmentId;
  }

  /// Upload từ bytes (khi ImagePicker trả XFile không phải path file ổn định).
  static Future<String> uploadAttachmentBytes(
    String conversationId, {
    required Uint8List bytes,
    required String name,
    required String mimeType,
    void Function(double progress)? onProgress,
  }) async {
    if (bytes.isEmpty) {
      throw const MessagingApiException(400, 'Tệp ảnh trống.');
    }
    final type = mimeType.isNotEmpty ? mimeType : _guessMimeType(name);
    final ticket = await presignAttachment(
      conversationId,
      name: name,
      mimeType: type,
      sizeBytes: bytes.length,
    );
    if (ticket.attachmentId.isEmpty) {
      throw const MessagingApiException(
        500,
        'Không tạo được liên kết tải lên.',
      );
    }
    final useDirect = ticket.uploadPath != null;
    final url = useDirect ? '$baseUrl${ticket.uploadPath}' : ticket.uploadUrl;
    if (url.isEmpty) {
      throw const MessagingApiException(
        500,
        'Không tạo được liên kết tải lên.',
      );
    }
    try {
      final response = await ApiClient.instance.dio.request<List<int>>(
        url,
        data: bytes,
        options: Options(
          method: ticket.method,
          headers: {
            ...ticket.headers,
            Headers.contentLengthHeader: bytes.length,
          },
          contentType: type,
          extra: {'auth': useDirect},
          responseType: ResponseType.bytes,
          sendTimeout: const Duration(minutes: 2),
          receiveTimeout: const Duration(minutes: 2),
          validateStatus: (_) => true,
        ),
        onSendProgress: onProgress == null
            ? null
            : (sent, total) {
                if (total > 0) onProgress(sent / total);
              },
      );
      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        throw MessagingApiException(status, 'Không tải được ảnh lên.');
      }
    } on DioException catch (e) {
      if (e.error is SocketException) {
        throw const MessagingApiException(
          0,
          'Không kết nối được máy chủ. Kiểm tra mạng trên thiết bị.',
        );
      }
      throw const MessagingApiException(0, 'Không tải được ảnh lên.');
    }
    if (!useDirect) await completeAttachment(ticket.attachmentId);
    onProgress?.call(1);
    return ticket.attachmentId;
  }

  static Future<String> attachmentDownloadUrl(String attachmentId) async {
    final result = _map(
      await _request('GET', '/api/chat/attachments/$attachmentId/download'),
    );
    return result['url'] as String? ?? '';
  }

  // --- Calls (WebRTC) ---

  static Future<ChatConfig> config() async {
    final result = _map(await _request('GET', '/api/chat/config'));
    return ChatConfig.fromJson(result);
  }

  static Future<ChatCall> createCall(String conversationId, String mode) async {
    final result = _map(
      await _request(
        'POST',
        '/api/chat/conversations/$conversationId/calls',
        body: {'mode': mode},
      ),
    );
    return ChatCall.fromJson(result);
  }

  static Future<ChatCall> answerCall(String callId) async {
    final result = _map(
      await _request('POST', '/api/chat/calls/$callId/answer'),
    );
    return ChatCall.fromJson(result);
  }

  static Future<ChatCall> rejectCall(String callId) async {
    final result = _map(
      await _request('POST', '/api/chat/calls/$callId/reject'),
    );
    return ChatCall.fromJson(result);
  }

  static Future<ChatCall> endCall(String callId) async {
    final result = _map(await _request('POST', '/api/chat/calls/$callId/end'));
    return ChatCall.fromJson(result);
  }

  static Future<void> persistCallSignal(Map<String, dynamic> signal) async {
    await _request('POST', '/api/chat/call-signals', body: signal);
  }

  static Future<({List<ChatRealtimeEvent> items, String nextCursor})>
  callSignals({String after = '0'}) async {
    final result = _map(
      await _request('GET', '/api/chat/call-signals', query: {'after': after}),
    );
    final items = (result['items'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ChatRealtimeEvent.fromJson)
        .toList();
    final next = result['nextCursor']?.toString() ?? after;
    return (items: items, nextCursor: next);
  }

  static String _guessMimeType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) return 'image/heic';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    return 'image/jpeg';
  }
}
