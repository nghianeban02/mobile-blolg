import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/utils/text_excerpt.dart';
import 'package:mobile/core/widgets/app_cached_image.dart';
import 'package:mobile/core/widgets/editorial_surface_card.dart';
import 'package:mobile/data/models/dtos.dart';

class ProfilePostCard extends StatelessWidget {
  final PostDto post;
  final VoidCallback onTap;

  const ProfilePostCard({super.key, required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return EditorialSurfaceCard(
      onTap: onTap,
      showAccentBar: true,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.hasTitleImage)
            SizedBox(
              height: 140,
              width: double.infinity,
              child: AppCachedImage.sized(
                context: context,
                url: post.resolveTitleImageUrl(ApiConstants.baseUrl),
                logicalWidth: 400,
                logicalHeight: 140,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ARCHIVE POST',
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: AppColors.primaryBrown,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  post.title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  textExcerpt(post.content, maxLength: 120),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.homeTextLight,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
