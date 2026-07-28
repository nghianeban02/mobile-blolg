import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/brand/site_brand.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/router/app_router.dart';
import 'package:mobile/core/theme/app_palette.dart';
import 'package:mobile/core/theme/app_spacing.dart';
import 'package:mobile/core/theme/app_typography.dart';
import 'package:mobile/core/widgets/editorial_button.dart';
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
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(title: const Text('Khôi phục mật khẩu')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SiteBrand(
                  variant: SiteBrandVariant.mobile,
                  showMark: true,
                  markSize: 32,
                ),
                SizedBox(height: AppSpacing.xxl + AppSpacing.xs),
                Text('Quên mật khẩu?', style: AppTypography.pageTitle(context)),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Nhập email tài khoản. Nếu email tồn tại, hệ thống sẽ gửi một liên kết đặt lại mật khẩu.',
                  style: AppTypography.subtitle(context),
                ),
                SizedBox(height: AppSpacing.section + AppSpacing.xs),
                AuthFormField(
                  label: 'Email',
                  hint: 'email@example.com',
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
                  const SizedBox(height: AppSpacing.xl),
                  _MessageBanner(result: _result!),
                ],
                SizedBox(height: AppSpacing.xxl + AppSpacing.xs),
                EditorialButton(
                  label: 'GỬI EMAIL ĐẶT LẠI',
                  onPressed: _loading ? null : _submit,
                  loading: _loading,
                  expanded: true,
                ),
                const SizedBox(height: AppSpacing.md),
                EditorialButton(
                  label: 'Tôi đã có mã đặt lại',
                  onPressed: () => context.push(AppRoutes.resetPassword),
                  variant: EditorialButtonVariant.ghost,
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

class _MessageBanner extends StatelessWidget {
  final AuthActionResult result;

  const _MessageBanner({required this.result});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = result.success ? p.success : p.danger;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + AppSpacing.xxs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.input,
      ),
      child: Text(
        result.message,
        style: AppTypography.body(context, color: color),
      ),
    );
  }
}
