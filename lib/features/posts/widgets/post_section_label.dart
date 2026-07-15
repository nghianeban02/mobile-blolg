import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';

/// Uppercase kicker label (matches Recent Archives section style).
class PostSectionLabel extends StatelessWidget {
  final String text;

  const PostSectionLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.inter(
        color: AppColors.homeTextLight,
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        height: 1.4,
      ),
    );
  }
}
