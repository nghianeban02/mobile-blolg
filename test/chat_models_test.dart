import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/messaging/chat_models.dart';

void main() {
  test('ChatConversation parse payload từ messaging-service', () {
    final conversation = ChatConversation.fromJson({
      'id': 'c1',
      'type': 'DIRECT',
      'title': null,
      'members': [
        {'userId': 'u1', 'username': 'an', 'avatarUrl': null, 'role': 'OWNER'},
        {'userId': 'u2', 'username': 'binh', 'avatarUrl': '/a.png', 'role': 'MEMBER'},
      ],
      'lastMessage': {
        'id': 'm9',
        'senderId': 'u2',
        'type': 'STICKER',
        'content': '🔥',
        'encrypted': false,
        'revokedAt': null,
      },
      'lastMessageAt': '2026-07-15T10:00:00Z',
      'unreadCount': 3,
    });

    expect(conversation.displayName('u1'), 'binh');
    expect(conversation.otherMember('u1')?.avatarUrl, '/a.png');
    expect(conversation.unreadCount, 3);
    expect(conversation.lastMessage?.type, 'STICKER');
    expect(conversation.isGroup, isFalse);
  });

  test('ChatMessage parse reply + reactions + editedAt', () {
    final message = ChatMessage.fromJson({
      'id': 'm1',
      'sequence': 42,
      'conversationId': 'c1',
      'senderId': 'u2',
      'senderUsername': 'binh',
      'type': 'TEXT',
      'content': 'xin chào',
      'encrypted': false,
      'replyTo': {'id': 'm0', 'senderId': 'u1', 'content': 'hi', 'type': 'TEXT', 'revokedAt': null},
      'reactions': [
        {'userId': 'u1', 'emoji': '❤️'},
        {'userId': 'u2', 'emoji': '❤️'},
      ],
      'createdAt': '2026-07-15T10:00:00Z',
      'editedAt': '2026-07-15T10:05:00Z',
      'revokedAt': null,
    });

    expect(message.sequence, 42);
    expect(message.replyTo?.content, 'hi');
    expect(message.reactions, hasLength(2));
    expect(message.editedAt, isNotNull);
    expect(message.revoked, isFalse);

    final revoked = message.copyWith(clearContent: true, revokedAt: DateTime.now());
    expect(revoked.content, isNull);
    expect(revoked.revoked, isTrue);
  });

  test('ChatRealtimeEvent lấy conversationId từ payload hoặc aggregateId', () {
    final fromPayload = ChatRealtimeEvent.fromJson({
      'type': 'message.created',
      'payload': {'conversationId': 'c9'},
    });
    expect(fromPayload.conversationId, 'c9');

    final fromAggregate = ChatRealtimeEvent.fromJson({
      'type': 'typing.start',
      'aggregateId': 'c7',
      'payload': <String, dynamic>{},
    });
    expect(fromAggregate.conversationId, 'c7');
  });
}
