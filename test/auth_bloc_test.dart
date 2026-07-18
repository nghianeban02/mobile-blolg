import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/auth/session_events.dart';
import 'package:mobile/core/network/be_blog_http.dart';
import 'package:mobile/data/auth/auth_repository.dart';
import 'package:mobile/data/auth/login_request.dart';
import 'package:mobile/data/auth/login_response.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/data/repositories/users_repository.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockUsersRepository extends Mock implements BeBlogUsersRepository {}

void main() {
  late _MockAuthRepository auth;
  late _MockUsersRepository users;
  late SessionEvents sessions;

  setUpAll(() {
    registerFallbackValue(LoginRequest(email: '', password: ''));
  });

  setUp(() {
    auth = _MockAuthRepository();
    users = _MockUsersRepository();
    sessions = SessionEvents.instance;
  });

  AuthBloc buildBloc() => AuthBloc(
    authRepository: auth,
    usersRepository: users,
    sessionEvents: sessions,
  );

  group('AuthBloc', () {
    blocTest<AuthBloc, AuthState>(
      'AppStarted without token → unauthenticated',
      build: () {
        when(() => auth.getToken()).thenAnswer((_) async => null);
        return buildBloc();
      },
      act: (bloc) => bloc.add(const AuthAppStarted()),
      expect: () => [
        isA<AuthState>().having(
          (s) => s.status,
          'status',
          AuthStatus.unauthenticated,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'login success → authenticated',
      build: () {
        when(() => auth.login(any())).thenAnswer(
          (_) async => const LoginResponse(success: true, token: 't'),
        );
        when(() => users.me(forceRefresh: true)).thenAnswer(
          (_) async => BeBlogRepoResult.ok(
            const UserProfileDto(id: 'u1', username: 'reader'),
          ),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const AuthLoginRequested(email: 'a@b.c', password: 'secret12'),
      ),
      expect: () => [
        isA<AuthState>().having((s) => s.submitting, 'submitting', true),
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthStatus.authenticated)
            .having((s) => s.profile?.id, 'profile', 'u1')
            .having((s) => s.submitting, 'submitting', false),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'login failure keeps unauthenticated with error',
      build: () {
        when(() => auth.login(any())).thenAnswer(
          (_) async =>
              const LoginResponse(success: false, message: 'Sai mật khẩu'),
        );
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const AuthLoginRequested(email: 'a@b.c', password: 'bad')),
      expect: () => [
        isA<AuthState>().having((s) => s.submitting, 'submitting', true),
        isA<AuthState>()
            .having((s) => s.submitting, 'submitting', false)
            .having((s) => s.loginError, 'error', 'Sai mật khẩu'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'session expired clears authenticated session',
      build: () {
        when(() => auth.clearLocalSession()).thenAnswer((_) async {});
        return buildBloc();
      },
      seed: () => const AuthState(
        status: AuthStatus.authenticated,
        profile: UserProfileDto(id: 'u1', username: 'reader'),
      ),
      act: (bloc) => bloc.add(const AuthSessionExpired()),
      expect: () => [
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthStatus.unauthenticated)
            .having((s) => s.sessionExpired, 'expired', true),
      ],
    );
  });
}
