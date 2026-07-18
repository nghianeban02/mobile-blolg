import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/brand/site_brand.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/navigation/main_shell.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mobile/features/auth/screens/forgot_password_screen.dart';
import 'package:mobile/features/auth/screens/login_screen.dart';
import 'package:mobile/features/auth/screens/register_screen.dart';
import 'package:mobile/features/auth/screens/reset_password_screen.dart';
import 'package:mobile/features/calendar/screens/calendar_screen.dart';
import 'package:mobile/features/developer/screens/api_demo_screen.dart';
import 'package:mobile/features/friends/screens/friends_screen.dart';
import 'package:mobile/features/messages/screens/conversations_screen.dart';
import 'package:mobile/features/notes/screens/notes_screen.dart';
import 'package:mobile/features/notifications/screens/notifications_screen.dart';
import 'package:mobile/features/posts/screens/post_detail_screen.dart';
import 'package:mobile/features/profile/screens/user_profile_screen.dart';
import 'package:mobile/features/review/screens/book_detail_screen.dart';
import 'package:mobile/features/saved/screens/saved_screen.dart';

/// Route paths dùng chung (đường dẫn GoRouter).
abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const home = '/home';
  static const search = '/search';
  static const library = '/library';
  static const me = '/me';
  static const messages = '/messages';
  static const notifications = '/notifications';
  static const friends = '/friends';
  static const saved = '/saved';
  static const notes = '/notes';
  static const calendar = '/calendar';
  static const apiDemo = '/api-demo';

  static String post(String id) => '/posts/$id';
  static String review(String id) => '/reviews/$id';
  static String user(String id) => '/users/$id';
}

/// Tạo [GoRouter] gắn với [AuthBloc]: redirect theo trạng thái phiên và
/// nhận deep link `nook://` + `https://nooknh.com` (reset-password, post,
/// review, profile).
GoRouter createAppRouter(AuthBloc authBloc) {
  const authPaths = {
    AppRoutes.login,
    AppRoutes.register,
    AppRoutes.forgotPassword,
    AppRoutes.resetPassword,
  };

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: _AuthStateListenable(authBloc),
    redirect: (context, state) {
      final uri = state.uri;

      // Deep link dạng `nook://reset-password?token=...` — host mang tên route.
      if (uri.host == 'reset-password') {
        final token = uri.queryParameters['token'];
        return Uri(
          path: AppRoutes.resetPassword,
          queryParameters: {'token': ?token},
        ).toString();
      }

      final status = authBloc.state.status;
      final path = uri.path;
      final onAuthRoute = authPaths.contains(path);

      if (status == AuthStatus.unknown) {
        // Đang khôi phục phiên — giữ ở splash, nhớ đích đến ban đầu.
        if (path == AppRoutes.splash) return null;
        return Uri(
          path: AppRoutes.splash,
          queryParameters: {'from': uri.toString()},
        ).toString();
      }

      if (status == AuthStatus.unauthenticated) {
        return onAuthRoute ? null : AppRoutes.login;
      }

      // Đã đăng nhập.
      if (path == AppRoutes.splash) {
        final from = uri.queryParameters['from'];
        if (from != null && !from.startsWith(AppRoutes.splash)) return from;
        return AppRoutes.home;
      }
      if (onAuthRoute && path != AppRoutes.resetPassword) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const _SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) => ResetPasswordScreen(
          initialToken: state.uri.queryParameters['token'],
        ),
      ),
      // Shell 4 tab — MainShell giữ IndexedStack nội bộ để bảo toàn state.
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const MainShell(),
      ),
      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) => const MainShell(initialIndex: 1),
      ),
      GoRoute(
        path: AppRoutes.library,
        builder: (context, state) => const MainShell(initialIndex: 2),
      ),
      GoRoute(
        path: AppRoutes.me,
        builder: (context, state) => const MainShell(initialIndex: 3),
      ),
      GoRoute(
        path: '/posts/:id',
        builder: (context, state) =>
            PostDetailScreen(postId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/reviews/:id',
        builder: (context, state) =>
            BookDetailScreen(reviewId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/users/:id',
        builder: (context, state) =>
            UserProfileScreen(userId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.messages,
        builder: (context, state) => const ConversationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.friends,
        builder: (context, state) => FriendsScreen(
          initialTab: int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: AppRoutes.saved,
        builder: (context, state) => const SavedScreen(),
      ),
      GoRoute(
        path: AppRoutes.notes,
        builder: (context, state) => const NotesScreen(),
      ),
      GoRoute(
        path: AppRoutes.calendar,
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        path: AppRoutes.apiDemo,
        builder: (context, state) => const ApiDemoScreen(),
      ),
    ],
  );
}

/// Chuyển stream của AuthBloc thành [Listenable] cho `refreshListenable`.
class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(AuthBloc bloc) {
    _subscription = bloc.stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.homeBackground,
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const NookMark(size: 72),
          const SizedBox(height: 16),
          const SiteBrand(variant: SiteBrandVariant.hero, showSlogan: true),
          const SizedBox(height: 28),
          const CircularProgressIndicator(color: AppColors.primaryBrown),
        ],
      ),
    ),
  );
}
