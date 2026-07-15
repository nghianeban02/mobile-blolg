import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';

class CreatePostSubmitBar extends StatelessWidget {
  final bool isLoading;
  final bool hasCover;
  final int galleryCount;
  final VoidCallback onPublish;

  const CreatePostSubmitBar({
    super.key,
    required this.isLoading,
    required this.hasCover,
    required this.galleryCount,
    required this.onPublish,
  });

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (hasCover) parts.add('1 cover');
    if (galleryCount > 0) parts.add('$galleryCount gallery');
    final mediaHint = parts.isEmpty ? 'Text only' : parts.join(' · ');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.homeBackground,
        border: Border(
          top: BorderSide(
            color: AppColors.homeTextDark.withValues(alpha: 0.08),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ready to publish',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.homeTextDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  mediaHint,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.homeTextLight,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          FilledButton(
            onPressed: isLoading ? null : onPublish,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryBrown,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Publish',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
