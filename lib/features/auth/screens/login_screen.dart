import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/brand/site_brand.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/i18n/locale_controller.dart';
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
      // GoRouter redirect handles navigation; no toast needed.
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
                                context.t('auth.welcomeBack'),
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.homeTextDark,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                context.t('auth.signInSubtitle'),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: AppColors.homeTextLight,
                                ),
                              ),
                              const SizedBox(height: 28),
                              AuthFormField(
                                label: context.t('auth.username'),
                                hint: context.t('auth.usernamePlaceholder'),
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if ((v?.trim() ?? '').isEmpty) {
                                    return context.t(
                                      'auth.usernamePlaceholder',
                                    );
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              AuthFormField(
                                label: context.t('auth.password'),
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
                                    context.t('auth.forgotPassword'),
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryBrown,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return context.t('auth.password');
                                  }
                                  if (value.length < 6) {
                                    return context.t('auth.password');
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
                                  _isLoading
                                      ? context.t('auth.signingIn')
                                      : context.t('auth.signIn'),
                                ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => context.push(AppRoutes.register),
                                child: Text(context.t('auth.createAccountBtn')),
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
                                      context.t('auth.or'),
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
                                child: Text(context.t('auth.continueGuest')),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                context.t('auth.guestHint'),
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
                          TextSpan(text: '${context.t('auth.noAccount')} '),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: GestureDetector(
                              onTap: () => context.push(AppRoutes.register),
                              child: Text(
                                context.t('auth.createAccount'),
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
