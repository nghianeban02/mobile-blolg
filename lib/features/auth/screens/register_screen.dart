import 'package:flutter/material.dart';
import 'package:mobile/core/brand/site_brand.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/theme/app_palette.dart';
import 'package:mobile/core/theme/app_spacing.dart';
import 'package:mobile/core/theme/app_typography.dart';
import 'package:mobile/core/widgets/editorial_button.dart';
import 'package:mobile/data/auth/auth_repository.dart';
import 'package:mobile/data/auth/register_request.dart';
import 'package:mobile/features/auth/screens/verify_email_screen.dart';
import 'package:mobile/features/auth/widgets/auth_form_field.dart';

/// `POST /api/auth/register` — UI aligned with [LoginScreen].
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authRepo = AuthRepository();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final result = await _authRepo.register(
      RegisterRequest(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      if (result.needsVerification) {
        final verified = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) =>
                VerifyEmailScreen(email: _emailController.text.trim()),
          ),
        );
        if (!mounted) return;
        // Quay lại login dù đã xác nhận hay chưa (user có thể verify sau).
        Navigator.pop(context);
        if (verified == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Tài khoản đã được xác nhận. Đăng nhập ngay.',
                style: AppTypography.body(context, color: Colors.white),
              ),
              backgroundColor: context.palette.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message ?? 'Đăng ký thành công. Đăng nhập ngay.',
            style: AppTypography.body(context, color: Colors.white),
          ),
          backgroundColor: context.palette.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else {
      setState(() => _errorMessage = result.message ?? 'Đăng ký thất bại.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xxl + AppSpacing.xs,
                AppSpacing.xl,
                AppSpacing.section,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SiteBrand(
                      variant: SiteBrandVariant.mobile,
                      showSlogan: true,
                      showMark: true,
                      markSize: 36,
                    ),
                    SizedBox(height: AppSpacing.xxl + AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xxl - AppSpacing.xxs,
                        AppSpacing.xxl + AppSpacing.xs,
                        AppSpacing.xxl - AppSpacing.xxs,
                        AppSpacing.xxl + AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: p.surface,
                        borderRadius: AppRadius.card,
                        border: Border.all(color: p.border),
                        boxShadow: AppShadows.soft,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Tạo tài khoản',
                              style: AppTypography.pageTitle(context),
                            ),
                            const SizedBox(
                              height: AppSpacing.sm + AppSpacing.xxs,
                            ),
                            Text(
                              'Tham gia cộng đồng đọc và viết trên Nook.',
                              style: AppTypography.subtitle(context),
                            ),
                            SizedBox(height: AppSpacing.xxl + AppSpacing.xs),
                            AuthFormField(
                              label: 'Tên đăng nhập',
                              hint: 'ten_dang_nhap',
                              controller: _usernameController,
                              validator: (v) {
                                final t = v?.trim() ?? '';
                                if (t.isEmpty) return 'Vui lòng nhập username';
                                if (t.length < 3) {
                                  return 'Username tối thiểu 3 ký tự';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            AuthFormField(
                              label: 'Email',
                              hint: 'email@example.com',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                final t = v?.trim() ?? '';
                                if (t.isEmpty) {
                                  return 'Vui lòng nhập email';
                                }
                                if (!t.contains('@')) {
                                  return 'Email không hợp lệ';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            AuthFormField(
                              label: 'Mật khẩu',
                              hint: '••••••••',
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              showVisibilityToggle: true,
                              onToggleVisibility: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Vui lòng nhập mật khẩu';
                                }
                                if (v.length < 6) {
                                  return 'Mật khẩu phải có ít nhất 6 ký tự';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: AppSpacing.xxl + AppSpacing.xs),
                            AuthFormField(
                              label: 'Xác nhận mật khẩu',
                              hint: '••••••••',
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirm,
                              showVisibilityToggle: true,
                              onToggleVisibility: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                              validator: (v) {
                                if (v != _passwordController.text) {
                                  return 'Mật khẩu không khớp';
                                }
                                return null;
                              },
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: AppSpacing.xl),
                              AuthErrorBanner(message: _errorMessage!),
                            ],
                            SizedBox(height: AppSpacing.xxl + AppSpacing.xs),
                            EditorialButton(
                              label: _loading ? 'Đang tạo…' : 'Tạo tài khoản',
                              onPressed: _loading ? null : _register,
                              loading: _loading,
                              expanded: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.xxl + AppSpacing.xs),
                    Text.rich(
                      TextSpan(
                        style: AppTypography.body(context),
                        children: [
                          const TextSpan(text: 'Đã có tài khoản? '),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Text(
                                'Đăng nhập',
                                style: AppTypography.body(context).copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: p.foreground,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
