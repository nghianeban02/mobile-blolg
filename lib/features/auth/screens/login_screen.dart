import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/router/app_router.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mobile/features/auth/widgets/auth_form_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
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
      // Điều hướng về /home do router redirect đảm nhiệm.
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: _onAuthChanged,
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo header
                  Center(
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      width: 180,
                      height: 180,
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
                  const SizedBox(height: 48),

                  // White Card
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 40,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.card,
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppShadows.soft,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Welcome Back',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 32,
                              color: AppColors.homeTextDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Access your curated literary archive\nand recent intelligence.',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.homeTextLight,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 48),

                          // EMAIL FIELD
                          _buildEmailField(),
                          const SizedBox(height: 32),

                          // PASSWORD FIELD
                          _buildPasswordField(),
                          const SizedBox(height: 12),

                          if (_errorMessage != null) ...[
                            const SizedBox(height: 12),
                            _buildErrorMessage(),
                            const SizedBox(height: 12),
                          ] else ...[
                            const SizedBox(height: 24),
                          ],

                          // SIGN IN BUTTON
                          _buildLoginButton(),
                          const SizedBox(height: 16),
                          _buildRegisterButton(),

                          const SizedBox(height: 48),
                          // OR CONTINUE WITH
                          Center(
                            child: Text(
                              'Or continue with',
                              style: GoogleFonts.inter(
                                color: AppColors.homeTextDark.withValues(
                                  alpha: 0.7,
                                ),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          OutlinedButton.icon(
                            onPressed: _isLoading ? null : _handleGuestLogin,
                            icon: const Icon(Icons.menu_book_outlined),
                            label: const Text('BROWSE AS GUEST'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.homeTextDark,
                              side: const BorderSide(
                                color: AppColors.borderStrong,
                              ),
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                  // SIGN UP LINK
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return AuthFormField(
      label: 'Email address',
      hint: 'reader@archive.com',
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      validator: (v) {
        final t = v?.trim() ?? '';
        if (t.isEmpty) return 'Vui lòng nhập email hoặc username';
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return AuthFormField(
      label: 'Password',
      hint: '••••••••',
      controller: _passwordController,
      obscureText: _obscurePassword,
      showVisibilityToggle: true,
      onToggleVisibility: () =>
          setState(() => _obscurePassword = !_obscurePassword),
      trailingLabel: GestureDetector(
        onTap: () => context.push(AppRoutes.forgotPassword),
        child: Text(
          'FORGOT?',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
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
    );
  }

  Widget _buildErrorMessage() => AuthErrorBanner(message: _errorMessage!);

  Widget _buildRegisterButton() {
    return OutlinedButton(
      onPressed: _isLoading
          ? null
          : () => context.push(AppRoutes.register),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryBrown,
        side: BorderSide(color: AppColors.primaryBrown.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: const StadiumBorder(),
      ),
      child: Text(
        'CREATE ACCOUNT',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: AppRadius.pill,
        boxShadow: _isLoading ? null : AppShadows.primaryButton,
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBrown,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primaryBrown.withValues(
            alpha: 0.6,
          ),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: const StadiumBorder(),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Text(
                'SIGN IN',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Don\'t have an account? ',
          style: GoogleFonts.inter(
            color: AppColors.homeTextDark.withValues(alpha: 0.6),
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: () => context.push(AppRoutes.register),
          child: Text(
            'Sign up',
            style: GoogleFonts.inter(
              color: AppColors.homeTextDark,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
