part of 'auth_bloc.dart';

enum AuthStatus {
  /// Đang khôi phục phiên khi mở app.
  unknown,

  /// Có JWT hợp lệ và profile.
  authenticated,

  /// Chưa đăng nhập (hoặc phiên đã hết hạn).
  unauthenticated,
}

final class AuthState extends Equatable {
  final AuthStatus status;
  final UserProfileDto? profile;

  /// Lỗi của lần đăng nhập gần nhất (hiển thị trên form).
  final String? loginError;

  /// Đang chờ login/guest request.
  final bool submitting;

  /// Phiên vừa hết hạn — UI hiển thị thông báo yêu cầu đăng nhập lại.
  final bool sessionExpired;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.profile,
    this.loginError,
    this.submitting = false,
    this.sessionExpired = false,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    UserProfileDto? profile,
    String? loginError,
    bool? submitting,
    bool? sessionExpired,
    bool clearProfile = false,
    bool clearLoginError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      profile: clearProfile ? null : (profile ?? this.profile),
      loginError: clearLoginError ? null : (loginError ?? this.loginError),
      submitting: submitting ?? this.submitting,
      sessionExpired: sessionExpired ?? this.sessionExpired,
    );
  }

  @override
  List<Object?> get props => [
    status,
    profile?.id,
    loginError,
    submitting,
    sessionExpired,
  ];
}
