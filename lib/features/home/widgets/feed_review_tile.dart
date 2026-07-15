import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/navigation/open_user_profile.dart';
import 'package:mobile/core/utils/text_excerpt.dart';
import 'package:mobile/core/widgets/editorial_surface_card.dart';
import 'package:mobile/core/widgets/editorial_ui.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/features/review/screens/book_detail_screen.dart';

/// One review row on the home feed timeline.
class FeedReviewTile extends StatelessWidget {
  final FeedItemDto item;
  final bool isFromCircle;

  const FeedReviewTile({
    super.key,
    required this.item,
    required this.isFromCircle,
  });

  @override
  Widget build(BuildContext context) {
    final review = item.review!;
    final authorName =
        item.author?.displayName ??
        (item.author?.username.isNotEmpty == true
            ? item.author!.username
            : 'Reader');
    final authorId = item.authorId ?? item.author?.id ?? review.userId;

    return EditorialSurfaceCard(
      showAccentBar: true,
      accentColor: isFromCircle ? AppColors.coverTeal : AppColors.primaryBrown,
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookDetailScreen(
              reviewId: review.id,
              initialReview: review,
              authorId: authorId,
              authorDisplayName: authorName,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isFromCircle) ...[
                const EditorialStatusChip(label: 'Circle'),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: GestureDetector(
                  onTap: item.authorId != null
                      ? () => openUserProfile(
                          context,
                          userId: item.authorId!,
                          displayName: authorName,
                        )
                      : null,
                  child: Text(
                    authorName.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppColors.primaryBrown,
                    ),
                  ),
                ),
              ),
              Text(
                '${review.rating} ★',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.homeTextDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            textExcerpt(review.content, maxLength: 140),
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.homeTextLight,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
