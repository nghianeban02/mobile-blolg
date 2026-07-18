part of 'search_bloc.dart';

sealed class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => const [];
}

final class SearchQueryChanged extends SearchEvent {
  final String query;
  const SearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

final class SearchSubmitted extends SearchEvent {
  const SearchSubmitted();
}

final class SearchFilterChanged extends SearchEvent {
  final ArchiveSearchFilter filter;
  const SearchFilterChanged(this.filter);

  @override
  List<Object?> get props => [filter];
}

final class SearchLoadMoreRequested extends SearchEvent {
  const SearchLoadMoreRequested();
}
