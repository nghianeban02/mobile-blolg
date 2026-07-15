import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/widgets/editorial_surface_card.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/features/posts/widgets/post_section_label.dart';
import 'package:mobile/features/profile/widgets/profile_friend_bar.dart';

class UserProfileHeader extends StatelessWidget {
  final UserProfileViewDto profile;
  final int postCount;
  final int reviewCount;
  final VoidCallback onFriendshipChanged;

  const UserProfileHeader({
    super.key,
    required this.profile,
    required this.postCount,
    required this.reviewCount,
    required this.onFriendshipChanged,
  });

  String get _relationLabel {
    switch (profile.relationStatus) {
      case 'FRIENDS':
        return 'Đã kết bạn';
      case 'PENDING_OUTGOING':
        return 'Đã gửi lời mời';
      case 'PENDING_INCOMING':
        return 'Lời mời đang chờ';
      case 'SELF':
        return 'Trang của bạn';
      default:
        return 'Chưa kết bạn';
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = profile.displayName.isNotEmpty
        ? profile.displayName[0].toUpperCase()
        : '?';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PostSectionLabel(text: 'READER PROFILE'),
        const SizedBox(height: 12),
        EditorialSurfaceCard(
          showAccentBar: true,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    color: AppColors.primaryBrown.withValues(alpha: 0.12),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBrown,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.displayName,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            height: 1.05,
                          ),
                        ),
                        if (profile.username.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '@${profile.username}',
                            style: GoogleFonts.inter(
                              color: AppColors.homeTextLight,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          color: AppColors.coverSand.withValues(alpha: 0.7),
                          child: Text(
                            _relationLabel.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: AppColors.primaryBrown,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (profile.bio != null && profile.bio!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  profile.bio!.trim(),
                  style: GoogleFonts.inter(
                    color: AppColors.homeTextLight,
                    fontSize: 14,
                    height: 1.55,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  _StatChip(label: 'Bạn bè', value: '${profile.friendsCount}'),
                  const SizedBox(width: 10),
                  _StatChip(label: 'Bài đăng', value: '$postCount'),
                  const SizedBox(width: 10),
                  _StatChip(label: 'Review', value: '$reviewCount'),
                ],
              ),
              ProfileFriendBar(
                userId: profile.id,
                relationStatus: profile.relationStatus,
                onChanged: onFriendshipChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        color: AppColors.homeBackground,
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: AppColors.homeTextLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
