import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/brand/site_brand.dart';
import 'package:mobile/core/constants/app_colors.dart';

// ----------------------------------------------------------------------
// SEARCH HEADER
// ----------------------------------------------------------------------
class SearchHeader extends StatelessWidget {
  final TextEditingController? controller;

  const SearchHeader({super.key, this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const EditorialPageHeader(
          title: 'Tìm kiếm',
          subtitle: 'Bài viết, review và sách trong kho lưu trữ Nook.',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: controller,
          style: GoogleFonts.inter(
            color: AppColors.homeTextDark,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: 'Tìm trong kho lưu trữ…',
            hintStyle: GoogleFonts.inter(
              color: AppColors.homeTextLight.withValues(alpha: 0.7),
              fontSize: 16,
            ),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 12.0, right: 12.0),
              child: Icon(
                Icons.search_rounded,
                color: AppColors.homeTextLight,
                size: 24,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 24),
            filled: true,
            fillColor: AppColors.homeTextDark.withValues(alpha: 0.04),
            border: OutlineInputBorder(
              borderRadius: AppRadius.input,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.input,
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.input,
              borderSide: BorderSide(
                color: AppColors.primaryBrown.withValues(alpha: 0.45),
                width: 1.5,
              ),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'CHỈ MỤC LƯU TRỮ',
          style: GoogleFonts.inter(
            color: AppColors.homeTextLight,
            fontSize: 8,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------------
// TRENDING COLLECTIONS
// ----------------------------------------------------------------------
class TrendingCollections extends StatelessWidget {
  final void Function(String keyword)? onCollectionTap;

  const TrendingCollections({super.key, this.onCollectionTap});

  @override
  Widget build(BuildContext context) {
    final collections = ['fiction', 'philosophy', 'design', 'essay', 'review'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TRENDING COLLECTIONS',
          style: GoogleFonts.inter(
            color: AppColors.homeTextLight,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        ...collections.map(
          (c) => Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: InkWell(
              onTap: onCollectionTap != null ? () => onCollectionTap!(c) : null,
              child: Text(
                c[0].toUpperCase() + c.substring(1),
                style: GoogleFonts.inter(
                  color: AppColors.homeTextDark.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------------
// LIBRARIAN'S NOTE
// ----------------------------------------------------------------------
class LibrariansNote extends StatelessWidget {
  const LibrariansNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The Librarian\'s Note',
            style: GoogleFonts.playfairDisplay(
              color: AppColors.homeTextDark,
              fontSize: 14,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Our search algorithm prioritizes editorial\ndepth over raw popularity. Discover\nessays that challenge the narrative.',
            style: GoogleFonts.inter(
              color: AppColors.homeTextDark.withValues(alpha: 0.8),
              fontSize: 12,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------
// SEARCH RESULT CARD
// ----------------------------------------------------------------------
enum SearchResultButtonStyle { filledBlock, textLink }

enum FloatingTagPosition { topRight, bottomLeft, none }

class SearchResultCard extends StatelessWidget {
  final Color coverColor;
  final String bookTitleSimulation;
  final Color tagColor;
  final String tagText;
  final String dateText;
  final String title;
  final String excerpt;
  final String author;
  final SearchResultButtonStyle buttonStyleType;
  final String buttonText;
  final String? floatingTagText;
  final FloatingTagPosition floatingTagPosition;
  final Color? floatingTagColor;
  final Color? floatingTagTextColor;

  const SearchResultCard({
    super.key,
    required this.coverColor,
    required this.bookTitleSimulation,
    required this.tagColor,
    required this.tagText,
    required this.dateText,
    required this.title,
    required this.excerpt,
    required this.author,
    required this.buttonStyleType,
    required this.buttonText,
    this.floatingTagText,
    this.floatingTagPosition = FloatingTagPosition.none,
    this.floatingTagColor,
    this.floatingTagTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Floating Tag (if applicable)
        if (floatingTagPosition == FloatingTagPosition.topRight &&
            floatingTagText != null)
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color:
                    floatingTagColor ??
                    AppColors.success.withValues(alpha: 0.2),
                borderRadius: AppRadius.pill,
              ),
              child: Text(
                floatingTagText!,
                style: GoogleFonts.inter(
                  color: floatingTagTextColor ?? Colors.green.shade800,
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),

        // Book Mockup Background
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              height: 380,
              decoration: BoxDecoration(
                color: Colors.black.withValues(
                  alpha: 0.04,
                ), // soft grey background
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Center(
                child: Container(
                  width: 200,
                  height: 280,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: coverColor,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(-8, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      bookTitleSimulation,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.black.withValues(alpha: 0.6),
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Left Floating Tag
            if (floatingTagPosition == FloatingTagPosition.bottomLeft &&
                floatingTagText != null)
              Positioned(
                bottom: -8,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        floatingTagColor ??
                        AppColors.success.withValues(alpha: 0.2),
                    borderRadius: AppRadius.pill,
                  ),
                  child: Text(
                    floatingTagText!,
                    style: GoogleFonts.inter(
                      color: floatingTagTextColor ?? Colors.green.shade800,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 24),

        // Tags Row
        Row(
          children: [
            Text(
              tagText,
              style: GoogleFonts.inter(
                color: tagColor,
                fontSize: 8,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 24,
              height: 1,
              color: Colors.black.withValues(alpha: 0.1),
            ),
            const SizedBox(width: 8),
            Text(
              dateText,
              style: GoogleFonts.inter(
                color: AppColors.homeTextLight,
                fontSize: 8,
                letterSpacing: 1,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        // Title
        Text(
          title,
          style: GoogleFonts.playfairDisplay(
            color: AppColors.homeTextDark,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            height: 1.1,
          ),
        ),

        const SizedBox(height: 16),
        // Excerpt
        Text(
          excerpt,
          style: GoogleFonts.inter(
            color: AppColors.homeTextDark.withValues(alpha: 0.8),
            fontSize: 13,
            height: 1.6,
          ),
        ),

        const SizedBox(height: 24),
        // Footer (Author & Button)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'by $author',
              style: GoogleFonts.inter(
                color: AppColors.homeTextLight,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
            _buildButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildButton() {
    if (buttonStyleType == SearchResultButtonStyle.filledBlock) {
      return ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBrown,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: Text(
          buttonText,
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      );
    } else {
      return InkWell(
        onTap: () {},
        child: Text(
          buttonText,
          style: GoogleFonts.inter(
            color: const Color(0xFFD3554A), // Reddish brown
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
  }
}
