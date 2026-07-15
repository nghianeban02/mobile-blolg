DateTime? _chatDate(dynamic value) =>
    value == null ? null : DateTime.tryParse(value.toString());

class ChatMemberDto {
  final String userId;
  final String username;
  final String? avatarUrl;
  final String role;

  const ChatMemberDto({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.role,
  });

  factory ChatMemberDto.fromJson(Map<String, dynamic> json) => ChatMemberDto(
    userId: json['userId']?.toString() ?? '',
    username: json['username']?.toString() ?? '',
    avatarUrl: json['avatarUrl']?.toString(),
    role: json['role']?.toString() ?? 'MEMBER',
  );
}

class ChatReactionDto {
  final String userId;
  final String emoji;

  const ChatReactionDto({required this.userId, required this.emoji});

  factory ChatReactionDto.fromJson(Map<String, dynamic> json) =>
      ChatReactionDto(
        userId: json['userId']?.toString() ?? '',
        emoji: json['emoji']?.toString() ?? '',
      );
}

class ChatAttachmentDto {
  final String id;
  final String name;
  final String mimeType;
  final int sizeBytes;
  final String status;

  const ChatAttachmentDto({
    required this.id,
    required this.name,
    required this.mimeType,
    required this.sizeBytes,
    required this.status,
  });

  factory ChatAttachmentDto.fromJson(Map<String, dynamic> json) =>
      ChatAttachmentDto(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'attachment',
        mimeType: json['mimeType']?.toString() ?? 'application/octet-stream',
        sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
        status: json['status']?.toString() ?? 'PENDING',
      );
}

class ChatMessageDto {
  final String id;
  final int sequence;
  final String conversationId;
  final String senderId;
  final String senderUsername;
  final String type;
  final String? content;
  final ChatAttachmentDto? attachment;
  final List<ChatReactionDto> reactions;
  final DateTime? createdAt;
  final DateTime? revokedAt;

  const ChatMessageDto({
    required this.id,
    required this.sequence,
    required this.conversationId,
    required this.senderId,
    required this.senderUsername,
    required this.type,
    this.content,
    this.attachment,
    this.reactions = const [],
    this.createdAt,
    this.revokedAt,
  });

  factory ChatMessageDto.fromJson(Map<String, dynamic> json) {
    final attachment = json['attachment'];
    final reactions = json['reactions'];
    return ChatMessageDto(
      id: json['id']?.toString() ?? '',
      sequence: (json['sequence'] as num?)?.toInt() ?? 0,
      conversationId: json['conversationId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      senderUsername: json['senderUsername']?.toString() ?? '',
      type: json['type']?.toString() ?? 'TEXT',
      content: json['content']?.toString(),
      attachment: attachment is Map
          ? ChatAttachmentDto.fromJson(Map<String, dynamic>.from(attachment))
          : null,
      reactions: reactions is List
          ? reactions
                .whereType<Map>()
                .map(
                  (e) => ChatReactionDto.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
      createdAt: _chatDate(json['createdAt']),
      revokedAt: _chatDate(json['revokedAt']),
    );
  }
}

class ChatLastMessageDto {
  final String id;
  final int sequence;
  final String senderId;
  final String type;
  final String? content;
  final DateTime? createdAt;
  final DateTime? revokedAt;

  const ChatLastMessageDto({
    required this.id,
    required this.sequence,
    required this.senderId,
    required this.type,
    this.content,
    this.createdAt,
    this.revokedAt,
  });

  factory ChatLastMessageDto.fromJson(Map<String, dynamic> json) =>
      ChatLastMessageDto(
        id: json['id']?.toString() ?? '',
        sequence: (json['sequence'] as num?)?.toInt() ?? 0,
        senderId: json['senderId']?.toString() ?? '',
        type: json['type']?.toString() ?? 'TEXT',
        content: json['content']?.toString(),
        createdAt: _chatDate(json['createdAt']),
        revokedAt: _chatDate(json['revokedAt']),
      );
}

class ChatConversationDto {
  final String id;
  final String type;
  final String? title;
  final String? avatarUrl;
  final String createdBy;
  final List<ChatMemberDto> members;
  final ChatLastMessageDto? lastMessage;
  final int unreadCount;
  final int lastReadSequence;
  final DateTime? lastMessageAt;

  const ChatConversationDto({
    required this.id,
    required this.type,
    this.title,
    this.avatarUrl,
    required this.createdBy,
    this.members = const [],
    this.lastMessage,
    this.unreadCount = 0,
    this.lastReadSequence = 0,
    this.lastMessageAt,
  });

  factory ChatConversationDto.fromJson(Map<String, dynamic> json) {
    final members = json['members'];
    final lastMessage = json['lastMessage'];
    return ChatConversationDto(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'DIRECT',
      title: json['title']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      createdBy: json['createdBy']?.toString() ?? '',
      members: members is List
          ? members
                .whereType<Map>()
                .map(
                  (e) => ChatMemberDto.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
      lastMessage: lastMessage is Map
          ? ChatLastMessageDto.fromJson(Map<String, dynamic>.from(lastMessage))
          : null,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      lastReadSequence: (json['lastReadSequence'] as num?)?.toInt() ?? 0,
      lastMessageAt: _chatDate(json['lastMessageAt']),
    );
  }

  String displayTitle(String? currentUserId) {
    final explicit = title?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    final other = members.where((member) => member.userId != currentUserId);
    if (other.isNotEmpty) {
      return other.map((member) => member.username).join(', ');
    }
    return members.isNotEmpty ? members.first.username : 'Cuộc trò chuyện';
  }
}

class ChatFriendDto {
  final String id;
  final String username;
  final String? avatarUrl;

  const ChatFriendDto({
    required this.id,
    required this.username,
    this.avatarUrl,
  });

  factory ChatFriendDto.fromJson(Map<String, dynamic> json) => ChatFriendDto(
    id: json['id']?.toString() ?? '',
    username: json['username']?.toString() ?? '',
    avatarUrl: json['avatarUrl']?.toString(),
  );
}
