import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/models/messaging_dtos.dart';

void main() {
  test('direct conversation derives the other member title', () {
    final conversation = ChatConversationDto.fromJson({
      'id': 'chat-1',
      'type': 'DIRECT',
      'createdBy': 'u-1',
      'members': [
        {'userId': 'u-1', 'username': 'me', 'role': 'MEMBER'},
        {'userId': 'u-2', 'username': 'nghia', 'role': 'MEMBER'},
      ],
      'unreadCount': 3,
    });

    expect(conversation.displayTitle('u-1'), 'nghia');
    expect(conversation.unreadCount, 3);
  });

  test('message parser supports attachment, reactions and revoke state', () {
    final message = ChatMessageDto.fromJson({
      'id': 'm-1',
      'sequence': 9,
      'conversationId': 'chat-1',
      'senderId': 'u-2',
      'senderUsername': 'nghia',
      'type': 'IMAGE',
      'attachment': {
        'id': 'a-1',
        'name': 'cover.jpg',
        'mimeType': 'image/jpeg',
        'sizeBytes': 1024,
        'status': 'READY',
      },
      'reactions': [
        {'userId': 'u-1', 'emoji': '❤️'},
      ],
      'revokedAt': '2026-07-15T04:05:06Z',
    });

    expect(message.sequence, 9);
    expect(message.attachment?.name, 'cover.jpg');
    expect(message.reactions.single.emoji, '❤️');
    expect(message.revokedAt, isNotNull);
  });
}
