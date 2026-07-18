import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/data/repositories/posts_repository.dart';

part 'create_post_event.dart';
part 'create_post_state.dart';

class CreatePostBloc extends Bloc<CreatePostEvent, CreatePostState> {
  CreatePostBloc({BeBlogPostsRepository? repository})
    : _repository = repository ?? BeBlogPostsRepository(),
      super(const CreatePostState()) {
    on<CreatePostSubmitted>(_onSubmitted);
  }

  final BeBlogPostsRepository _repository;

  Future<void> _onSubmitted(
    CreatePostSubmitted event,
    Emitter<CreatePostState> emit,
  ) async {
    emit(
      state.copyWith(
        status: CreatePostStatus.uploading,
        uploadProgress: 0,
        clearError: true,
      ),
    );
    final result = await _repository.createMultipart(
      title: event.title,
      content: event.content,
      titleImageFile: event.titleImageFile,
      galleryImageFiles: event.galleryImageFiles,
      onUploadProgress: (progress) {
        if (!emit.isDone) {
          emit(state.copyWith(uploadProgress: progress));
        }
      },
    );
    if (!result.success) {
      emit(
        state.copyWith(
          status: CreatePostStatus.failure,
          errorMessage: result.message ?? 'Không tạo được bài viết.',
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        status: CreatePostStatus.success,
        created: result.data,
        uploadProgress: 1,
      ),
    );
  }
}
