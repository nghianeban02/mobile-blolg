part of 'post_detail_bloc.dart';

enum PostDetailStatus { initial, loading, success, deleting, deleted, failure }

final class PostDetailState extends Equatable {
  final PostDetailStatus status;
  final PostDto? post;
  final String? errorMessage;

  const PostDetailState({
    this.status = PostDetailStatus.initial,
    this.post,
    this.errorMessage,
  });

  PostDetailState copyWith({
    PostDetailStatus? status,
    PostDto? post,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PostDetailState(
      status: status ?? this.status,
      post: post ?? this.post,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, post?.id, errorMessage];
}
