import 'package:flutter/material.dart';
import 'package:mobile/app/routes.dart';
import 'package:mobile/core/navigation/main_shell.dart';
import 'package:mobile/core/preferences/display_preferences.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/screens/login_screen.dart';
import 'package:mobile/features/auth/screens/register_screen.dart';
import 'package:mobile/features/auth/screens/forgot_password_screen.dart';
import 'package:mobile/features/auth/screens/reset_password_screen.dart';
import 'package:mobile/features/auth/screens/startup_screen.dart';
import 'package:mobile/features/developer/screens/api_demo_screen.dart';

/// Root [MaterialApp]: theme and named routes.
class MobileApp extends StatefulWidget {
  const MobileApp({super.key});

  @override
  State<MobileApp> createState() => _MobileAppState();
}

class _MobileAppState extends State<MobileApp> {
  final _display = DisplayPreferences.instance;

  @override
  void initState() {
    super.initState();
    _display.addListener(_refresh);
    _display.load();
  }

  @override
  void dispose() {
    _display.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final platformRoute =
        WidgetsBinding.instance.platformDispatcher.defaultRouteName;
    return MaterialApp(
      title: 'Nook',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildLightTheme(),
      darkTheme: AppTheme.buildDarkTheme(),
      themeMode: _display.themeMode,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(_display.textScale),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      initialRoute: platformRoute == '/' ? AppRoutes.startup : platformRoute,
      routes: {
        AppRoutes.startup: (context) => const StartupScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.register: (context) => const RegisterScreen(),
        AppRoutes.forgotPassword: (context) => const ForgotPasswordScreen(),
        AppRoutes.resetPassword: (context) => const ResetPasswordScreen(),
        AppRoutes.home: (context) => const MainShell(),
        AppRoutes.apiDemo: (context) => const ApiDemoScreen(),
      },
      onGenerateRoute: (settings) {
        final uri = Uri.tryParse(settings.name ?? '');
        if (uri?.path == AppRoutes.resetPassword ||
            uri?.host == 'reset-password') {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => ResetPasswordScreen(
              initialToken: uri?.queryParameters['token'],
            ),
          );
        }
        return null;
      },
    );
  }
}
