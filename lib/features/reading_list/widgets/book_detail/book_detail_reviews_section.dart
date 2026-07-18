import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/utils/text_excerpt.dart';
import 'package:mobile/core/widgets/editorial_surface_card.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/features/posts/widgets/post_section_label.dart';
import 'package:mobile/features/review/screens/book_detail_screen.dart';

class BookDetailReviewsSection extends StatelessWidget {
  final List<ReviewDto> reviews;

  const BookDetailReviewsSection({super.key, required this.reviews});

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PostSectionLabel(text: 'Reviews'),
            const SizedBox(height: 12),
            Text(
              'No review for this title yet.',
              style: GoogleFonts.inter(
                color: AppColors.homeTextLight,
                fontSize: 13,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PostSectionLabel(
            text: reviews.length == 1
                ? 'Review'
                : 'Reviews (${reviews.length})',
          ),
          const SizedBox(height: 16),
          ...reviews.map((review) => _ReviewTile(review: review)),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final ReviewDto review;

  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final rating = review.rating.clamp(0, 5);

    return EditorialSurfaceCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                BookDetailScreen(reviewId: review.id, initialReview: review),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: AppRadius.pill,
                ),
                child: Text(
                  review.status.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: Colors.green.shade800,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              if (rating > 0)
                Row(
                  children: List.generate(
                    rating,
                    (_) => const Icon(
                      Icons.star,
                      size: 12,
                      color: AppColors.primaryBrown,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.title,
            style: GoogleFonts.playfairDisplay(
              color: AppColors.homeTextDark,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            textExcerpt(review.content, maxLength: 140),
            style: GoogleFonts.inter(
              color: AppColors.homeTextLight,
              fontSize: 12,
              height: 1.55,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Text(
            'Read full review →',
            style: GoogleFonts.inter(
              color: AppColors.primaryBrown,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
