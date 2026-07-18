import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/search/archive_search_index.dart';
import 'package:mobile/data/repositories/search_repository.dart';

part 'search_event.dart';
part 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc({BeBlogSearchRepository? repository})
    : _repository = repository ?? BeBlogSearchRepository(),
      super(const SearchState()) {
    on<SearchQueryChanged>(_onQueryChanged);
    on<SearchSubmitted>(_onSubmitted);
    on<SearchFilterChanged>(_onFilterChanged);
    on<SearchLoadMoreRequested>(_onLoadMore);
  }

  final BeBlogSearchRepository _repository;
  static const int _pageSize = 20;

  Future<void> _onQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    emit(state.copyWith(query: event.query));
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (event.query != state.query) return;
    if (event.query.trim().isEmpty) {
      emit(
        state.copyWith(
          status: SearchStatus.initial,
          hits: const [],
          page: 0,
          hasMore: false,
          clearError: true,
        ),
      );
      return;
    }
    add(const SearchSubmitted());
  }

  Future<void> _onSubmitted(
    SearchSubmitted event,
    Emitter<SearchState> emit,
  ) async {
    final q = state.query.trim();
    if (q.isEmpty) return;
    emit(
      state.copyWith(status: SearchStatus.loading, page: 0, clearError: true),
    );
    await _fetch(emit, page: 0, append: false);
  }

  Future<void> _onFilterChanged(
    SearchFilterChanged event,
    Emitter<SearchState> emit,
  ) async {
    emit(state.copyWith(filter: event.filter));
    if (state.query.trim().isNotEmpty) {
      emit(
        state.copyWith(status: SearchStatus.loading, page: 0, clearError: true),
      );
      await _fetch(emit, page: 0, append: false);
    }
  }

  Future<void> _onLoadMore(
    SearchLoadMoreRequested event,
    Emitter<SearchState> emit,
  ) async {
    if (!state.hasMore || state.status == SearchStatus.loadingMore) return;
    emit(state.copyWith(status: SearchStatus.loadingMore));
    await _fetch(emit, page: state.page + 1, append: true);
  }

  Future<void> _fetch(
    Emitter<SearchState> emit, {
    required int page,
    required bool append,
  }) async {
    final result = await _repository.search(
      state.query.trim(),
      filter: state.filter,
      page: page,
      size: _pageSize,
    );
    if (!result.success) {
      emit(
        state.copyWith(
          status: SearchStatus.failure,
          errorMessage: result.message ?? 'Không tìm được kết quả.',
        ),
      );
      return;
    }
    final pageHits = result.data?.hits ?? const <ArchiveSearchHit>[];
    final hits = append ? [...state.hits, ...pageHits] : pageHits;
    emit(
      state.copyWith(
        status: SearchStatus.success,
        hits: hits,
        page: page,
        hasMore: pageHits.length >= _pageSize,
        clearError: true,
      ),
    );
  }
}
