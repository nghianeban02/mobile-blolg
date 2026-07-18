import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/models/dtos.dart';

void main() {
  test(
    'PushPreferencesDto parse payload từ be-blog, thiếu field mặc định bật',
    () {
      final parsed = PushPreferencesDto.fromJson({
        'messages': false,
        'calls': true,
        'likes': false,
        // friends/comments/system vắng mặt — service cũ hoặc bản ghi mới.
      });

      expect(parsed.messages, isFalse);
      expect(parsed.calls, isTrue);
      expect(parsed.likes, isFalse);
      expect(parsed.friends, isTrue);
      expect(parsed.comments, isTrue);
      expect(parsed.system, isTrue);
    },
  );

  test(
    'toJson tròn vòng đủ 6 loại — khớp contract PUT /api/notifications/preferences',
    () {
      const preferences = PushPreferencesDto(
        messages: true,
        calls: false,
        friends: true,
        comments: false,
        likes: true,
        system: false,
      );

      final json = preferences.toJson();
      expect(
        json.keys,
        containsAll([
          'messages',
          'calls',
          'friends',
          'comments',
          'likes',
          'system',
        ]),
      );
      final roundTrip = PushPreferencesDto.fromJson(json);
      expect(roundTrip.calls, isFalse);
      expect(roundTrip.comments, isFalse);
      expect(roundTrip.system, isFalse);
      expect(roundTrip.messages, isTrue);
    },
  );

  test('copyWith chỉ đổi field được chỉ định', () {
    const base = PushPreferencesDto.defaults;
    final next = base.copyWith(likes: false);
    expect(next.likes, isFalse);
    expect(next.messages, isTrue);
    expect(base.likes, isTrue, reason: 'immutable — bản gốc không đổi');
  });
}
