import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/data/repositories/likes_repository.dart';

part 'likes_event.dart';
part 'likes_state.dart';

enum LikeTarget { post, review }

/// Cảm xúc (HEART/WOW/…) dùng chung cho post + review.
class LikesBloc extends Bloc<LikesEvent, LikesState> {
  LikesBloc({
    required this.target,
    required this.targetId,
    BeBlogLikesRepository? repository,
  }) : _repository = repository ?? BeBlogLikesRepository(),
       super(const LikesState()) {
    on<LikesLoadRequested>(_onLoad);
    on<LikesReactRequested>(_onReact);
    on<LikesUnlikeRequested>(_onUnlike);
  }

  final LikeTarget target;
  final String targetId;
  final BeBlogLikesRepository _repository;

  Future<void> _onLoad(LikesLoadRequested event, Emitter<LikesState> emit) async {
    emit(state.copyWith(status: LikesStatus.loading));
    final result = target == LikeTarget.post
        ? await _repository.statusPost(targetId)
        : await _repository.status(targetId);
    if (!result.success) {
      emit(
        state.copyWith(
          status: LikesStatus.failure,
          errorMessage: result.message,
        ),
      );
      return;
    }
    emit(
      state.copyWith(status: LikesStatus.success, likeStatus: result.data),
    );
  }

  Future<void> _onReact(
    LikesReactRequested event,
    Emitter<LikesState> emit,
  ) async {
    final result = target == LikeTarget.post
        ? await _repository.likePost(targetId, type: event.type)
        : await _repository.like(targetId, type: event.type);
    if (result.success) {
      emit(state.copyWith(likeStatus: result.data, status: LikesStatus.success));
    }
  }

  Future<void> _onUnlike(
    LikesUnlikeRequested event,
    Emitter<LikesState> emit,
  ) async {
    final result = target == LikeTarget.post
        ? await _repository.unlikePost(targetId)
        : await _repository.unlike(targetId);
    if (result.success) {
      emit(state.copyWith(likeStatus: result.data, status: LikesStatus.success));
    }
  }
}
