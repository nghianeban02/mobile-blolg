import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/models/productivity_dtos.dart';

void main() {
  group('Note DTOs', () {
    test('parses summary payload and labels safely', () {
      final note = NoteDto.fromJson({
        'id': 'n-1',
        'title': 'Ideas',
        'preview': 'A short preview',
        'contentFormat': 'rich',
        'color': 'blue',
        'pinned': true,
        'wordCount': 12,
        'labels': [
          {'id': 'l-1', 'name': 'Work', 'color': 'red'},
        ],
        'lastEditedAt': '2026-07-15T10:30:00Z',
      });

      expect(note.id, 'n-1');
      expect(note.preview, 'A short preview');
      expect(note.pinned, isTrue);
      expect(note.labels.single.name, 'Work');
      expect(note.lastEditedAt, DateTime.utc(2026, 7, 15, 10, 30));
    });

    test('write request computes searchable plain text statistics', () {
      const request = NoteWriteRequest(
        title: '  Draft  ',
        content: 'one two\nthree',
        folderId: 'folder-1',
        labelIds: ['label-1'],
      );
      final json = request.toJson();

      expect(json['title'], 'Draft');
      expect(json['contentPlain'], 'one two\nthree');
      expect(json['wordCount'], 3);
      expect(json['readingTimeSeconds'], 1);
      expect(json['folderId'], 'folder-1');
    });
  });

  group('Calendar DTO', () {
    test('serializes date-only contract and focus progress', () {
      final entry =
          CalendarEntryDto(
            id: 'c-1',
            userId: 'u-1',
            eventDate: DateTime(2026, 7, 15, 22, 10),
            title: ' Focus ',
            pomodoroMinutes: 25,
          ).copyWith(
            completed: true,
            pomodoroCompleted: 2,
            totalFocusSeconds: 3000,
          );
      final json = entry.toJson();

      expect(json['eventDate'], '2026-07-15');
      expect(json['title'], 'Focus');
      expect(json['completed'], isTrue);
      expect(json['pomodoroCompleted'], 2);
      expect(json['totalFocusSeconds'], 3000);
      expect(entry.completedAt, isNotNull);
    });

    test('uses safe defaults for optional backend fields', () {
      final entry = CalendarEntryDto.fromJson({
        'id': 'c-2',
        'userId': 'u-2',
        'eventDate': '2026-07-01',
        'title': 'Read',
      });

      expect(entry.completed, isFalse);
      expect(entry.pomodoroMinutes, 25);
      expect(entry.pomodoroCompleted, 0);
      expect(entry.totalFocusSeconds, 0);
    });
  });
}
