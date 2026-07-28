import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_typography.dart';

/// Uppercase section kicker — web tracking-widest eyebrow style.
class PostSectionLabel extends StatelessWidget {
  final String text;

  const PostSectionLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTypography.sectionEyebrow(context),
    );
  }
}
