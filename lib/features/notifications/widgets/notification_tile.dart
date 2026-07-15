import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/widgets/editorial_surface_card.dart';
import 'package:mobile/data/models/dtos.dart';

class NotificationTile extends StatelessWidget {
  final NotificationDto notification;
  final VoidCallback onTap;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  IconData get _icon {
    switch (notification.type) {
      case NotificationType.reviewLike:
      case NotificationType.postLike:
        return Icons.favorite_outline;
      case NotificationType.reviewComment:
      case NotificationType.postComment:
        return Icons.chat_bubble_outline;
      case NotificationType.reviewCommentReply:
      case NotificationType.postCommentReply:
        return Icons.reply_outlined;
      case NotificationType.friendRequest:
        return Icons.person_add_outlined;
      case NotificationType.friendRequestAccepted:
        return Icons.people_outline;
      case NotificationType.unknown:
        return Icons.notifications_outlined;
    }
  }

  Color get _accent {
    switch (notification.type) {
      case NotificationType.friendRequest:
      case NotificationType.friendRequestAccepted:
        return AppColors.coverTeal;
      default:
        return AppColors.primaryBrown;
    }
  }

  String? _formatTime(DateTime? date) {
    if (date == null) return null;
    final local = date.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inHours < 1) return '${diff.inMinutes} phút';
    if (diff.inDays < 1) return '${diff.inHours} giờ';
    if (diff.inDays < 7) return '${diff.inDays} ngày';
    return '${local.day}/${local.month}/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final timeLabel = _formatTime(notification.createdAt);

    return EditorialSurfaceCard(
      onTap: onTap,
      showAccentBar: true,
      accentColor: notification.read ? AppColors.coverSand : _accent,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(_icon, size: 20, color: _accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.message,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.45,
                          fontWeight: notification.read
                              ? FontWeight.w400
                              : FontWeight.w600,
                          color: AppColors.homeTextDark,
                        ),
                      ),
                    ),
                    if (!notification.read)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                if (timeLabel != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    timeLabel,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.homeTextLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
