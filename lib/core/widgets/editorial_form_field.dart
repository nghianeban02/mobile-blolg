import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';

/// Underline text field matching login / editorial compose screens.
class EditorialFormField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool obscureText;

  const EditorialFormField({
    super.key,
    required this.label,
    this.hint = '',
    required this.controller,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: AppColors.homeTextDark.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          style: GoogleFonts.inter(
            color: AppColors.homeTextDark,
            fontSize: maxLines > 1 ? 15 : 16,
            height: maxLines > 1 ? 1.65 : 1.2,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: AppColors.homeTextLight.withValues(alpha: 0.4),
              fontSize: maxLines > 1 ? 15 : 16,
              height: maxLines > 1 ? 1.65 : 1.2,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: AppColors.homeTextDark.withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primaryBrown, width: 2),
            ),
            errorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.error, width: 2),
            ),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              vertical: maxLines > 1 ? 12 : 8,
            ),
          ),
        ),
      ],
    );
  }
}
