part of 'search_bloc.dart';

enum SearchStatus { initial, loading, loadingMore, success, failure }

final class SearchState extends Equatable {
  final SearchStatus status;
  final String query;
  final ArchiveSearchFilter filter;
  final List<ArchiveSearchHit> hits;
  final int page;
  final bool hasMore;
  final String? errorMessage;

  const SearchState({
    this.status = SearchStatus.initial,
    this.query = '',
    this.filter = ArchiveSearchFilter.all,
    this.hits = const [],
    this.page = 0,
    this.hasMore = false,
    this.errorMessage,
  });

  SearchState copyWith({
    SearchStatus? status,
    String? query,
    ArchiveSearchFilter? filter,
    List<ArchiveSearchHit>? hits,
    int? page,
    bool? hasMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SearchState(
      status: status ?? this.status,
      query: query ?? this.query,
      filter: filter ?? this.filter,
      hits: hits ?? this.hits,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props =>
      [status, query, filter, hits, page, hasMore, errorMessage];
}
