part of 'notifications_bloc.dart';

sealed class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => const [];
}

final class NotificationsUnreadRefreshRequested extends NotificationsEvent {
  const NotificationsUnreadRefreshRequested();
}

final class NotificationsListRequested extends NotificationsEvent {
  const NotificationsListRequested();
}

final class NotificationsMarkReadRequested extends NotificationsEvent {
  final String id;
  const NotificationsMarkReadRequested(this.id);

  @override
  List<Object?> get props => [id];
}

final class NotificationsMarkAllReadRequested extends NotificationsEvent {
  const NotificationsMarkAllReadRequested();
}
