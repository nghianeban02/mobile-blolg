import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/router/app_router.dart';
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
        content: Text(result.message),
        backgroundColor: AppColors.success,
      ),
    );
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.homeBackground,
    appBar: AppBar(title: const Text('Đặt lại mật khẩu')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                'Tạo mật khẩu mới',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),
              AuthFormField(
                label: 'Mã đặt lại từ email',
                hint: 'Dán token vào đây',
                controller: _token,
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? 'Vui lòng nhập token'
                    : null,
              ),
              const SizedBox(height: 24),
              AuthFormField(
                label: 'Mật khẩu mới',
                hint: '••••••••',
                controller: _password,
                obscureText: _obscure,
                showVisibilityToggle: true,
                onToggleVisibility: () => setState(() => _obscure = !_obscure),
                validator: (value) => (value?.length ?? 0) < 8
                    ? 'Mật khẩu cần ít nhất 8 ký tự'
                    : null,
              ),
              const SizedBox(height: 24),
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
                const SizedBox(height: 20),
                Text(_error!, style: const TextStyle(color: AppColors.error)),
              ],
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBrown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  shape: const StadiumBorder(),
                ),
                child: _loading
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('LƯU MẬT KHẨU MỚI'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
