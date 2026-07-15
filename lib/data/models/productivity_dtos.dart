DateTime? _date(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

String _dateOnly(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

class NoteLabelInfoDto {
  final String id;
  final String name;
  final String color;

  const NoteLabelInfoDto({
    required this.id,
    required this.name,
    required this.color,
  });

  factory NoteLabelInfoDto.fromJson(Map<String, dynamic> json) =>
      NoteLabelInfoDto(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        color: json['color']?.toString() ?? 'default',
      );
}

class NoteDto {
  final String id;
  final String title;
  final String content;
  final String preview;
  final String contentFormat;
  final String color;
  final String? icon;
  final String? coverImageUrl;
  final String? folderId;
  final bool pinned;
  final bool archived;
  final bool trashed;
  final int wordCount;
  final int readingTimeSeconds;
  final int viewCount;
  final List<NoteLabelInfoDto> labels;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastEditedAt;

  const NoteDto({
    required this.id,
    this.title = '',
    this.content = '',
    this.preview = '',
    this.contentFormat = 'plain',
    this.color = 'default',
    this.icon,
    this.coverImageUrl,
    this.folderId,
    this.pinned = false,
    this.archived = false,
    this.trashed = false,
    this.wordCount = 0,
    this.readingTimeSeconds = 0,
    this.viewCount = 0,
    this.labels = const [],
    this.createdAt,
    this.updatedAt,
    this.lastEditedAt,
  });

  factory NoteDto.fromJson(Map<String, dynamic> json) {
    final labelData = json['labels'];
    return NoteDto(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      preview:
          json['preview']?.toString() ?? json['contentPlain']?.toString() ?? '',
      contentFormat: json['contentFormat']?.toString() ?? 'plain',
      color: json['color']?.toString() ?? 'default',
      icon: json['icon']?.toString(),
      coverImageUrl: json['coverImageUrl']?.toString(),
      folderId: json['folderId']?.toString(),
      pinned: json['pinned'] as bool? ?? false,
      archived: json['archived'] as bool? ?? false,
      trashed: json['trashed'] as bool? ?? false,
      wordCount: (json['wordCount'] as num?)?.toInt() ?? 0,
      readingTimeSeconds: (json['readingTimeSeconds'] as num?)?.toInt() ?? 0,
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      labels: labelData is List
          ? labelData
                .whereType<Map>()
                .map(
                  (e) =>
                      NoteLabelInfoDto.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
      createdAt: _date(json['createdAt']),
      updatedAt: _date(json['updatedAt']),
      lastEditedAt: _date(json['lastEditedAt']),
    );
  }
}

class NoteWriteRequest {
  final String title;
  final String content;
  final String contentFormat;
  final String color;
  final String? icon;
  final String? folderId;
  final bool pinned;
  final bool archived;
  final List<String> labelIds;

  const NoteWriteRequest({
    this.title = '',
    this.content = '',
    this.contentFormat = 'plain',
    this.color = 'default',
    this.icon,
    this.folderId,
    this.pinned = false,
    this.archived = false,
    this.labelIds = const [],
  });

  Map<String, dynamic> toJson() {
    final plain = content.trim();
    final words = plain.isEmpty
        ? 0
        : plain.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
    return {
      'title': title.trim(),
      'content': content,
      'contentPlain': plain,
      'contentFormat': contentFormat,
      'color': color,
      'icon': icon,
      'folderId': folderId,
      'pinned': pinned,
      'archived': archived,
      'labelIds': labelIds,
      'wordCount': words,
      'readingTimeSeconds': words == 0 ? 0 : ((words / 200) * 60).ceil(),
    };
  }
}

class NoteFolderDto {
  final String id;
  final String name;
  final String? icon;
  final String color;
  final String? parentId;
  final int sortOrder;

  const NoteFolderDto({
    required this.id,
    required this.name,
    this.icon,
    this.color = 'default',
    this.parentId,
    this.sortOrder = 0,
  });

  factory NoteFolderDto.fromJson(Map<String, dynamic> json) => NoteFolderDto(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    icon: json['icon']?.toString(),
    color: json['color']?.toString() ?? 'default',
    parentId: json['parentId']?.toString(),
    sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
  );
}

class NoteLabelDto {
  final String id;
  final String name;
  final String color;

  const NoteLabelDto({
    required this.id,
    required this.name,
    this.color = 'default',
  });

  factory NoteLabelDto.fromJson(Map<String, dynamic> json) => NoteLabelDto(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    color: json['color']?.toString() ?? 'default',
  );
}

class NoteStatsDto {
  final int active;
  final int archived;
  final int trashed;

  const NoteStatsDto({this.active = 0, this.archived = 0, this.trashed = 0});

  factory NoteStatsDto.fromJson(Map<String, dynamic> json) => NoteStatsDto(
    active: (json['active'] as num?)?.toInt() ?? 0,
    archived: (json['archived'] as num?)?.toInt() ?? 0,
    trashed: (json['trashed'] as num?)?.toInt() ?? 0,
  );
}

class CalendarEntryDto {
  final String id;
  final String userId;
  final DateTime eventDate;
  final String title;
  final String? note;
  final bool completed;
  final DateTime? completedAt;
  final int pomodoroMinutes;
  final int pomodoroCompleted;
  final int totalFocusSeconds;
  final DateTime? createdAt;

  const CalendarEntryDto({
    required this.id,
    required this.userId,
    required this.eventDate,
    required this.title,
    this.note,
    this.completed = false,
    this.completedAt,
    this.pomodoroMinutes = 25,
    this.pomodoroCompleted = 0,
    this.totalFocusSeconds = 0,
    this.createdAt,
  });

  factory CalendarEntryDto.fromJson(Map<String, dynamic> json) =>
      CalendarEntryDto(
        id: json['id']?.toString() ?? '',
        userId: json['userId']?.toString() ?? '',
        eventDate: _date(json['eventDate']) ?? DateTime.now(),
        title: json['title']?.toString() ?? '',
        note: json['note']?.toString(),
        completed: json['completed'] as bool? ?? false,
        completedAt: _date(json['completedAt']),
        pomodoroMinutes: (json['pomodoroMinutes'] as num?)?.toInt() ?? 25,
        pomodoroCompleted: (json['pomodoroCompleted'] as num?)?.toInt() ?? 0,
        totalFocusSeconds: (json['totalFocusSeconds'] as num?)?.toInt() ?? 0,
        createdAt: _date(json['createdAt']),
      );

  CalendarEntryDto copyWith({
    DateTime? eventDate,
    String? title,
    String? note,
    bool? completed,
    int? pomodoroMinutes,
    int? pomodoroCompleted,
    int? totalFocusSeconds,
  }) => CalendarEntryDto(
    id: id,
    userId: userId,
    eventDate: eventDate ?? this.eventDate,
    title: title ?? this.title,
    note: note ?? this.note,
    completed: completed ?? this.completed,
    completedAt: completed == null
        ? completedAt
        : (completed ? DateTime.now() : null),
    pomodoroMinutes: pomodoroMinutes ?? this.pomodoroMinutes,
    pomodoroCompleted: pomodoroCompleted ?? this.pomodoroCompleted,
    totalFocusSeconds: totalFocusSeconds ?? this.totalFocusSeconds,
    createdAt: createdAt,
  );

  Map<String, dynamic> toJson() => {
    'eventDate': _dateOnly(eventDate),
    'title': title.trim(),
    'note': note?.trim(),
    'completed': completed,
    'pomodoroMinutes': pomodoroMinutes,
    'pomodoroCompleted': pomodoroCompleted,
    'totalFocusSeconds': totalFocusSeconds,
  };
}
