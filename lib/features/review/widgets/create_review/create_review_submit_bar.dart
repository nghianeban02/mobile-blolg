import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';

class CreateReviewSubmitBar extends StatelessWidget {
  final bool isLoading;
  final String bookTitle;
  final int rating;
  final String status;
  final bool hasCover;
  final VoidCallback onPublish;

  const CreateReviewSubmitBar({
    super.key,
    required this.isLoading,
    required this.bookTitle,
    required this.rating,
    required this.status,
    this.hasCover = false,
    required this.onPublish,
  });

  @override
  Widget build(BuildContext context) {
    final titleHint = bookTitle.trim().isEmpty
        ? 'Add book title'
        : bookTitle.trim();

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
                  'Save to library',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.homeTextDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$titleHint · $rating★ · $status${hasCover ? ' · cover' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
