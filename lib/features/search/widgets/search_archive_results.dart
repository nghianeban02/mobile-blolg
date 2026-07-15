import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/search/archive_search_index.dart';
import 'package:mobile/core/utils/text_excerpt.dart';
import 'package:mobile/features/posts/screens/post_detail_screen.dart';
import 'package:mobile/features/reading_list/screens/library_book_detail_screen.dart';
import 'package:mobile/features/review/screens/book_detail_screen.dart';

class SearchArchiveResults extends StatelessWidget {
  final List<ArchiveSearchHit> hits;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;

  const SearchArchiveResults({
    super.key,
    required this.hits,
    this.isLoading = false,
    this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primaryBrown),
        ),
      );
    }
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Text(
              error!,
              style: GoogleFonts.inter(color: AppColors.error, fontSize: 13),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      );
    }
    if (hits.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'No matches in the archive. Try another keyword.',
          style: GoogleFonts.inter(
            color: AppColors.homeTextLight,
            fontSize: 13,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < hits.length; i++) ...[
          if (i > 0) const SizedBox(height: 32),
          _SearchHitTile(hit: hits[i]),
        ],
      ],
    );
  }
}

class _SearchHitTile extends StatelessWidget {
  final ArchiveSearchHit hit;

  const _SearchHitTile({required this.hit});

  String get _tag {
    switch (hit.type) {
      case ArchiveSearchHitType.post:
        return 'POST';
      case ArchiveSearchHitType.review:
        return 'REVIEW';
      case ArchiveSearchHitType.book:
        return 'BOOK';
    }
  }

  void _open(BuildContext context) {
    switch (hit.type) {
      case ArchiveSearchHitType.post:
        final post = hit.post;
        if (post == null) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PostDetailScreen(postId: post.id, initialPost: post),
          ),
        );
      case ArchiveSearchHitType.review:
        final review = hit.review;
        if (review == null) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                BookDetailScreen(reviewId: review.id, initialReview: review),
          ),
        );
      case ArchiveSearchHitType.book:
        final book = hit.book;
        if (book == null) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                LibraryBookDetailScreen(bookId: book.id, initialBook: book),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => _open(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _tag,
                style: GoogleFonts.inter(
                  color: AppColors.primaryBrown,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                hit.title,
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.homeTextDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                hit.subtitle,
                style: GoogleFonts.inter(
                  color: AppColors.homeTextLight,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (hit.excerpt.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  textExcerpt(hit.excerpt, maxLength: 140),
                  style: GoogleFonts.inter(
                    color: AppColors.homeTextLight,
                    fontSize: 12,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Open →',
                style: GoogleFonts.inter(
                  color: AppColors.primaryBrown,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
