DateTime? _parseDate(dynamic value) =>
    value == null ? null : DateTime.tryParse(value.toString());

enum BookmarkEntityType { post, review }

extension BookmarkEntityTypeApi on BookmarkEntityType {
  String get apiValue => name.toUpperCase();
}

BookmarkEntityType bookmarkEntityTypeFromApi(String? value) =>
    value?.toUpperCase() == 'REVIEW'
    ? BookmarkEntityType.review
    : BookmarkEntityType.post;

class BookmarkItemDto {
  final String bookmarkId;
  final BookmarkEntityType entityType;
  final String entityId;
  final String title;
  final String excerpt;
  final DateTime? savedAt;

  const BookmarkItemDto({
    required this.bookmarkId,
    required this.entityType,
    required this.entityId,
    required this.title,
    this.excerpt = '',
    this.savedAt,
  });

  factory BookmarkItemDto.fromJson(Map<String, dynamic> json) =>
      BookmarkItemDto(
        bookmarkId: json['bookmarkId']?.toString() ?? '',
        entityType: bookmarkEntityTypeFromApi(json['entityType']?.toString()),
        entityId: json['entityId']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        excerpt: json['excerpt']?.toString() ?? '',
        savedAt: _parseDate(json['savedAt']),
      );
}

class StreakDayDto {
  final DateTime date;
  final bool active;

  const StreakDayDto({required this.date, required this.active});

  factory StreakDayDto.fromJson(Map<String, dynamic> json) => StreakDayDto(
    date: _parseDate(json['date']) ?? DateTime.now(),
    active: json['active'] as bool? ?? false,
  );
}

class StreakSnapshotDto {
  final int currentStreak;
  final int longestStreak;
  final bool activeToday;
  final List<StreakDayDto> last7Days;

  const StreakSnapshotDto({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.activeToday = false,
    this.last7Days = const [],
  });

  factory StreakSnapshotDto.fromJson(Map<String, dynamic> json) {
    final days = json['last7Days'];
    return StreakSnapshotDto(
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
      activeToday: json['activeToday'] as bool? ?? false,
      last7Days: days is List
          ? days
                .whereType<Map>()
                .map((e) => StreakDayDto.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
    );
  }
}
