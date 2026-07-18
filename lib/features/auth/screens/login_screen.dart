import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/brand/site_brand.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/router/app_router.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mobile/features/auth/widgets/auth_form_field.dart';

/// Login — bố cục mirror web `/login` (SiteBrand + card form + guest).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      AuthLoginRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  void _handleGuestLogin() {
    context.read<AuthBloc>().add(const AuthGuestRequested());
  }

  void _onAuthChanged(BuildContext context, AuthState state) {
    setState(() {
      _isLoading = state.submitting;
      _errorMessage = state.loginError;
    });
    if (state.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng nhập thành công!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: _onAuthChanged,
      child: Scaffold(
        backgroundColor: AppColors.homeBackground,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
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
                    const SizedBox(height: 28),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.card,
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppShadows.soft,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Chào mừng trở lại',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.homeTextDark,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Đăng nhập để xem dòng thời gian và thư viện của bạn.',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: AppColors.homeTextLight,
                                ),
                              ),
                              const SizedBox(height: 28),
                              AuthFormField(
                                label: 'Tên đăng nhập',
                                hint: 'ten_dang_nhap hoặc email@…',
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if ((v?.trim() ?? '').isEmpty) {
                                    return 'Vui lòng nhập email hoặc username';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              AuthFormField(
                                label: 'Mật khẩu',
                                hint: '••••••••',
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                showVisibilityToggle: true,
                                onToggleVisibility: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                trailingLabel: GestureDetector(
                                  onTap: () =>
                                      context.push(AppRoutes.forgotPassword),
                                  child: Text(
                                    'Quên mật khẩu?',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryBrown,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Vui lòng nhập mật khẩu';
                                  }
                                  if (value.length < 6) {
                                    return 'Mật khẩu phải có ít nhất 6 ký tự';
                                  }
                                  return null;
                                },
                              ),
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 16),
                                AuthErrorBanner(message: _errorMessage!),
                              ],
                              const SizedBox(height: 24),
                              FilledButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                child: Text(
                                  _isLoading ? 'Đang đăng nhập…' : 'Đăng nhập',
                                ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => context.push(AppRoutes.register),
                                child: const Text('Tạo tài khoản'),
                              ),
                              const SizedBox(height: 28),
                              Row(
                                children: [
                                  const Expanded(child: Divider()),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text(
                                      'HOẶC',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        letterSpacing: 1.6,
                                        color: AppColors.homeTextLight,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const Expanded(child: Divider()),
                                ],
                              ),
                              const SizedBox(height: 20),
                              OutlinedButton(
                                onPressed: _isLoading
                                    ? null
                                    : _handleGuestLogin,
                                child: const Text('Tiếp tục với tư cách khách'),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Xem bài công khai — chưa thể bình luận, thích hay đăng nội dung mới.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  height: 1.45,
                                  color: AppColors.homeTextLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text.rich(
                      TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.homeTextLight,
                        ),
                        children: [
                          const TextSpan(text: 'Chưa có tài khoản? '),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: GestureDetector(
                              onTap: () => context.push(AppRoutes.register),
                              child: Text(
                                'Đăng ký',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.homeTextDark,
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
