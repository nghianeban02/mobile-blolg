import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/router/app_router.dart';
import 'package:mobile/core/theme/app_palette.dart';
import 'package:mobile/core/theme/app_spacing.dart';
import 'package:mobile/core/theme/app_typography.dart';
import 'package:mobile/core/widgets/editorial_button.dart';
import 'package:mobile/data/auth/auth_repository.dart';
import 'package:mobile/features/auth/widgets/auth_form_field.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? initialToken;

  const ResetPasswordScreen({super.key, this.initialToken});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _token = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _auth = AuthRepository();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _token.text = widget.initialToken ?? '';
  }

  @override
  void dispose() {
    _token.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _auth.resetPassword(
      token: _token.text,
      newPassword: _password.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (!result.success) {
      setState(() => _error = result.message);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.message,
          style: AppTypography.body(context, color: Colors.white),
        ),
        backgroundColor: context.palette.success,
      ),
    );
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(title: const Text('Đặt lại mật khẩu')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  'Tạo mật khẩu mới',
                  style: AppTypography.pageTitle(context),
                ),
                const SizedBox(height: AppSpacing.section),
                AuthFormField(
                  label: 'Mã đặt lại từ email',
                  hint: 'Dán token vào đây',
                  controller: _token,
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? 'Vui lòng nhập token'
                      : null,
                ),
                const SizedBox(height: AppSpacing.xxl),
                AuthFormField(
                  label: 'Mật khẩu mới',
                  hint: '••••••••',
                  controller: _password,
                  obscureText: _obscure,
                  showVisibilityToggle: true,
                  onToggleVisibility: () =>
                      setState(() => _obscure = !_obscure),
                  validator: (value) => (value?.length ?? 0) < 8
                      ? 'Mật khẩu cần ít nhất 8 ký tự'
                      : null,
                ),
                const SizedBox(height: AppSpacing.xxl),
                AuthFormField(
                  label: 'Nhập lại mật khẩu',
                  hint: '••••••••',
                  controller: _confirm,
                  obscureText: _obscure,
                  validator: (value) => value != _password.text
                      ? 'Mật khẩu nhập lại chưa khớp'
                      : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    _error!,
                    style: AppTypography.body(context, color: p.danger),
                  ),
                ],
                SizedBox(height: AppSpacing.xxl + AppSpacing.xs),
                EditorialButton(
                  label: 'LƯU MẬT KHẨU MỚI',
                  onPressed: _loading ? null : _submit,
                  loading: _loading,
                  expanded: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
