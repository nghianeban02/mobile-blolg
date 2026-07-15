import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/features/reading_list/utils/library_book_style.dart';
import 'package:mobile/features/reading_list/widgets/library_book_cover.dart';

class ReadingListItem extends StatelessWidget {
  final BookDto book;
  final int listIndex;
  final ReviewDto? review;
  final VoidCallback? onTap;
  final VoidCallback? onReadReview;

  const ReadingListItem({
    super.key,
    required this.book,
    required this.listIndex,
    this.review,
    this.onTap,
    this.onReadReview,
  });

  @override
  Widget build(BuildContext context) {
    final coverColor = LibraryBookStyle.coverColor(listIndex);
    final tag = LibraryBookStyle.catalogTag(book, listIndex);
    final tagColor = LibraryBookStyle.tagColor(listIndex);
    final hasReview = review != null;
    final rating = review?.rating ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: double.infinity,
                      height: 380,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: LibraryBookCover(
                          book: book,
                          fallbackColor: coverColor,
                          width: 220,
                          height: 300,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(
                        tag,
                        style: GoogleFonts.inter(
                          color: tagColor,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      if (hasReview) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.1),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Review',
                            style: GoogleFonts.inter(
                              color: AppColors.homeTextDark,
                              fontSize: 8,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    book.title,
                    style: GoogleFonts.playfairDisplay(
                      color: AppColors.homeTextDark,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    LibraryBookStyle.description(book),
                    style: GoogleFonts.inter(
                      color: AppColors.homeTextLight,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onReadReview,
                behavior: HitTestBehavior.opaque,
                child: Text(
                  hasReview ? 'Read Review' : 'View details',
                  style: GoogleFonts.inter(
                    color: AppColors.primaryBrown,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (rating > 0)
                Row(
                  children: List.generate(
                    rating.clamp(0, 5),
                    (_) => const Padding(
                      padding: EdgeInsets.only(left: 4.0),
                      child: Icon(
                        Icons.star,
                        color: AppColors.primaryBrown,
                        size: 12,
                      ),
                    ),
                  ),
                )
              else
                const Icon(
                  Icons.bookmark_outline,
                  color: AppColors.homeTextDark,
                  size: 16,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
