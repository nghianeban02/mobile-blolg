import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/widgets/editorial_surface_card.dart';
import 'package:mobile/data/models/dtos.dart';

class FriendUserTile extends StatelessWidget {
  final UserPublicDto user;
  final VoidCallback onTap;
  final Widget? trailing;

  const FriendUserTile({
    super.key,
    required this.user,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final initial = user.displayName.isNotEmpty
        ? user.displayName[0].toUpperCase()
        : '?';

    return EditorialSurfaceCard(
      onTap: onTap,
      showAccentBar: true,
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryBrown.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              initial,
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryBrown,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '@${user.username}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.homeTextLight,
                    letterSpacing: 0.3,
                  ),
                ),
                if (user.bio != null && user.bio!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    user.bio!.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppColors.homeTextLight,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          trailing ??
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.primaryBrown,
              ),
        ],
      ),
    );
  }
}
