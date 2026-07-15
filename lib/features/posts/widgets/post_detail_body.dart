import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/features/posts/widgets/post_detail_gallery.dart';
import 'package:mobile/features/posts/widgets/post_section_label.dart';

class PostDetailBody extends StatelessWidget {
  final PostDto post;

  const PostDetailBody({super.key, required this.post});

  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    final local = date.toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[local.month - 1]} ${local.day}, ${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _formatDate(post.createdAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PostSectionLabel(text: 'Editorial archive'),
        const SizedBox(height: 12),
        Text(
          post.title,
          style: GoogleFonts.playfairDisplay(
            color: AppColors.homeTextDark,
            fontSize: 34,
            height: 1.12,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
          ),
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
        const SizedBox(height: 24),
        Divider(
          height: 1,
          color: AppColors.homeTextDark.withValues(alpha: 0.08),
        ),
        const SizedBox(height: 24),
        Text(
          post.content,
          style: GoogleFonts.inter(
            color: AppColors.homeTextLight,
            fontSize: 15,
            height: 1.7,
          ),
        ),
        if (post.galleryImages.isNotEmpty) ...[
          const SizedBox(height: 40),
          PostDetailGallery(post: post),
        ],
        const SizedBox(height: 32),
      ],
    );
  }
}
