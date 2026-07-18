part of 'post_detail_bloc.dart';

sealed class PostDetailEvent extends Equatable {
  const PostDetailEvent();

  @override
  List<Object?> get props => const [];
}

final class PostDetailLoadRequested extends PostDetailEvent {
  const PostDetailLoadRequested();
}

final class PostDetailDeleteRequested extends PostDetailEvent {
  const PostDetailDeleteRequested();
}
