part of 'bookmarks_bloc.dart';

enum BookmarksStatus { initial, loading, success, failure }

final class BookmarksState extends Equatable {
  final BookmarksStatus status;
  final List<BookmarkItemDto> items;
  final String? errorMessage;

  const BookmarksState({
    this.status = BookmarksStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  BookmarksState copyWith({
    BookmarksStatus? status,
    List<BookmarkItemDto>? items,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BookmarksState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, items, errorMessage];
}
