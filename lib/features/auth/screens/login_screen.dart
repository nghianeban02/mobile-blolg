import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/brand/site_brand.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/i18n/locale_controller.dart';
import 'package:mobile/core/router/app_router.dart';
import 'package:mobile/core/theme/app_palette.dart';
import 'package:mobile/core/theme/app_spacing.dart';
import 'package:mobile/core/theme/app_typography.dart';
import 'package:mobile/core/widgets/editorial_button.dart';
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
    final p = context.palette;

    return BlocListener<AuthBloc, AuthState>(
      listener: _onAuthChanged,
      child: Scaffold(
        backgroundColor: p.background,
        body: SafeArea(
          child: Center(
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
                    ),
                    SizedBox(height: AppSpacing.xxl + AppSpacing.xs),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: p.surface,
                        borderRadius: AppRadius.card,
                        border: Border.all(color: p.border),
                        boxShadow: AppShadows.soft,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xxl - AppSpacing.xxs,
                          AppSpacing.xxl + AppSpacing.xs,
                          AppSpacing.xxl - AppSpacing.xxs,
                          AppSpacing.xxl + AppSpacing.xs,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                context.t('auth.welcomeBack'),
                                style: AppTypography.pageTitle(context),
                              ),
                              const SizedBox(
                                height: AppSpacing.sm + AppSpacing.xxs,
                              ),
                              Text(
                                context.t('auth.signInSubtitle'),
                                style: AppTypography.subtitle(context),
                              ),
                              SizedBox(height: AppSpacing.xxl + AppSpacing.xs),
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
                              const SizedBox(height: AppSpacing.xl),
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
                                    style:
                                        AppTypography.accentLabel(
                                          context,
                                          color: p.accent,
                                        ).copyWith(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
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
                                const SizedBox(height: AppSpacing.lg),
                                AuthErrorBanner(message: _errorMessage!),
                              ],
                              const SizedBox(height: AppSpacing.xxl),
                              EditorialButton(
                                label: _isLoading
                                    ? context.t('auth.signingIn')
                                    : context.t('auth.signIn'),
                                onPressed: _isLoading ? null : _handleLogin,
                                loading: _isLoading,
                                expanded: true,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              EditorialButton(
                                label: context.t('auth.createAccountBtn'),
                                onPressed: _isLoading
                                    ? null
                                    : () => context.push(AppRoutes.register),
                                variant: EditorialButtonVariant.outline,
                                expanded: true,
                              ),
                              SizedBox(height: AppSpacing.xxl + AppSpacing.xs),
                              Row(
                                children: [
                                  Expanded(child: Divider(color: p.border)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                    ),
                                    child: Text(
                                      context.t('auth.or'),
                                      style:
                                          AppTypography.body(
                                            context,
                                            size: 11,
                                            color: p.muted,
                                          ).copyWith(
                                            letterSpacing: 1.6,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                  Expanded(child: Divider(color: p.border)),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              EditorialButton(
                                label: context.t('auth.continueGuest'),
                                onPressed: _isLoading
                                    ? null
                                    : _handleGuestLogin,
                                variant: EditorialButtonVariant.outline,
                                expanded: true,
                              ),
                              const SizedBox(
                                height: AppSpacing.sm + AppSpacing.xxs,
                              ),
                              Text(
                                context.t('auth.guestHint'),
                                textAlign: TextAlign.center,
                                style: AppTypography.body(context, size: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.xxl + AppSpacing.xs),
                    Text.rich(
                      TextSpan(
                        style: AppTypography.body(context),
                        children: [
                          TextSpan(text: '${context.t('auth.noAccount')} '),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: GestureDetector(
                              onTap: () => context.push(AppRoutes.register),
                              child: Text(
                                context.t('auth.createAccount'),
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
