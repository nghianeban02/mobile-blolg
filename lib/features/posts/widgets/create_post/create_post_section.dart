import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/features/posts/widgets/post_section_label.dart';

/// Labeled block for create-post steps (title image, gallery, etc.).
class CreatePostSection extends StatelessWidget {
  final String label;
  final String? subtitle;
  final Widget child;

  const CreatePostSection({
    super.key,
    required this.label,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PostSectionLabel(text: label),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.homeTextLight,
              height: 1.45,
            ),
          ),
        ],
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}
