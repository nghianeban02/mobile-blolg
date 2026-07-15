import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/widgets/editorial_surface_card.dart';

/// Shown when [UserProfileViewDto.canViewFeed] is false.
class ProfilePrivateFeedBanner extends StatelessWidget {
  const ProfilePrivateFeedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: EditorialSurfaceCard(
        showAccentBar: true,
        accentColor: AppColors.coverSand,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nội dung riêng tư',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Gửi lời mời kết bạn để xem bài đăng và review của độc giả này '
              '(trừ khi họ để feed ở chế độ công khai).',
              style: GoogleFonts.inter(
                color: AppColors.homeTextLight,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
