import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/utils/text_excerpt.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/features/review/screens/book_detail_screen.dart';

class RelatedReviewsSection extends StatelessWidget {
  final List<ReviewDto> reviews;
  final String excludeReviewId;
  final String? authorId;

  const RelatedReviewsSection({
    super.key,
    required this.reviews,
    required this.excludeReviewId,
    this.authorId,
  });

  @override
  Widget build(BuildContext context) {
    final related = reviews
        .where((r) => r.id != excludeReviewId)
        .take(3)
        .toList();

    if (related.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review khác\nvề cuốn sách',
            style: GoogleFonts.playfairDisplay(
              color: AppColors.homeTextDark,
              fontSize: 28,
              height: 1.1,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          ...related.map(
            (review) => Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.card,
                  side: const BorderSide(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookDetailScreen(
                          reviewId: review.id,
                          initialReview: review,
                          authorId: authorId ?? review.userId,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.title,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.homeTextDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          textExcerpt(review.content, maxLength: 100),
                          style: GoogleFonts.inter(
                            color: AppColors.homeTextLight,
                            fontSize: 12,
                            height: 1.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
