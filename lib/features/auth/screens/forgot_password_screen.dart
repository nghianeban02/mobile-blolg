import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/app/routes.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/data/auth/auth_repository.dart';
import 'package:mobile/features/auth/widgets/auth_form_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _auth = AuthRepository();
  bool _loading = false;
  AuthActionResult? _result;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _result = null;
    });
    final result = await _auth.requestPasswordReset(_email.text);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.homeBackground,
    appBar: AppBar(title: const Text('Khôi phục mật khẩu')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Text(
                'Quên mật khẩu?',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                  color: AppColors.homeTextDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Nhập email tài khoản. Nếu email tồn tại, hệ thống sẽ gửi một liên kết đặt lại mật khẩu.',
                style: GoogleFonts.inter(
                  height: 1.55,
                  color: AppColors.homeTextLight,
                ),
              ),
              const SizedBox(height: 36),
              AuthFormField(
                label: 'Email',
                hint: 'reader@archive.com',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty || !text.contains('@')) {
                    return 'Vui lòng nhập email hợp lệ';
                  }
                  return null;
                },
              ),
              if (_result != null) ...[
                const SizedBox(height: 20),
                _MessageBanner(result: _result!),
              ],
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBrown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                ),
                child: _loading
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('GỬI EMAIL ĐẶT LẠI'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.resetPassword),
                child: const Text('Tôi đã có mã đặt lại'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _MessageBanner extends StatelessWidget {
  final AuthActionResult result;

  const _MessageBanner({required this.result});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    color: (result.success ? AppColors.success : AppColors.error).withValues(
      alpha: 0.1,
    ),
    child: Text(
      result.message,
      style: TextStyle(
        color: result.success ? AppColors.success : AppColors.error,
      ),
    ),
  );
}
