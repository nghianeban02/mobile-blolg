import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_palette.dart';

/// Star row — mirror web `StarRating`.
class EditorialStarRating extends StatelessWidget {
  final int rating;
  final double size;

  const EditorialStarRating({super.key, required this.rating, this.size = 14});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final clamped = rating.clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Icon(
            Icons.star_rounded,
            size: size,
            color: i < clamped ? p.accent : p.muted.withValues(alpha: 0.3),
          ),
        );
      }),
    );
  }
}
