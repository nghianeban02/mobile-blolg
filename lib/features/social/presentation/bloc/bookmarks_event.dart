part of 'bookmarks_bloc.dart';

sealed class BookmarksEvent extends Equatable {
  const BookmarksEvent();

  @override
  List<Object?> get props => const [];
}

final class BookmarksLoadRequested extends BookmarksEvent {
  const BookmarksLoadRequested();
}

final class BookmarksAddRequested extends BookmarksEvent {
  final BookmarkEntityType entityType;
  final String entityId;
  const BookmarksAddRequested({
    required this.entityType,
    required this.entityId,
  });

  @override
  List<Object?> get props => [entityType, entityId];
}

final class BookmarksRemoveRequested extends BookmarksEvent {
  final BookmarkEntityType entityType;
  final String entityId;
  const BookmarksRemoveRequested({
    required this.entityType,
    required this.entityId,
  });

  @override
  List<Object?> get props => [entityType, entityId];
}
