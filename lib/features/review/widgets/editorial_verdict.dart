import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';

class EditorialVerdict extends StatelessWidget {
  const EditorialVerdict({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.menu_book,
                  color: AppColors.primaryBrown,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Text(
                  'THE EDITORIAL VERDICT',
                  style: GoogleFonts.inter(
                    color: AppColors.homeTextDark,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'A luminous, life-\naffirming mystery... \nthat transforms the\nconcept of the "What If"\ninto a powerful\ncelebration of the "What\nIs."',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                color: AppColors.homeTextDark,
                fontSize: 22,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildTag('EXISTENTIAL REGRET'),
                _buildTag('FORGIVENESS'),
                _buildTag('A BIT WEEPY', isSecondary: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, {bool isSecondary = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isSecondary
            ? Colors.grey.shade100
            : AppColors.success.withValues(alpha: 0.15),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: isSecondary ? Colors.grey.shade600 : Colors.green.shade800,
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
