import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/widgets/detail_app_bar.dart';
import 'package:mobile/core/widgets/editorial_surface_card.dart';
import 'package:mobile/data/repositories/users_repository.dart';
import 'package:mobile/features/auth/widgets/auth_form_field.dart';

/// Đổi mật khẩu — `PUT /api/users/me/password`.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  final _usersRepo = BeBlogUsersRepository();

  bool _saving = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    final result = await _usersRepo.changePassword(
      currentPassword: _currentController.text,
      newPassword: _newController.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã đổi mật khẩu.', style: GoogleFonts.inter()),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else {
      setState(
        () => _errorMessage = result.message ?? 'Không thể đổi mật khẩu.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const DetailSliverAppBar(title: 'Security'),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Change\npassword',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 34,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                          color: AppColors.homeTextDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Mật khẩu mới cần tối thiểu 6 ký tự.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.homeTextLight,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      EditorialSurfaceCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 28,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AuthFormField(
                              label: 'Current password',
                              hint: '••••••••',
                              controller: _currentController,
                              obscureText: _obscureCurrent,
                              showVisibilityToggle: true,
                              onToggleVisibility: () => setState(
                                () => _obscureCurrent = !_obscureCurrent,
                              ),
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Nhập mật khẩu hiện tại'
                                  : null,
                            ),
                            const SizedBox(height: 28),
                            AuthFormField(
                              label: 'New password',
                              hint: '••••••••',
                              controller: _newController,
                              obscureText: _obscureNew,
                              showVisibilityToggle: true,
                              onToggleVisibility: () =>
                                  setState(() => _obscureNew = !_obscureNew),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Nhập mật khẩu mới';
                                }
                                if (v.length < 6) {
                                  return 'Mật khẩu phải có ít nhất 6 ký tự';
                                }
                                if (v == _currentController.text) {
                                  return 'Mật khẩu mới phải khác mật khẩu cũ';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 28),
                            AuthFormField(
                              label: 'Confirm new password',
                              hint: '••••••••',
                              controller: _confirmController,
                              obscureText: _obscureConfirm,
                              showVisibilityToggle: true,
                              onToggleVisibility: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                              validator: (v) => v != _newController.text
                                  ? 'Mật khẩu không khớp'
                                  : null,
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 20),
                              AuthErrorBanner(message: _errorMessage!),
                            ],
                            const SizedBox(height: 28),
                            ElevatedButton(
                              onPressed: _saving ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBrown,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: AppColors.primaryBrown
                                    .withValues(alpha: 0.6),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: const StadiumBorder(),
                                elevation: 0,
                              ),
                              child: _saving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      'UPDATE PASSWORD',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
