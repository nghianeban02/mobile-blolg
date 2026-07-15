import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/widgets/editorial_surface_card.dart';
import 'package:mobile/data/auth/auth_repository.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/data/repositories/likes_repository.dart';
import 'package:mobile/features/social/models/discussion_target.dart';

/// Thanh cảm xúc kiểu mạng xã hội — mirror `LikeBar` bản web:
/// 5 emoji chip, bấm để thả/bỏ, chip đang chọn tô đậm, mỗi chip hiện số riêng.
class EngagementLikeBar extends StatefulWidget {
  final DiscussionTarget target;
  final String targetId;

  const EngagementLikeBar({
    super.key,
    required this.target,
    required this.targetId,
  });

  @override
  State<EngagementLikeBar> createState() => _EngagementLikeBarState();
}

class _EngagementLikeBarState extends State<EngagementLikeBar> {
  final _likesRepo = BeBlogLikesRepository();
  final _authRepo = AuthRepository();

  LikeStatusDto? _status;
  bool _busy = false;

  bool get _isReview => widget.target == DiscussionTarget.review;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final result = _isReview
        ? await _likesRepo.status(widget.targetId)
        : await _likesRepo.statusPost(widget.targetId);
    if (!mounted) return;
    if (result.success && result.data != null) {
      setState(() => _status = result.data);
    } else {
      // Guest/lỗi mạng: hiển thị thanh trống thay vì skeleton mãi mãi.
      setState(() => _status = const LikeStatusDto(count: 0, likedByMe: false));
    }
  }

  /// Bấm đúng cảm xúc đang chọn = bỏ; khác = đổi (giống web).
  Future<void> _react(String type) async {
    final token = await _authRepo.getToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      final label = _isReview ? 'review' : 'bài viết';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đăng nhập để thả cảm xúc cho $label.',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_busy) return;

    final current = _status ?? const LikeStatusDto(count: 0, likedByMe: false);
    final currentReaction =
        current.myReaction ?? (current.likedByMe ? 'HEART' : null);
    final String? next = currentReaction == type ? null : type;

    setState(() {
      _busy = true;
      _status = _optimisticApply(current, next);
    });

    final result = next == null
        ? (_isReview
              ? await _likesRepo.unlike(widget.targetId)
              : await _likesRepo.unlikePost(widget.targetId))
        : (_isReview
              ? await _likesRepo.like(widget.targetId, type: next)
              : await _likesRepo.likePost(widget.targetId, type: next));

    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result.success && result.data != null) {
        _status = result.data;
      } else {
        _status = current; // Rollback optimistic khi lỗi.
      }
    });
  }

  LikeStatusDto _optimisticApply(LikeStatusDto current, String? next) {
    final reactions = Map<String, int>.from(current.reactions);
    final mine = current.myReaction ?? (current.likedByMe ? 'HEART' : null);
    if (mine != null) {
      final prev = reactions[mine] ?? 0;
      if (prev <= 1) {
        reactions.remove(mine);
      } else {
        reactions[mine] = prev - 1;
      }
    }
    if (next != null) {
      reactions[next] = (reactions[next] ?? 0) + 1;
    }
    final delta = (next != null ? 1 : 0) - (mine != null ? 1 : 0);
    return LikeStatusDto(
      count: (current.count + delta).clamp(0, 1 << 31),
      likedByMe: next != null,
      myReaction: next,
      reactions: reactions,
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final myReaction =
        status?.myReaction ?? ((status?.likedByMe ?? false) ? 'HEART' : null);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: EditorialSurfaceCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: kReactionTypes.map((type) {
                if (status == null) {
                  // Card luôn nền trắng nên skeleton dùng tông tối cố định.
                  return Container(
                    width: 48,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.homeTextDark.withValues(alpha: 0.05),
                      borderRadius: AppRadius.pill,
                    ),
                  );
                }
                final active = myReaction == type;
                final typeCount = status.reactions[type] ?? 0;
                return _ReactionChip(
                  emoji: kReactionEmoji[type]!,
                  count: typeCount,
                  active: active,
                  busy: _busy,
                  onTap: () => _react(type),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              status == null
                  ? ''
                  : status.count > 0
                  ? '${status.count} lượt bày tỏ cảm xúc'
                  : 'Hãy là người đầu tiên bày tỏ cảm xúc',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.homeTextLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  final String emoji;
  final int count;
  final bool active;
  final bool busy;
  final VoidCallback onTap;

  const _ReactionChip({
    required this.emoji,
    required this.count,
    required this.active,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Nằm trong EditorialSurfaceCard nền trắng nên dùng tông tối cố định.
    const onSurface = AppColors.homeTextDark;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: busy ? 0.6 : 1,
      child: Material(
        color: active
            ? AppColors.primaryBrown.withValues(alpha: 0.15)
            : Colors.transparent,
        shape: StadiumBorder(
          side: BorderSide(
            color: active
                ? AppColors.primaryBrown.withValues(alpha: 0.4)
                : onSurface.withValues(alpha: 0.08),
            width: active ? 1.6 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: busy ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  duration: const Duration(milliseconds: 150),
                  scale: active ? 1.2 : 1,
                  child: Text(emoji, style: const TextStyle(fontSize: 16)),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    '$count',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active
                          ? AppColors.primaryBrown
                          : AppColors.homeTextLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
