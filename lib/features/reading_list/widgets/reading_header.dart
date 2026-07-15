import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';

class ReadingHeader extends StatelessWidget {
  const ReadingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'The\nReading\nArchive',
            style: GoogleFonts.playfairDisplay(
              color: AppColors.homeTextDark,
              fontSize: 44,
              height: 1.05,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'A curated collection of your literary\njourneys. From half-finished epics to\nthe next great discovery.',
            style: GoogleFonts.playfairDisplay(
              color: AppColors.homeTextLight,
              fontSize: 16,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 40),

          // Tabs
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTab('Library', isActive: true),
              _buildTab('To Read'),
              _buildTab('Reading'),
              _buildTab('Finished'),
            ],
          ),

          const SizedBox(height: 32),
          // Sort By
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sort by: Recent',
                  style: GoogleFonts.inter(
                    color: AppColors.homeTextDark,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 12,
                  color: AppColors.homeTextLight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String text, {bool isActive = false}) {
    return Column(
      children: [
        Text(
          text,
          style: GoogleFonts.inter(
            color: isActive
                ? AppColors.homeTextDark
                : AppColors.homeTextLight.withValues(alpha: 0.7),
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        if (isActive)
          Container(height: 2, width: 32, color: AppColors.primaryBrown)
        else
          const SizedBox(height: 2, width: 32),
      ],
    );
  }
}
