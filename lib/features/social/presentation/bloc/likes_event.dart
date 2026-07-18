part of 'likes_bloc.dart';

sealed class LikesEvent extends Equatable {
  const LikesEvent();

  @override
  List<Object?> get props => const [];
}

final class LikesLoadRequested extends LikesEvent {
  const LikesLoadRequested();
}

final class LikesReactRequested extends LikesEvent {
  final String type;
  const LikesReactRequested(this.type);

  @override
  List<Object?> get props => [type];
}

final class LikesUnlikeRequested extends LikesEvent {
  const LikesUnlikeRequested();
}
