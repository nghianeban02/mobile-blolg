import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/widgets/editorial_surface_card.dart';
import 'package:mobile/features/friends/screens/friends_screen.dart';
import 'package:mobile/features/posts/widgets/post_section_label.dart';

/// Shortcut on Home → [FriendsScreen].
class EditorialCircleEntry extends StatelessWidget {
  const EditorialCircleEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: EditorialSurfaceCard(
        showAccentBar: true,
        accentColor: AppColors.coverTeal,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const FriendsScreen()),
          );
        },
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.coverTeal.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.people_outline,
                color: AppColors.primaryBrown,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PostSectionLabel(text: 'SOCIAL'),
                  const SizedBox(height: 8),
                  Text(
                    'Editorial\ncircle',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kết bạn · lời mời · trang độc giả',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.homeTextLight,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppColors.primaryBrown,
            ),
          ],
        ),
      ),
    );
  }
}
