import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/features/reading_list/utils/library_book_style.dart';
import 'package:mobile/features/reading_list/widgets/library_book_cover.dart';

/// Full-width cover hero for book catalog detail.
class BookDetailCoverHero extends StatelessWidget {
  final BookDto book;
  final int colorIndex;

  const BookDetailCoverHero({
    super.key,
    required this.book,
    this.colorIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = LibraryBookStyle.coverColor(colorIndex);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(color: fallback.withValues(alpha: 0.25)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Center(
              child: Container(
                decoration: BoxDecoration(boxShadow: AppShadows.lift),
                child: LibraryBookCover(
                  book: book,
                  fallbackColor: fallback,
                  width: 200,
                  height: 280,
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryBrown.withValues(alpha: 0.12),
                borderRadius: AppRadius.pill,
              ),
              child: Text(
                LibraryBookStyle.catalogTag(book, colorIndex),
                style: const TextStyle(
                  color: AppColors.primaryBrown,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
