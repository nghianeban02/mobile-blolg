/// Models cho messaging-service (`nook-messaging`) — mirror `web-blog/lib/messaging/types.ts`.
library;

String? _string(dynamic value) => value is String ? value : null;

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

class ChatMember {
  final String userId;
  final String username;
  final String? avatarUrl;
  final String role;

  const ChatMember({
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.role = 'MEMBER',
  });

  factory ChatMember.fromJson(Map<String, dynamic> json) => ChatMember(
        userId: _string(json['userId']) ?? '',
        username: _string(json['username']) ?? '',
        avatarUrl: _string(json['avatarUrl']),
        role: _string(json['role']) ?? 'MEMBER',
      );
}

class MessageReaction {
  final String userId;
  final String emoji;

  const MessageReaction({required this.userId, required this.emoji});

  factory MessageReaction.fromJson(Map<String, dynamic> json) =>
      MessageReaction(
        userId: _string(json['userId']) ?? '',
        emoji: _string(json['emoji']) ?? '',
      );
}

class ChatAttachment {
  final String id;
  final String name;
  final String mimeType;
  final int sizeBytes;

  const ChatAttachment({
    required this.id,
    required this.name,
    required this.mimeType,
    required this.sizeBytes,
  });

  bool get isImage => mimeType.startsWith('image/');

  factory ChatAttachment.fromJson(Map<String, dynamic> json) => ChatAttachment(
        id: _string(json['id']) ?? '',
        name: _string(json['name']) ?? '',
        mimeType: _string(json['mimeType']) ?? 'application/octet-stream',
        sizeBytes: _int(json['sizeBytes']),
      );
}

class ChatReplyPreview {
  final String id;
  final String senderId;
  final String? content;
  final String type;
  final bool revoked;

  const ChatReplyPreview({
    required this.id,
    required this.senderId,
    this.content,
    this.type = 'TEXT',
    this.revoked = false,
  });

  factory ChatReplyPreview.fromJson(Map<String, dynamic> json) =>
      ChatReplyPreview(
        id: _string(json['id']) ?? '',
        senderId: _string(json['senderId']) ?? '',
        content: _string(json['content']),
        type: _string(json['type']) ?? 'TEXT',
        revoked: json['revokedAt'] != null,
      );
}

class ChatMessage {
  final String id;
  final double sequence;
  final String conversationId;
  final String senderId;
  final String senderUsername;
  final String type; // TEXT | IMAGE | FILE | STICKER | SYSTEM | CALL
  final String? content;
  final bool encrypted;
  final ChatReplyPreview? replyTo;
  final ChatAttachment? attachment;
  final List<MessageReaction> reactions;
  final DateTime createdAt;
  final DateTime? editedAt;
  final DateTime? revokedAt;

  /// Optimistic — đang chờ server xác nhận (chỉ tồn tại phía client).
  final bool pending;
  final String? clientId;

  /// Đường dẫn ảnh local khi đang upload (chỉ phía client).
  final String? localPreviewPath;

  const ChatMessage({
    required this.id,
    required this.sequence,
    required this.conversationId,
    required this.senderId,
    required this.senderUsername,
    required this.type,
    required this.content,
    required this.encrypted,
    this.replyTo,
    this.attachment,
    this.reactions = const [],
    required this.createdAt,
    this.editedAt,
    this.revokedAt,
    this.pending = false,
    this.clientId,
    this.localPreviewPath,
  });

  bool get revoked => revokedAt != null;

  ChatMessage copyWith({
    double? sequence,
    String? content,
    ChatAttachment? attachment,
    List<MessageReaction>? reactions,
    DateTime? editedAt,
    DateTime? revokedAt,
    bool? pending,
    String? localPreviewPath,
    bool clearContent = false,
    bool clearLocalPreview = false,
  }) =>
      ChatMessage(
        id: id,
        sequence: sequence ?? this.sequence,
        conversationId: conversationId,
        senderId: senderId,
        senderUsername: senderUsername,
        type: type,
        content: clearContent ? null : (content ?? this.content),
        encrypted: encrypted,
        replyTo: replyTo,
        attachment: attachment ?? this.attachment,
        reactions: reactions ?? this.reactions,
        createdAt: createdAt,
        editedAt: editedAt ?? this.editedAt,
        revokedAt: revokedAt ?? this.revokedAt,
        pending: pending ?? this.pending,
        clientId: clientId,
        localPreviewPath:
            clearLocalPreview ? null : (localPreviewPath ?? this.localPreviewPath),
      );

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: _string(json['id']) ?? '',
        sequence: (json['sequence'] as num?)?.toDouble() ?? 0,
        conversationId: _string(json['conversationId']) ?? '',
        senderId: _string(json['senderId']) ?? '',
        senderUsername: _string(json['senderUsername']) ?? '',
        type: _string(json['type']) ?? 'TEXT',
        content: _string(json['content']),
        encrypted: json['encrypted'] == true,
        replyTo: json['replyTo'] is Map<String, dynamic>
            ? ChatReplyPreview.fromJson(json['replyTo'] as Map<String, dynamic>)
            : null,
        attachment: json['attachment'] is Map<String, dynamic>
            ? ChatAttachment.fromJson(json['attachment'] as Map<String, dynamic>)
            : null,
        reactions: (json['reactions'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(MessageReaction.fromJson)
                .toList() ??
            const [],
        createdAt:
            DateTime.tryParse(_string(json['createdAt']) ?? '')?.toLocal() ??
                DateTime.now(),
        editedAt: DateTime.tryParse(_string(json['editedAt']) ?? '')?.toLocal(),
        revokedAt:
            DateTime.tryParse(_string(json['revokedAt']) ?? '')?.toLocal(),
        clientId: _string(json['clientId']),
      );
}

class ChatLastMessage {
  final String id;
  final String senderId;
  final String type;
  final String? content;
  final bool encrypted;
  final bool revoked;

  const ChatLastMessage({
    required this.id,
    required this.senderId,
    required this.type,
    this.content,
    this.encrypted = false,
    this.revoked = false,
  });

  factory ChatLastMessage.fromJson(Map<String, dynamic> json) =>
      ChatLastMessage(
        id: _string(json['id']) ?? '',
        senderId: _string(json['senderId']) ?? '',
        type: _string(json['type']) ?? 'TEXT',
        content: _string(json['content']),
        encrypted: json['encrypted'] == true,
        revoked: json['revokedAt'] != null,
      );
}

class ChatConversation {
  final String id;
  final String type; // DIRECT | GROUP
  final String? title;
  final List<ChatMember> members;
  final ChatLastMessage? lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;

  const ChatConversation({
    required this.id,
    required this.type,
    this.title,
    required this.members,
    this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = 0,
  });

  bool get isGroup => type == 'GROUP';

  ChatMember? otherMember(String? currentUserId) {
    for (final member in members) {
      if (member.userId != currentUserId) return member;
    }
    return null;
  }

  String displayName(String? currentUserId) {
    if (isGroup) return title?.trim().isNotEmpty == true ? title! : 'Nhóm chat';
    return otherMember(currentUserId)?.username ?? 'Cuộc trò chuyện';
  }

  ChatConversation copyWith({
    ChatLastMessage? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
  }) =>
      ChatConversation(
        id: id,
        type: type,
        title: title,
        members: members,
        lastMessage: lastMessage ?? this.lastMessage,
        lastMessageAt: lastMessageAt ?? this.lastMessageAt,
        unreadCount: unreadCount ?? this.unreadCount,
      );

  factory ChatConversation.fromJson(Map<String, dynamic> json) =>
      ChatConversation(
        id: _string(json['id']) ?? '',
        type: _string(json['type']) ?? 'DIRECT',
        title: _string(json['title']),
        members: (json['members'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(ChatMember.fromJson)
                .toList() ??
            const [],
        lastMessage: json['lastMessage'] is Map<String, dynamic>
            ? ChatLastMessage.fromJson(
                json['lastMessage'] as Map<String, dynamic>)
            : null,
        lastMessageAt:
            DateTime.tryParse(_string(json['lastMessageAt']) ?? '')?.toLocal() ??
                DateTime.now(),
        unreadCount: _int(json['unreadCount']),
      );
}

class ChatFriend {
  final String id;
  final String username;
  final String? avatarUrl;

  const ChatFriend({required this.id, required this.username, this.avatarUrl});

  factory ChatFriend.fromJson(Map<String, dynamic> json) => ChatFriend(
        id: _string(json['id']) ?? '',
        username: _string(json['username']) ?? '',
        avatarUrl: _string(json['avatarUrl']),
      );
}

class ChatCall {
  final String id;
  final String conversationId;
  final String initiatorId;
  final String mode; // AUDIO | VIDEO
  final String status;
  final DateTime? startedAt;

  const ChatCall({
    required this.id,
    required this.conversationId,
    required this.initiatorId,
    required this.mode,
    required this.status,
    this.startedAt,
  });

  factory ChatCall.fromJson(Map<String, dynamic> json) => ChatCall(
        id: _string(json['id']) ?? '',
        conversationId: _string(json['conversationId']) ?? '',
        initiatorId: _string(json['initiatorId']) ?? '',
        mode: _string(json['mode']) == 'VIDEO' ? 'VIDEO' : 'AUDIO',
        status: _string(json['status']) ?? 'RINGING',
        startedAt:
            DateTime.tryParse(_string(json['startedAt']) ?? '')?.toLocal(),
      );
}

class ChatIceServer {
  final List<String> urls;
  final String? username;
  final String? credential;

  const ChatIceServer({
    required this.urls,
    this.username,
    this.credential,
  });

  factory ChatIceServer.fromJson(Map<String, dynamic> json) {
    final raw = json['urls'];
    final urls = raw is List
        ? raw.map((e) => '$e').where((e) => e.isNotEmpty).toList()
        : raw is String
            ? [raw]
            : <String>[];
    return ChatIceServer(
      urls: urls,
      username: _string(json['username']),
      credential: _string(json['credential']),
    );
  }

  Map<String, dynamic> toWebRtcMap() => {
        'urls': urls.length == 1 ? urls.first : urls,
        if (username != null) 'username': username,
        if (credential != null) 'credential': credential,
      };
}

class ChatConfig {
  final bool turnAvailable;
  final List<ChatIceServer> iceServers;

  const ChatConfig({
    required this.turnAvailable,
    required this.iceServers,
  });

  factory ChatConfig.fromJson(Map<String, dynamic> json) => ChatConfig(
        turnAvailable: json['turnAvailable'] == true,
        iceServers: (json['iceServers'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(ChatIceServer.fromJson)
                .toList() ??
            const [],
      );
}

/// Sự kiện realtime từ WebSocket (`message.created`, `typing.start`…).
class ChatRealtimeEvent {
  final String type;
  final String? aggregateId;
  final Map<String, dynamic> payload;

  const ChatRealtimeEvent({
    required this.type,
    this.aggregateId,
    required this.payload,
  });

  String? get conversationId =>
      _string(payload['conversationId']) ?? aggregateId;

  factory ChatRealtimeEvent.fromJson(Map<String, dynamic> json) =>
      ChatRealtimeEvent(
        type: _string(json['type']) ?? '',
        aggregateId: _string(json['aggregateId']),
        payload: json['payload'] is Map<String, dynamic>
            ? json['payload'] as Map<String, dynamic>
            : const {},
      );
}
