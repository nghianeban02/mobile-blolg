import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/services/messaging_realtime_service.dart';
import 'package:mobile/data/models/dtos.dart';

void main() {
  group('LikeStatusDto', () {
    test('parse đầy đủ trạng thái từ be-blog', () {
      final status = LikeStatusDto.fromJson({
        'count': 7,
        'likedByMe': true,
        'myReaction': 'CLAP',
        'reactions': {'HEART': 4, 'CLAP': 2, 'SAD': 1},
      });
      expect(status.count, 7);
      expect(status.likedByMe, isTrue);
      expect(status.myReaction, 'CLAP');
      expect(status.reactions, {'HEART': 4, 'CLAP': 2, 'SAD': 1});
    });

    test('bỏ qua reaction lạ và count <= 0', () {
      final status = LikeStatusDto.fromJson({
        'count': 3,
        'likedByMe': false,
        'myReaction': 'UNKNOWN',
        'reactions': {'HEART': 3, 'FIRE': 9, 'WOW': 0},
      });
      expect(status.myReaction, isNull);
      expect(status.reactions, {'HEART': 3});
    });

    test('an toàn khi body rỗng', () {
      final status = LikeStatusDto.fromJson(const {});
      expect(status.count, 0);
      expect(status.likedByMe, isFalse);
      expect(status.myReaction, isNull);
      expect(status.reactions, isEmpty);
    });

    test('kReactionEmoji có đủ 5 loại như web', () {
      expect(kReactionTypes, ['HEART', 'WOW', 'CLAP', 'THINKING', 'SAD']);
      for (final type in kReactionTypes) {
        expect(kReactionEmoji[type], isNotNull);
      }
    });
  });

  group('MessagingRealtimeEvent', () {
    test('parse sự kiện message.created', () {
      final event = MessagingRealtimeEvent.fromJson({
        'id': 'evt-1',
        'type': 'message.created',
        'payload': {'conversationId': 'c1', 'senderId': 'u2'},
      });
      expect(event.id, 'evt-1');
      expect(event.type, 'message.created');
      expect(event.payload['conversationId'], 'c1');
    });

    test('payload thiếu vẫn không lỗi', () {
      final event = MessagingRealtimeEvent.fromJson({'type': 'ping'});
      expect(event.type, 'ping');
      expect(event.payload, isEmpty);
      expect(event.id, isNull);
    });
  });
}
