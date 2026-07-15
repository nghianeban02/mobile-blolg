import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/data/auth/auth_repository.dart';
import 'package:mobile/features/auth/widgets/auth_form_field.dart';

/// Màn xác nhận email sau khi đăng ký (be-blog yêu cầu verify trước khi login).
///
/// Cho phép nhập mã/token từ email và gửi lại link xác nhận.
class VerifyEmailScreen extends StatefulWidget {
  final String email;

  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _authRepo = AuthRepository();

  bool _verifying = false;
  bool _resending = false;
  String? _errorMessage;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _verifying = true;
      _errorMessage = null;
    });

    final result = await _authRepo.verifyEmail(_tokenController.text);
    if (!mounted) return;
    setState(() => _verifying = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message ?? 'Email đã xác nhận. Đăng nhập ngay.',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      setState(() => _errorMessage = result.message ?? 'Xác nhận thất bại.');
    }
  }

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _errorMessage = null;
    });
    final result = await _authRepo.resendVerification(widget.email);
    if (!mounted) return;
    setState(() => _resending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.message ??
              (result.success
                  ? 'Đã gửi lại email xác nhận.'
                  : 'Không thể gửi lại email.'),
          style: GoogleFonts.inter(),
        ),
        backgroundColor: result.success ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      appBar: AppBar(
        backgroundColor: AppColors.homeBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          color: AppColors.homeTextDark,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.coverSand,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  color: AppColors.primaryBrown,
                  size: 34,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Check your inbox',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  color: AppColors.homeTextDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text.rich(
                TextSpan(
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.homeTextLight,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: 'Chúng tôi đã gửi link xác nhận tới '),
                    TextSpan(
                      text: widget.email,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.homeTextDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(
                      text:
                          '. Mở email và bấm vào link, hoặc dán mã xác nhận bên dưới.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
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
                      AuthFormField(
                        label: 'Verification code',
                        hint: 'Dán mã từ email',
                        controller: _tokenController,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Nhập mã xác nhận'
                            : null,
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 20),
                        AuthErrorBanner(message: _errorMessage!),
                      ],
                      const SizedBox(height: 28),
                      ElevatedButton(
                        onPressed: _verifying ? null : _verify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBrown,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.primaryBrown
                              .withValues(alpha: 0.6),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: const StadiumBorder(),
                          elevation: 0,
                        ),
                        child: _verifying
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
                                'VERIFY EMAIL',
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
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Chưa nhận được email? ',
                    style: GoogleFonts.inter(
                      color: AppColors.homeTextDark.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: _resending ? null : _resend,
                    child: Text(
                      _resending ? 'Đang gửi…' : 'Gửi lại',
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
    );
  }
}
