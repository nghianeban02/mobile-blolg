import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/navigation/open_user_profile.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/features/posts/widgets/post_section_label.dart';

/// Editorial body for a single book review (aligned with [PostDetailBody]).
class ReviewDetailBody extends StatelessWidget {
  final ReviewDto review;
  final String? bookTitle;
  final String? authorId;
  final String? authorDisplayName;

  const ReviewDetailBody({
    super.key,
    required this.review,
    this.bookTitle,
    this.authorId,
    this.authorDisplayName,
  });

  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    final local = date.toLocal();
    const months = [
      'Th1',
      'Th2',
      'Th3',
      'Th4',
      'Th5',
      'Th6',
      'Th7',
      'Th8',
      'Th9',
      'Th10',
      'Th11',
      'Th12',
    ];
    return '${local.day} ${months[local.month - 1]}, ${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _formatDate(review.publishedAt ?? review.createdAt);
    final rating = review.rating.clamp(0, 5);
    final author = authorDisplayName?.trim();
    final showAuthor = author != null && author.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PostSectionLabel(text: 'REVIEW SÁCH'),
        if (showAuthor) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: authorId != null
                ? () => openUserProfile(
                    context,
                    userId: authorId!,
                    displayName: author,
                  )
                : null,
            child: Text(
              author.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.4,
                color: AppColors.primaryBrown,
                decoration: authorId != null ? TextDecoration.underline : null,
                decorationColor: AppColors.primaryBrown.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
        if (bookTitle != null && bookTitle!.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            bookTitle!.trim(),
            style: GoogleFonts.inter(
              color: AppColors.homeTextLight,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          review.title,
          style: GoogleFonts.playfairDisplay(
            color: AppColors.homeTextDark,
            fontSize: 34,
            height: 1.12,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ...List.generate(5, (index) {
              final filled = index < rating;
              return Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Icon(
                  filled ? Icons.star : Icons.star_border,
                  color: AppColors.primaryBrown,
                  size: 18,
                ),
              );
            }),
            const SizedBox(width: 12),
            Text(
              '$rating / 5',
              style: GoogleFonts.inter(
                color: AppColors.homeTextDark,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (dateLabel != null) ...[
          const SizedBox(height: 12),
          Text(
            dateLabel,
            style: GoogleFonts.inter(
              color: AppColors.primaryBrown,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (review.containsSpoilers) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: AppColors.error.withValues(alpha: 0.08),
            child: Text(
              'CẢNH BÁO SPOILER',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppColors.error,
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Divider(
          height: 1,
          color: AppColors.homeTextDark.withValues(alpha: 0.08),
        ),
        const SizedBox(height: 24),
        Text(
          review.content,
          style: GoogleFonts.inter(
            color: AppColors.homeTextLight,
            fontSize: 15,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
