import 'package:flutter/material.dart';
import 'package:mobile/app/routes.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/data/auth/auth_repository.dart';
import 'package:mobile/data/repositories/users_repository.dart';

/// Restores a saved JWT and validates it before opening the authenticated shell.
class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  final _auth = AuthRepository();
  final _users = BeBlogUsersRepository();

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final token = await _auth.getToken();
    if (!mounted) return;
    if (token == null || token.isEmpty) {
      _open(AppRoutes.login);
      return;
    }

    final me = await _users.me(forceRefresh: true);
    if (!mounted) return;
    if (me.success) {
      _open(AppRoutes.home);
      return;
    }

    if (me.statusCode == 401 || me.statusCode == 403) {
      await _auth.clearLocalSession();
      if (!mounted) return;
    }
    _open(AppRoutes.login);
  }

  void _open(String route) => Navigator.of(context).pushReplacementNamed(route);

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: AppColors.homeBackground,
    body: Center(
      child: CircularProgressIndicator(color: AppColors.primaryBrown),
    ),
  );
}
