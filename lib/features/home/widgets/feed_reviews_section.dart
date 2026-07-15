import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/features/home/widgets/feed_review_tile.dart';
import 'package:mobile/features/posts/widgets/post_section_label.dart';

/// Review sách từ feed (`GET /api/feed`) — mình + bạn bè (published).
class FeedReviewsSection extends StatelessWidget {
  final List<FeedItemDto> reviewItems;
  final Set<String> friendReviewIds;

  const FeedReviewsSection({
    super.key,
    required this.reviewItems,
    required this.friendReviewIds,
  });

  @override
  Widget build(BuildContext context) {
    final hasCircleReviews = friendReviewIds.isNotEmpty;
    final display = hasCircleReviews
        ? reviewItems
              .where(
                (i) =>
                    i.review != null && friendReviewIds.contains(i.review!.id),
              )
              .toList()
        : reviewItems;
    final visible = display.take(8).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PostSectionLabel(
            text: hasCircleReviews
                ? 'REVIEWS FROM YOUR CIRCLE'
                : 'BOOK REVIEWS',
          ),
          const SizedBox(height: 8),
          Text(
            hasCircleReviews
                ? 'Critiques mới từ vòng bạn bè trên timeline.'
                : reviewItems.isEmpty
                ? 'Chưa có review trên feed. Bạn bè cần publish review.'
                : 'Các review gần đây trên dòng thời gian của bạn.',
            style: GoogleFonts.inter(
              color: AppColors.homeTextLight,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          if (visible.isEmpty)
            Text(
              'Kết bạn và đảm bảo review ở trạng thái published.',
              style: GoogleFonts.inter(
                color: AppColors.homeTextLight,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...visible.map(
              (item) => FeedReviewTile(
                key: ValueKey(item.review!.id),
                item: item,
                isFromCircle: friendReviewIds.contains(item.review!.id),
              ),
            ),
        ],
      ),
    );
  }
}
