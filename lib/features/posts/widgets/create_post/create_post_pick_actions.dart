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
      shape: const StadiumBorder(
        side: BorderSide(color: AppColors.borderStrong),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          alignment: Alignment.center,
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
