import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/app.dart';
import 'package:mobile/app/routes.dart';
import 'package:mobile/features/auth/screens/forgot_password_screen.dart';
import 'package:mobile/features/auth/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App boots to login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MobileApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
  });

  testWidgets('Forgot password action opens recovery form', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const LoginScreen(),
        routes: {AppRoutes.forgotPassword: (_) => const ForgotPasswordScreen()},
      ),
    );
    await tester.pumpAndSettle();

    final forgot = find.text('FORGOT?');
    await tester.ensureVisible(forgot);
    await tester.pumpAndSettle();
    await tester.tap(forgot);
    await tester.pumpAndSettle();

    expect(find.text('Quên mật khẩu?'), findsOneWidget);
    expect(find.text('GỬI EMAIL ĐẶT LẠI'), findsOneWidget);
  });
}
