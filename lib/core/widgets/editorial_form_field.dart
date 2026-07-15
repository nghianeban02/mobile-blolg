import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';

/// Filled text field kiểu web (uiField): nền ink/4, bo rounded-xl,
/// không viền, focus ring nâu nhạt. Label nhỏ chữ hoa ở trên.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.darkForeground
        : AppColors.homeTextDark;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.homeTextLight;
    final accent = isDark ? AppColors.darkAccent : AppColors.primaryBrown;
    final fill = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : AppColors.homeTextDark.withValues(alpha: 0.04);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: mutedColor,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          style: GoogleFonts.inter(
            color: textColor,
            fontSize: maxLines > 1 ? 15 : 16,
            height: maxLines > 1 ? 1.65 : 1.3,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: mutedColor.withValues(alpha: 0.6),
              fontSize: maxLines > 1 ? 15 : 16,
              height: maxLines > 1 ? 1.65 : 1.3,
            ),
            filled: true,
            fillColor: fill,
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
                color: accent.withValues(alpha: 0.45),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: AppRadius.input,
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: AppRadius.input,
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
