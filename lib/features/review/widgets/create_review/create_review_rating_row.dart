import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';

class CreateReviewRatingRow extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onRatingChanged;

  const CreateReviewRatingRow({
    super.key,
    required this.rating,
    required this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RATING',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: AppColors.homeTextDark.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(5, (index) {
            final value = index + 1;
            final filled = value <= rating;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => onRatingChanged(value),
                borderRadius: BorderRadius.circular(4),
                child: Icon(
                  filled ? Icons.star : Icons.star_border,
                  color: AppColors.primaryBrown,
                  size: 32,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Text(
          '$rating / 5 stars',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.homeTextLight,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
