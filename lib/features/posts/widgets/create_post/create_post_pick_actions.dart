import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';

/// Compact gallery / camera actions for image sections.
class CreatePostPickActions extends StatelessWidget {
  final VoidCallback onGallery;
  final VoidCallback onCamera;
  final String galleryLabel;
  final String cameraLabel;

  const CreatePostPickActions({
    super.key,
    required this.onGallery,
    required this.onCamera,
    this.galleryLabel = 'Thư viện',
    this.cameraLabel = 'Máy ảnh',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionChip(
            icon: Icons.photo_library_outlined,
            label: galleryLabel,
            onTap: onGallery,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionChip(
            icon: Icons.photo_camera_outlined,
            label: cameraLabel,
            onTap: onCamera,
          ),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: AppColors.homeTextDark.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: AppColors.primaryBrown),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.homeTextDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
