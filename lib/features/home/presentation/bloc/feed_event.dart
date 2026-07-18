part of 'feed_bloc.dart';

sealed class FeedEvent extends Equatable {
  const FeedEvent();

  @override
  List<Object?> get props => const [];
}

final class FeedLoadRequested extends FeedEvent {
  const FeedLoadRequested();
}

final class FeedRefreshRequested extends FeedEvent {
  const FeedRefreshRequested();
}

final class FeedLoadMoreRequested extends FeedEvent {
  const FeedLoadMoreRequested();
}
