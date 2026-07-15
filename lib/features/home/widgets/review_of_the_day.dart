import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/utils/text_excerpt.dart';
import 'package:mobile/core/widgets/editorial_ui.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/features/review/screens/book_detail_screen.dart';

class ReviewOfTheDay extends StatelessWidget {
  final ReviewDto? review;
  final UserPublicDto? author;

  const ReviewOfTheDay({super.key, this.review, this.author});

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'published':
        return 'Đã xuất bản';
      case 'draft':
        return 'Bản nháp';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasReview = review != null;
    final title = review?.title ?? 'Đánh giá nổi bật';
    final content = hasReview
        ? textExcerpt(review!.content, maxLength: 280)
        : 'Đăng nhập và viết đánh giá đầu tiên để xem tại đây.';
    final rating = (review?.rating ?? 0).clamp(0, 5);
    final status = review?.status ?? 'draft';
    final coverTitle = hasReview
        ? textExcerpt(review!.title, maxLength: 48)
        : 'Sách &\nđánh giá';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: AppColors.coverTeal.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: editorialSoftShadow(opacity: 0.08),
              ),
              child: Center(
                child: Container(
                  width: 168,
                  height: 236,
                  decoration: BoxDecoration(
                    color: AppColors.coverTeal,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 18,
                        offset: const Offset(-6, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
                      Text(
                        coverTitle.toUpperCase(),
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (author != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          author!.displayName.toUpperCase(),
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 8,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const Spacer(flex: 2),
                      Row(
                        children: List.generate(5, (i) {
                          return Icon(
                            i < rating ? Icons.star : Icons.star_border,
                            size: 12,
                            color: Colors.white.withValues(alpha: 0.9),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              EditorialStatusChip(
                label: _statusLabel(status),
                backgroundColor: status == 'published'
                    ? AppColors.success.withValues(alpha: 0.15)
                    : AppColors.coverSand.withValues(alpha: 0.6),
                textColor: status == 'published'
                    ? Colors.green.shade800
                    : AppColors.primaryBrown,
              ),
              const SizedBox(width: 12),
              Text(
                'Đánh giá nổi bật',
                style: GoogleFonts.playfairDisplay(
                  fontStyle: FontStyle.italic,
                  color: AppColors.homeTextLight,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (author != null) ...[
            const SizedBox(height: 8),
            Text(
              'bởi ${author!.displayName}',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.primaryBrown,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              color: AppColors.homeTextDark,
              fontSize: 34,
              height: 1.12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            content,
            style: GoogleFonts.inter(
              color: AppColors.homeTextLight,
              fontSize: 14,
              height: 1.6,
            ),
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              ElevatedButton(
                onPressed: hasReview
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookDetailScreen(
                              reviewId: review!.id,
                              initialReview: review,
                            ),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBrown,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                ),
                child: Text(
                  'ĐỌC\nĐÁNH GIÁ',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Row(
                children: List.generate(5, (index) {
                  final filled = index < rating;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      filled ? Icons.star : Icons.star_border,
                      color: AppColors.primaryBrown,
                      size: 18,
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
