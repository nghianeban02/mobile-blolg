import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
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
                style: GoogleFonts.inter(),
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message ?? 'Đăng ký thành công. Đăng nhập ngay.',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      Navigator.pop(context);
    } else {
      setState(() => _errorMessage = result.message ?? 'Đăng ký thất bại.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      width: 140,
                      height: 140,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Text(
                    'Editorial Intelligence',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      color: AppColors.homeTextDark,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 40,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Create account',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 32,
                              color: AppColors.homeTextDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Join the archive — save reviews,\nreading lists, and your personal feed.',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.homeTextLight,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 40),
                          AuthFormField(
                            label: 'Username',
                            hint: 'your_name',
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
                          const SizedBox(height: 28),
                          AuthFormField(
                            label: 'Email address',
                            hint: 'reader@archive.com',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              final t = v?.trim() ?? '';
                              if (t.isEmpty) return 'Vui lòng nhập email';
                              if (!t.contains('@')) return 'Email không hợp lệ';
                              return null;
                            },
                          ),
                          const SizedBox(height: 28),
                          AuthFormField(
                            label: 'Password',
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
                          const SizedBox(height: 28),
                          AuthFormField(
                            label: 'Confirm password',
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
                            const SizedBox(height: 20),
                            AuthErrorBanner(message: _errorMessage!),
                          ],
                          const SizedBox(height: 28),
                          _buildRegisterButton(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: GoogleFonts.inter(
                          color: AppColors.homeTextDark.withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          'Sign in',
                          style: GoogleFonts.inter(
                            color: AppColors.homeTextDark,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: _loading ? null : _register,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryBrown,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.primaryBrown.withValues(alpha: 0.6),
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        elevation: 0,
      ),
      child: _loading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
          : Text(
              'SIGN UP',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
    );
  }
}
