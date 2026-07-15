import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';

class RecommendedList extends StatelessWidget {
  const RecommendedList({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommended From\nThe Archive',
            style: GoogleFonts.playfairDisplay(
              color: AppColors.homeTextDark,
              fontSize: 28,
              height: 1.1,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 32),
          _buildRecommendedBook(
            coverColor: const Color(0xFF143F37), // Dark forest green
            tag: 'FICTION',
            title: 'The Starless Sea',
            author: 'Erin Morgenstern',
          ),
          const SizedBox(height: 48),
          _buildRecommendedBook(
            coverColor: Colors.grey.shade300,
            tag: 'PHILOSOPHY',
            title: 'Man\'s Search For Meaning',
            author: 'Viktor Frankl',
            isTextDark: true,
          ),
          const SizedBox(height: 48),
          _buildRecommendedBook(
            coverColor: AppColors.coverSand,
            tag: 'CONTEMPORARY',
            title: 'Before The Coffee Gets Cold',
            author: 'Toshikazu Kawaguchi',
            isTextDark: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedBook({
    required Color coverColor,
    required String tag,
    required String title,
    required String author,
    bool isTextDark = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 380,
          color: coverColor.withValues(alpha: 0.3), // Background tone
          child: Center(
            child: Container(
              width: 160,
              height: 240,
              decoration: BoxDecoration(
                color: coverColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 15,
                    offset: const Offset(-5, 5),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'BOOK COVER\nSIMULATION',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: isTextDark ? Colors.black54 : Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          tag,
          style: GoogleFonts.inter(
            color: AppColors.primaryBrown,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.playfairDisplay(
            color: AppColors.homeTextDark,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          author,
          style: GoogleFonts.inter(
            color: AppColors.homeTextLight,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
