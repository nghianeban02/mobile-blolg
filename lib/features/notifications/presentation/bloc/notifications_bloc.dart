import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/data/repositories/notifications_repository.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

/// Badge unread toàn cục + danh sách thông báo.
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  NotificationsBloc({BeBlogNotificationsRepository? repository})
    : _repository = repository ?? BeBlogNotificationsRepository(),
      super(const NotificationsState()) {
    on<NotificationsUnreadRefreshRequested>(_onUnreadRefresh);
    on<NotificationsListRequested>(_onListRequested);
    on<NotificationsMarkReadRequested>(_onMarkRead);
    on<NotificationsMarkAllReadRequested>(_onMarkAllRead);
  }

  final BeBlogNotificationsRepository _repository;
  Timer? _pollTimer;

  void startPolling({Duration interval = const Duration(seconds: 60)}) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(interval, (_) {
      add(const NotificationsUnreadRefreshRequested());
    });
    add(const NotificationsUnreadRefreshRequested());
  }

  Future<void> _onUnreadRefresh(
    NotificationsUnreadRefreshRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    final result = await _repository.unreadCount();
    if (result.success) {
      emit(state.copyWith(unreadCount: result.data ?? 0));
    }
  }

  Future<void> _onListRequested(
    NotificationsListRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(status: NotificationsStatus.loading, clearError: true));
    final result = await _repository.list();
    if (!result.success) {
      emit(
        state.copyWith(
          status: NotificationsStatus.failure,
          errorMessage: result.message ?? 'Không tải được thông báo.',
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        status: NotificationsStatus.success,
        items: result.data ?? const [],
      ),
    );
    add(const NotificationsUnreadRefreshRequested());
  }

  Future<void> _onMarkRead(
    NotificationsMarkReadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    await _repository.markRead(event.id);
    final updated = state.items
        .map(
          (n) => n.id == event.id
              ? NotificationDto(
                  id: n.id,
                  type: n.type,
                  actor: n.actor,
                  reviewId: n.reviewId,
                  postId: n.postId,
                  commentId: n.commentId,
                  friendshipId: n.friendshipId,
                  message: n.message,
                  read: true,
                  createdAt: n.createdAt,
                )
              : n,
        )
        .toList();
    emit(state.copyWith(items: updated));
    add(const NotificationsUnreadRefreshRequested());
  }

  Future<void> _onMarkAllRead(
    NotificationsMarkAllReadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    await _repository.markAllRead();
    emit(
      state.copyWith(
        items: state.items
            .map(
              (n) => NotificationDto(
                id: n.id,
                type: n.type,
                actor: n.actor,
                reviewId: n.reviewId,
                postId: n.postId,
                commentId: n.commentId,
                friendshipId: n.friendshipId,
                message: n.message,
                read: true,
                createdAt: n.createdAt,
              ),
            )
            .toList(),
        unreadCount: 0,
      ),
    );
  }

  @override
  Future<void> close() async {
    _pollTimer?.cancel();
    return super.close();
  }
}
