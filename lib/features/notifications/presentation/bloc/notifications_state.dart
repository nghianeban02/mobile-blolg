part of 'notifications_bloc.dart';

enum NotificationsStatus { initial, loading, success, failure }

final class NotificationsState extends Equatable {
  final NotificationsStatus status;
  final List<NotificationDto> items;
  final int unreadCount;
  final String? errorMessage;

  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.items = const [],
    this.unreadCount = 0,
    this.errorMessage,
  });

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<NotificationDto>? items,
    int? unreadCount,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, items, unreadCount, errorMessage];
}
