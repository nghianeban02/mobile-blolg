import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/data/repositories/posts_repository.dart';

part 'post_detail_event.dart';
part 'post_detail_state.dart';

class PostDetailBloc extends Bloc<PostDetailEvent, PostDetailState> {
  PostDetailBloc({
    required this.postId,
    PostDto? initial,
    BeBlogPostsRepository? repository,
  }) : _repository = repository ?? BeBlogPostsRepository(),
       super(PostDetailState(post: initial)) {
    on<PostDetailLoadRequested>(_onLoad);
    on<PostDetailDeleteRequested>(_onDelete);
  }

  final String postId;
  final BeBlogPostsRepository _repository;

  Future<void> _onLoad(
    PostDetailLoadRequested event,
    Emitter<PostDetailState> emit,
  ) async {
    emit(state.copyWith(status: PostDetailStatus.loading, clearError: true));
    final result = await _repository.getOne(postId);
    if (!result.success || result.data == null) {
      emit(
        state.copyWith(
          status: PostDetailStatus.failure,
          errorMessage: result.message ?? 'Không tải được bài viết.',
        ),
      );
      return;
    }
    emit(
      state.copyWith(status: PostDetailStatus.success, post: result.data),
    );
  }

  Future<void> _onDelete(
    PostDetailDeleteRequested event,
    Emitter<PostDetailState> emit,
  ) async {
    emit(state.copyWith(status: PostDetailStatus.deleting));
    final result = await _repository.delete(postId);
    if (!result.success) {
      emit(
        state.copyWith(
          status: PostDetailStatus.failure,
          errorMessage: result.message ?? 'Không xóa được bài viết.',
        ),
      );
      return;
    }
    emit(state.copyWith(status: PostDetailStatus.deleted));
  }
}
