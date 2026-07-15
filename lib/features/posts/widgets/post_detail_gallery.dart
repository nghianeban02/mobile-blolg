import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/features/posts/screens/post_image_viewer_screen.dart';
import 'package:mobile/features/posts/utils/post_image_urls.dart';
import 'package:mobile/features/posts/widgets/post_network_image.dart';
import 'package:mobile/features/posts/widgets/post_section_label.dart';

class PostDetailGallery extends StatelessWidget {
  final PostDto post;

  const PostDetailGallery({super.key, required this.post});

  List<PostGalleryImageDto> get images => post.galleryImages;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    final allUrls = postDetailImageUrls(post);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PostSectionLabel(text: 'In this story'),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: images.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final img = images[index];
              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 140,
                  child: PostNetworkImage(
                    url: img.resolveUrl(ApiConstants.baseUrl),
                    fallbackColor: AppColors.coverTeal,
                    onTap: () => PostImageViewerScreen.open(
                      context,
                      imageUrls: allUrls,
                      initialIndex: galleryViewerIndex(post, index),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 8),
          Text(
            '${images.length} images',
            style: GoogleFonts.inter(
              color: AppColors.homeTextLight,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}
