import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/data/repositories/engagement_repository.dart';

class NewsletterSection extends StatefulWidget {
  const NewsletterSection({super.key});

  @override
  State<NewsletterSection> createState() => _NewsletterSectionState();
}

class _NewsletterSectionState extends State<NewsletterSection> {
  final _engagementRepo = BeBlogEngagementRepository();
  final _email = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _subscribe() async {
    final email = _email.text.trim();
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vui lòng nhập email hợp lệ.',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    final result = await _engagementRepo.subscribeNewsletter(email);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (result.success) _email.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? (result.data ?? 'Đăng ký nhận bản tin thành công.')
              : (result.message ?? 'Không đăng ký được. Thử lại sau.'),
          style: GoogleFonts.inter(),
        ),
        backgroundColor: result.success ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.homeBackground.withValues(alpha: 0.7),
      padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 24.0),
      child: Container(
        padding: const EdgeInsets.all(32.0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          children: [
            const Icon(
              Icons.menu_book_rounded,
              color: AppColors.primaryBrown,
              size: 32,
            ),
            const SizedBox(height: 16),
            Text(
              'The Weekly\nDispatch',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                color: AppColors.homeTextDark,
                fontSize: 28,
                height: 1.1,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Curated literary critiques\nand exclusive author\ninterviews delivered to your\ninbox every Sunday\nmorning.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.homeTextLight,
                fontSize: 12,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textAlign: TextAlign.center,
              onSubmitted: (_) => _submitting ? null : _subscribe(),
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.homeTextDark,
              ),
              decoration: InputDecoration(
                hintText: 'Your email address',
                hintStyle: GoogleFonts.inter(
                  color: AppColors.homeTextLight.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
                filled: true,
                fillColor: AppColors.homeTextDark.withValues(alpha: 0.04),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.input,
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.input,
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.input,
                  borderSide: BorderSide(
                    color: AppColors.primaryBrown.withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _subscribe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.homeTextDark,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _submitting
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'SUBSCRIBE',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
