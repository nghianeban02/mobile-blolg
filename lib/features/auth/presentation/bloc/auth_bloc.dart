import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/auth/session_events.dart';
import 'package:mobile/data/auth/auth_repository.dart';
import 'package:mobile/data/auth/login_request.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/data/repositories/users_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Quản lý vòng đời phiên đăng nhập toàn app.
///
/// be-blog phát JWT đơn hạn 24h, không có refresh token — nên khi nhận 401
/// ([SessionEvents]) chỉ có thể dọn phiên và yêu cầu đăng nhập lại.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    AuthRepository? authRepository,
    BeBlogUsersRepository? usersRepository,
    SessionEvents? sessionEvents,
  }) : _auth = authRepository ?? AuthRepository(),
       _users = usersRepository ?? BeBlogUsersRepository(),
       super(const AuthState()) {
    on<AuthAppStarted>(_onAppStarted);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthGuestRequested>(_onGuestRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthSessionExpired>(_onSessionExpired);
    on<AuthProfileRefreshRequested>(_onProfileRefreshRequested);

    _sessionSubscription = (sessionEvents ?? SessionEvents.instance)
        .onSessionExpired
        .listen((_) => add(const AuthSessionExpired()));
  }

  final AuthRepository _auth;
  final BeBlogUsersRepository _users;
  late final StreamSubscription<void> _sessionSubscription;

  @override
  Future<void> close() async {
    await _sessionSubscription.cancel();
    return super.close();
  }

  Future<void> _onAppStarted(
    AuthAppStarted event,
    Emitter<AuthState> emit,
  ) async {
    final token = await _auth.getToken();
    if (token == null || token.isEmpty) {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
      return;
    }
    try {
      final me = await _users.me(forceRefresh: true);
      if (me.success && me.data != null) {
        emit(
          state.copyWith(status: AuthStatus.authenticated, profile: me.data),
        );
        return;
      }
      if (me.statusCode == 401 || me.statusCode == 403) {
        await _auth.clearLocalSession();
      }
      emit(
        state.copyWith(status: AuthStatus.unauthenticated, clearProfile: true),
      );
    } on Exception {
      // Mất mạng khi mở app: token còn — cho vào app, API sẽ retry sau.
      emit(state.copyWith(status: AuthStatus.authenticated));
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        submitting: true,
        clearLoginError: true,
        sessionExpired: false,
      ),
    );
    final response = await _auth.login(
      LoginRequest(email: event.email, password: event.password),
    );
    if (!response.success) {
      emit(
        state.copyWith(
          submitting: false,
          loginError: response.message ?? 'Đăng nhập thất bại',
        ),
      );
      return;
    }
    final me = await _users.me(forceRefresh: true);
    emit(
      state.copyWith(
        submitting: false,
        status: AuthStatus.authenticated,
        profile: me.data,
      ),
    );
  }

  Future<void> _onGuestRequested(
    AuthGuestRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        submitting: true,
        clearLoginError: true,
        sessionExpired: false,
      ),
    );
    final response = await _auth.loginAsGuest();
    if (!response.success) {
      emit(
        state.copyWith(
          submitting: false,
          loginError: response.message ?? 'Không thể mở chế độ khách.',
        ),
      );
      return;
    }
    final me = await _users.me(forceRefresh: true);
    emit(
      state.copyWith(
        submitting: false,
        status: AuthStatus.authenticated,
        profile: me.data,
      ),
    );
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _auth.logout();
    emit(
      const AuthState(status: AuthStatus.unauthenticated),
    );
  }

  Future<void> _onSessionExpired(
    AuthSessionExpired event,
    Emitter<AuthState> emit,
  ) async {
    if (state.status != AuthStatus.authenticated) return;
    await _auth.clearLocalSession();
    emit(
      const AuthState(status: AuthStatus.unauthenticated, sessionExpired: true),
    );
  }

  Future<void> _onProfileRefreshRequested(
    AuthProfileRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state.status != AuthStatus.authenticated) return;
    final me = await _users.me(forceRefresh: true);
    if (me.success && me.data != null) {
      emit(state.copyWith(profile: me.data));
    }
  }
}
