part of 'likes_bloc.dart';

enum LikesStatus { initial, loading, success, failure }

final class LikesState extends Equatable {
  final LikesStatus status;
  final LikeStatusDto? likeStatus;
  final String? errorMessage;

  const LikesState({
    this.status = LikesStatus.initial,
    this.likeStatus,
    this.errorMessage,
  });

  LikesState copyWith({
    LikesStatus? status,
    LikeStatusDto? likeStatus,
    String? errorMessage,
  }) {
    return LikesState(
      status: status ?? this.status,
      likeStatus: likeStatus ?? this.likeStatus,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, likeStatus, errorMessage];
}
