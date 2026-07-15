import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/features/reading_list/utils/library_book_style.dart';
import 'package:mobile/features/reading_list/widgets/library_book_cover.dart';

class CurrentlyReadingCard extends StatelessWidget {
  final BookDto? book;
  final ReviewDto? review;
  final VoidCallback? onOpenBook;
  final VoidCallback? onReadReview;

  const CurrentlyReadingCard({
    super.key,
    this.book,
    this.review,
    this.onOpenBook,
    this.onReadReview,
  });

  @override
  Widget build(BuildContext context) {
    final title = book?.title ?? 'The\nArchitecture of\nSilence';
    final description = book != null
        ? LibraryBookStyle.description(book!, maxLines: 4)
        : 'An exploration into the spaces\nbetween words, examining how\nsilence serves as the ultimate...';
    final meta = book != null
        ? LibraryBookStyle.metaLine(book!)
        : 'PHILOSOPHY  •  2024';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: book != null ? onOpenBook : null,
              borderRadius: AppRadius.card,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadius.card,
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.soft,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: double.infinity,
                        height: 280,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: AppColors.border),
                          boxShadow: AppShadows.soft,
                        ),
                        child: book != null
                            ? Center(
                                child: LibraryBookCover(
                                  book: book!,
                                  fallbackColor: LibraryBookStyle.coverColor(0),
                                  width: 180,
                                  height: 240,
                                ),
                              )
                            : Center(
                                child: Text(
                                  'M I N I M A L I S T',
                                  style: GoogleFonts.inter(
                                    color: AppColors.homeTextLight,
                                    fontSize: 10,
                                    letterSpacing: 4,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      meta,
                      style: GoogleFonts.inter(
                        color: AppColors.homeTextDark,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _formatTitle(title),
                      style: GoogleFonts.playfairDisplay(
                        color: AppColors.homeTextDark,
                        fontSize: 28,
                        height: 1.1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      description,
                      style: GoogleFonts.inter(
                        color: AppColors.homeTextLight,
                        fontSize: 12,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Reading Progress',
                          style: GoogleFonts.inter(
                            color: AppColors.homeTextDark,
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          book != null ? '—' : '64%',
                          style: GoogleFonts.inter(
                            color: AppColors.homeTextDark,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Stack(
                      children: [
                        Container(
                          height: 2,
                          width: double.infinity,
                          color: Colors.grey.shade200,
                        ),
                        if (book == null)
                          FractionallySizedBox(
                            widthFactor: 0.64,
                            child: Container(
                              height: 2,
                              color: AppColors.primaryBrown,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBrown,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              'RESUME\nREADING',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: review != null ? onReadReview : null,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.homeTextDark,
                              side: const BorderSide(
                                color: AppColors.borderStrong,
                              ),
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              'READ\nREVIEW',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -12,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.2),
                borderRadius: AppRadius.pill,
              ),
              child: Text(
                book != null ? 'IN YOUR LIBRARY' : 'CURRENTLY READING',
                style: GoogleFonts.inter(
                  color: Colors.green.shade800,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTitle(String title) {
    if (title.contains('\n')) return title;
    final words = title.split(' ');
    if (words.length <= 3) return title;
    final mid = (words.length / 2).ceil();
    return '${words.sublist(0, mid).join(' ')}\n${words.sublist(mid).join(' ')}';
  }
}
