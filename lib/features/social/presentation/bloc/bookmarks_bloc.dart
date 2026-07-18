import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/data/models/engagement_dtos.dart';
import 'package:mobile/data/repositories/engagement_repository.dart';

part 'bookmarks_event.dart';
part 'bookmarks_state.dart';

class BookmarksBloc extends Bloc<BookmarksEvent, BookmarksState> {
  BookmarksBloc({BeBlogEngagementRepository? repository})
    : _repository = repository ?? BeBlogEngagementRepository(),
      super(const BookmarksState()) {
    on<BookmarksLoadRequested>(_onLoad);
    on<BookmarksAddRequested>(_onAdd);
    on<BookmarksRemoveRequested>(_onRemove);
  }

  final BeBlogEngagementRepository _repository;

  Future<void> _onLoad(
    BookmarksLoadRequested event,
    Emitter<BookmarksState> emit,
  ) async {
    emit(state.copyWith(status: BookmarksStatus.loading, clearError: true));
    final result = await _repository.getBookmarks();
    if (!result.success) {
      emit(
        state.copyWith(
          status: BookmarksStatus.failure,
          errorMessage: result.message ?? 'Không tải được mục đã lưu.',
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        status: BookmarksStatus.success,
        items: result.data ?? const [],
      ),
    );
  }

  Future<void> _onAdd(
    BookmarksAddRequested event,
    Emitter<BookmarksState> emit,
  ) async {
    final result = await _repository.addBookmark(
      event.entityType,
      event.entityId,
    );
    if (result.success) add(const BookmarksLoadRequested());
  }

  Future<void> _onRemove(
    BookmarksRemoveRequested event,
    Emitter<BookmarksState> emit,
  ) async {
    final result = await _repository.removeBookmark(
      event.entityType,
      event.entityId,
    );
    if (result.success) add(const BookmarksLoadRequested());
  }
}
