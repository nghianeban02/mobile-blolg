import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/app/app.dart';
import 'package:mobile/core/router/app_router.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mobile/features/auth/screens/forgot_password_screen.dart';
import 'package:mobile/features/auth/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('App boots to login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MobileApp());
    await tester.pumpAndSettle();

    expect(find.text('Chào mừng trở lại'), findsOneWidget);
    expect(find.text('Nook'), findsWidgets);
  });

  testWidgets('Forgot password action opens recovery form', (
    WidgetTester tester,
  ) async {
    final authBloc = AuthBloc();
    addTearDown(authBloc.close);
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
        GoRoute(
          path: AppRoutes.forgotPassword,
          builder: (_, _) => const ForgotPasswordScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      BlocProvider.value(
        value: authBloc,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final forgot = find.text('Quên mật khẩu?');
    await tester.ensureVisible(forgot);
    await tester.pumpAndSettle();
    await tester.tap(forgot);
    await tester.pumpAndSettle();

    expect(find.text('Quên mật khẩu?'), findsWidgets);
    expect(find.textContaining('EMAIL'), findsWidgets);
  });
}
