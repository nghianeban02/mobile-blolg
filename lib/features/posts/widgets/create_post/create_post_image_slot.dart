import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';

/// Empty state for image pick areas.
class CreatePostImageSlot extends StatelessWidget {
  final double height;
  final String title;
  final String subtitle;
  final IconData icon;

  const CreatePostImageSlot({
    super.key,
    required this.height,
    this.title = 'Add visual',
    this.subtitle = 'Tap below to choose from library or camera',
    this.icon = Icons.add_photo_alternate_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppColors.homeTextDark.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 36,
            color: AppColors.homeTextLight.withValues(alpha: 0.45),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color: AppColors.homeTextDark.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.homeTextLight,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
