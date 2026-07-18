import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/utils/text_excerpt.dart';
import 'package:mobile/core/widgets/app_cached_image.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/features/posts/screens/post_detail_screen.dart';
import 'package:mobile/features/search/screens/search_screen.dart';

class RecentArchives extends StatelessWidget {
  final List<PostDto> posts;
  final VoidCallback? onPostChanged;

  const RecentArchives({super.key, required this.posts, this.onPostChanged});

  @override
  Widget build(BuildContext context) {
    final displayed = posts.take(6).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bài viết\nmới',
                      style: GoogleFonts.playfairDisplay(
                        color: AppColors.homeTextDark,
                        fontSize: 32,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'TỪ DÒNG THỜI GIAN CỦA BẠN',
                      style: GoogleFonts.inter(
                        color: AppColors.homeTextLight,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => const SearchScreen()),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'Xem\ntất cả',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.inter(
                      color: AppColors.primaryBrown,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primaryBrown.withValues(
                        alpha: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 420,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            cacheExtent: 480,
            itemCount: displayed.isEmpty ? 1 : displayed.length,
            separatorBuilder: (context, index) => const SizedBox(width: 20),
            itemBuilder: (context, index) {
              if (displayed.isEmpty) {
                return const _ArchiveCard(
                  post: null,
                  title: 'Chưa có bài viết',
                  author: 'Tạo bài đầu tiên từ tab Home',
                  excerpt: 'Đăng nhập và đăng bài để hiển thị tại đây.',
                  color: AppColors.coverSand,
                );
              }
              final post = displayed[index];
              return _ArchiveCard(
                key: ValueKey(post.id),
                post: post,
                title: post.title,
                author: 'Bài viết',
                excerpt: textExcerpt(post.content, maxLength: 120),
                color: index.isEven ? AppColors.coverSand : AppColors.coverTeal,
                onPostChanged: onPostChanged,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ArchiveCard extends StatelessWidget {
  final PostDto? post;
  final String title;
  final String author;
  final String excerpt;
  final Color color;
  final VoidCallback? onPostChanged;

  const _ArchiveCard({
    super.key,
    required this.post,
    required this.title,
    required this.author,
    required this.excerpt,
    required this.color,
    this.onPostChanged,
  });

  Future<void> _openDetail(BuildContext context) async {
    final p = post;
    if (p == null) return;
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(postId: p.id, initialPost: p),
      ),
    );
    if (changed == true) onPostChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final card = SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RepaintBoundary(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: SizedBox(
                width: 220,
                height: 260,
                child: ColoredBox(
                  color: color.withValues(alpha: 0.8),
                  child: _ArchiveCover(post: post, color: color),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.article_outlined,
                color: AppColors.primaryBrown,
                size: 12,
              ),
              const SizedBox(width: 6),
              Text(
                author,
                style: GoogleFonts.inter(
                  color: AppColors.homeTextDark,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              color: AppColors.homeTextDark,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            excerpt,
            style: GoogleFonts.inter(
              color: AppColors.homeTextLight,
              fontSize: 11,
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    if (post == null) return card;

    return GestureDetector(onTap: () => _openDetail(context), child: card);
  }
}

class _ArchiveCover extends StatelessWidget {
  final PostDto? post;
  final Color color;

  const _ArchiveCover({required this.post, required this.color});

  @override
  Widget build(BuildContext context) {
    if (post != null && post!.hasTitleImage) {
      final imageUrl = post!.resolveTitleImageUrl(ApiConstants.baseUrl);
      return AppCachedImage.sized(
        context: context,
        url: imageUrl,
        logicalWidth: 220,
        logicalHeight: 260,
        fallbackColor: color,
      );
    }
    return Center(
      child: Container(
        width: 140,
        height: 200,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(-5, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Spacer(),
            Text(
              'CHƯA CÓ ẢNH',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.homeTextDark.withValues(alpha: 0.8),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
