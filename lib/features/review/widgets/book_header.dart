import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/data/models/dtos.dart';

class BookHeader extends StatelessWidget {
  final ReviewDto review;

  const BookHeader({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book Cover Simulation
          Container(
            width: double.infinity,
            height: 420,
            decoration: BoxDecoration(
              color: const Color(0xFF0F3144), // Dark blue like the mockup
              border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Inner glowing window simulation
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withValues(alpha: 0.4),
                          blurRadius: 50,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.grid_4x4,
                        color: const Color(0xFF0F3144).withValues(alpha: 0.3),
                        size: 100,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Text(
                        'THE MIDNIGHT LIBRARY',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'A NOVEL',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 8,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Buy Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBrown,
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'BUY NOW',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.north_east, size: 14),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          // Metadata Row (Date & Publisher)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '5/18/21',
                style: GoogleFonts.inter(
                  color: AppColors.homeTextLight,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'MacMillan',
                style: GoogleFonts.inter(
                  color: AppColors.homeTextLight,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            color: AppColors.homeTextDark.withValues(alpha: 0.1),
            height: 1,
          ),
          const SizedBox(height: 16),

          // Tags
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  review.status.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Text(
                  'FANTASY',
                  style: GoogleFonts.inter(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                    fontSize: 8,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          // Title
          Text(
            review.title,
            style: GoogleFonts.playfairDisplay(
              color: AppColors.homeTextDark,
              fontSize: 48,
              height: 1.05,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          // Author
          Text(
            'by Matt Haig',
            style: GoogleFonts.playfairDisplay(
              fontStyle: FontStyle.italic,
              color: AppColors.homeTextLight,
              fontSize: 20,
            ),
          ),

          const SizedBox(height: 24),
          // Ratings
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: List.generate(5, (index) {
                  final filled = index < review.rating.clamp(0, 5);
                  return Padding(
                    padding: const EdgeInsets.only(right: 2.0),
                    child: Icon(
                      filled ? Icons.star : Icons.star_border,
                      color: AppColors.primaryBrown,
                      size: 16,
                    ),
                  );
                }),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '4.8 /',
                    style: GoogleFonts.inter(
                      color: AppColors.homeTextDark,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '5.0',
                    style: GoogleFonts.inter(
                      color: AppColors.homeTextLight,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Container(
                width: 1,
                height: 20,
                color: AppColors.homeTextDark.withValues(alpha: 0.2),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '11,467',
                    style: GoogleFonts.inter(
                      color: AppColors.homeTextDark,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Reviews',
                    style: GoogleFonts.inter(
                      color: AppColors.homeTextLight,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
