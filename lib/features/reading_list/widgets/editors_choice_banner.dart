import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/features/reading_list/utils/library_book_style.dart';

class EditorsChoiceBanner extends StatelessWidget {
  final BookDto? book;
  final VoidCallback? onTap;

  const EditorsChoiceBanner({super.key, this.book, this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = book?.title ?? 'The Paper Archive';
    final description = book != null
        ? LibraryBookStyle.description(book!)
        : 'A curated list of independent journals and\ntheir impact on digital typography.';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Material(
        color: const Color(0xFFF9F6F0),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.arrow_back_ios,
                      size: 8,
                      color: AppColors.primaryBrown,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'EDITOR\'S CHOICE',
                      style: GoogleFonts.inter(
                        color: AppColors.primaryBrown,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    color: AppColors.homeTextDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    color: AppColors.homeTextLight,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      book != null ? 'View in catalog' : 'Explore Collection',
                      style: GoogleFonts.inter(
                        color: AppColors.primaryBrown,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward,
                      size: 12,
                      color: AppColors.primaryBrown,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
