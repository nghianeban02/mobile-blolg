part of 'comments_bloc.dart';

enum CommentsStatus { initial, loading, success, failure }

final class CommentsState extends Equatable {
  final CommentsStatus status;
  final List<CommentDto> comments;
  final bool submitting;
  final String? errorMessage;

  const CommentsState({
    this.status = CommentsStatus.initial,
    this.comments = const [],
    this.submitting = false,
    this.errorMessage,
  });

  CommentsState copyWith({
    CommentsStatus? status,
    List<CommentDto>? comments,
    bool? submitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CommentsState(
      status: status ?? this.status,
      comments: comments ?? this.comments,
      submitting: submitting ?? this.submitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, comments, submitting, errorMessage];
}
