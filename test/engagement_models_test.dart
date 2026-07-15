import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/models/engagement_dtos.dart';

void main() {
  test('bookmark parser preserves entity routing data', () {
    final item = BookmarkItemDto.fromJson({
      'bookmarkId': 'b-1',
      'entityType': 'REVIEW',
      'entityId': 'r-1',
      'title': 'Review title',
      'excerpt': 'Excerpt',
      'savedAt': '2026-07-15T01:02:03Z',
    });

    expect(item.entityType, BookmarkEntityType.review);
    expect(item.entityType.apiValue, 'REVIEW');
    expect(item.entityId, 'r-1');
    expect(item.savedAt, DateTime.utc(2026, 7, 15, 1, 2, 3));
  });

  test('streak parser handles seven-day activity', () {
    final streak = StreakSnapshotDto.fromJson({
      'currentStreak': 4,
      'longestStreak': 11,
      'activeToday': true,
      'last7Days': [
        {'date': '2026-07-14', 'active': false},
        {'date': '2026-07-15', 'active': true},
      ],
    });

    expect(streak.currentStreak, 4);
    expect(streak.longestStreak, 11);
    expect(streak.activeToday, isTrue);
    expect(streak.last7Days.map((day) => day.active), [false, true]);
  });
}
