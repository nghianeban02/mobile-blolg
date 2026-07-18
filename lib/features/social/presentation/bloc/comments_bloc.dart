import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/data/repositories/comments_repository.dart';

part 'comments_event.dart';
part 'comments_state.dart';

enum CommentTarget { review, post }

/// Threaded comments cho review (và post nếu repo hỗ trợ).
class CommentsBloc extends Bloc<CommentsEvent, CommentsState> {
  CommentsBloc({
    required this.target,
    required this.targetId,
    BeBlogCommentsRepository? repository,
  }) : _repository = repository ?? BeBlogCommentsRepository(),
       super(const CommentsState()) {
    on<CommentsLoadRequested>(_onLoad);
    on<CommentsCreateRequested>(_onCreate);
    on<CommentsReplyRequested>(_onReply);
    on<CommentsUpdateRequested>(_onUpdate);
    on<CommentsDeleteRequested>(_onDelete);
  }

  final CommentTarget target;
  final String targetId;
  final BeBlogCommentsRepository _repository;

  Future<void> _onLoad(
    CommentsLoadRequested event,
    Emitter<CommentsState> emit,
  ) async {
    emit(state.copyWith(status: CommentsStatus.loading, clearError: true));
    // Hiện repo chỉ có list theo review — post dùng cùng shape nếu backend mở rộng.
    final result = await _repository.listByReview(targetId);
    if (!result.success) {
      emit(
        state.copyWith(
          status: CommentsStatus.failure,
          errorMessage: result.message ?? 'Không tải được bình luận.',
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        status: CommentsStatus.success,
        comments: result.data ?? const [],
      ),
    );
  }

  Future<void> _onCreate(
    CommentsCreateRequested event,
    Emitter<CommentsState> emit,
  ) async {
    emit(state.copyWith(submitting: true, clearError: true));
    final result = await _repository.create(
      reviewId: targetId,
      content: event.content,
      parentId: event.parentId,
    );
    emit(state.copyWith(submitting: false));
    if (result.success) {
      add(const CommentsLoadRequested());
    } else {
      emit(
        state.copyWith(
          errorMessage: result.message ?? 'Không gửi được bình luận.',
        ),
      );
    }
  }

  Future<void> _onReply(
    CommentsReplyRequested event,
    Emitter<CommentsState> emit,
  ) async {
    emit(state.copyWith(submitting: true, clearError: true));
    final result = await _repository.reply(
      reviewId: targetId,
      commentId: event.commentId,
      content: event.content,
    );
    emit(state.copyWith(submitting: false));
    if (result.success) {
      add(const CommentsLoadRequested());
    } else {
      emit(
        state.copyWith(
          errorMessage: result.message ?? 'Không gửi được trả lời.',
        ),
      );
    }
  }

  Future<void> _onUpdate(
    CommentsUpdateRequested event,
    Emitter<CommentsState> emit,
  ) async {
    final result = await _repository.update(
      reviewId: targetId,
      commentId: event.commentId,
      content: event.content,
    );
    if (result.success) {
      add(const CommentsLoadRequested());
    } else {
      emit(
        state.copyWith(
          errorMessage: result.message ?? 'Không sửa được bình luận.',
        ),
      );
    }
  }

  Future<void> _onDelete(
    CommentsDeleteRequested event,
    Emitter<CommentsState> emit,
  ) async {
    final result = await _repository.delete(
      reviewId: targetId,
      commentId: event.commentId,
    );
    if (result.success) {
      add(const CommentsLoadRequested());
    } else {
      emit(
        state.copyWith(
          errorMessage: result.message ?? 'Không xóa được bình luận.',
        ),
      );
    }
  }
}
