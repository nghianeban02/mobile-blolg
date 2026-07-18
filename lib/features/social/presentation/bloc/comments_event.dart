part of 'comments_bloc.dart';

sealed class CommentsEvent extends Equatable {
  const CommentsEvent();

  @override
  List<Object?> get props => const [];
}

final class CommentsLoadRequested extends CommentsEvent {
  const CommentsLoadRequested();
}

final class CommentsCreateRequested extends CommentsEvent {
  final String content;
  final String? parentId;
  const CommentsCreateRequested({required this.content, this.parentId});

  @override
  List<Object?> get props => [content, parentId];
}

final class CommentsReplyRequested extends CommentsEvent {
  final String commentId;
  final String content;
  const CommentsReplyRequested({
    required this.commentId,
    required this.content,
  });

  @override
  List<Object?> get props => [commentId, content];
}

final class CommentsUpdateRequested extends CommentsEvent {
  final String commentId;
  final String content;
  const CommentsUpdateRequested({
    required this.commentId,
    required this.content,
  });

  @override
  List<Object?> get props => [commentId, content];
}

final class CommentsDeleteRequested extends CommentsEvent {
  final String commentId;
  const CommentsDeleteRequested(this.commentId);

  @override
  List<Object?> get props => [commentId];
}
