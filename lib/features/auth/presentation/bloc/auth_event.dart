part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => const [];
}

/// App khởi động: khôi phục token và xác thực với `/api/users/me`.
final class AuthAppStarted extends AuthEvent {
  const AuthAppStarted();
}

final class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

final class AuthGuestRequested extends AuthEvent {
  const AuthGuestRequested();
}

final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Nhận từ [SessionEvents] khi API trả 401 (JWT 24h hết hạn, không có refresh).
final class AuthSessionExpired extends AuthEvent {
  const AuthSessionExpired();
}

/// Đồng bộ lại profile sau khi người dùng cập nhật hồ sơ.
final class AuthProfileRefreshRequested extends AuthEvent {
  const AuthProfileRefreshRequested();
}
