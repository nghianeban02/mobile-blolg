part of 'create_post_bloc.dart';

enum CreatePostStatus { initial, uploading, success, failure }

final class CreatePostState extends Equatable {
  final CreatePostStatus status;
  final double uploadProgress;
  final PostDto? created;
  final String? errorMessage;

  const CreatePostState({
    this.status = CreatePostStatus.initial,
    this.uploadProgress = 0,
    this.created,
    this.errorMessage,
  });

  bool get isSubmitting => status == CreatePostStatus.uploading;

  CreatePostState copyWith({
    CreatePostStatus? status,
    double? uploadProgress,
    PostDto? created,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CreatePostState(
      status: status ?? this.status,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      created: created ?? this.created,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, uploadProgress, created?.id, errorMessage];
}
