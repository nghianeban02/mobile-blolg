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
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, -8),
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
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.pill,
              boxShadow: isLoading ? null : AppShadows.primaryButton,
            ),
            child: FilledButton(
              onPressed: isLoading ? null : onPublish,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryBrown,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: const StadiumBorder(),
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
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
