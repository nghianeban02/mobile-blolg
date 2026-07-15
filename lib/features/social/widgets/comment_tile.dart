import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/utils/format_datetime.dart';
import 'package:mobile/core/widgets/editorial_surface_card.dart';
import 'package:mobile/core/widgets/editorial_ui.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/features/social/widgets/comment_composer_bar.dart';

/// Một bình luận hoặc trả lời — card editorial, có ngày giờ.
class CommentTile extends StatelessWidget {
  final CommentDto comment;
  final bool isReply;
  final int? replyCount;
  final bool editing;
  final bool showReplyComposer;
  final TextEditingController? editController;
  final TextEditingController? replyController;
  final String? replyingToLabel;
  final bool submitting;
  final bool canManage;
  final VoidCallback? onReply;
  final VoidCallback? onCancelReply;
  final VoidCallback? onSubmitReply;
  final VoidCallback? onEdit;
  final VoidCallback? onCancelEdit;
  final VoidCallback? onSaveEdit;
  final VoidCallback? onDelete;

  const CommentTile({
    super.key,
    required this.comment,
    this.isReply = false,
    this.replyCount,
    this.editing = false,
    this.showReplyComposer = false,
    this.editController,
    this.replyController,
    this.replyingToLabel,
    this.submitting = false,
    this.canManage = false,
    this.onReply,
    this.onCancelReply,
    this.onSubmitReply,
    this.onEdit,
    this.onCancelEdit,
    this.onSaveEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final author = comment.username?.trim().isNotEmpty == true
        ? comment.username!.trim()
        : 'Reader';
    final when = formatCommentDateTime(comment.createdAt ?? comment.updatedAt);

    final body = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EditorialAvatarInitial(
          name: author,
          size: isReply ? 24 : 30,
          backgroundColor: isReply
              ? AppColors.coverSand.withValues(alpha: 0.5)
              : AppColors.coverTeal.withValues(alpha: 0.35),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          author,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.homeTextDark,
                          ),
                        ),
                        if (when.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              when,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: AppColors.homeTextLight,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!editing && onReply != null)
                    EditorialLinkButton(
                      label: 'Trả lời',
                      onPressed: submitting ? null : onReply,
                    ),
                ],
              ),
              if (replyCount != null && replyCount! > 0) ...[
                const SizedBox(height: 4),
                EditorialStatusChip(
                  label: '$replyCount trả lời',
                  backgroundColor: AppColors.primaryBrown.withValues(
                    alpha: 0.08,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              if (editing && editController != null) ...[
                CommentComposerBar(
                  controller: editController!,
                  hint: 'Sửa nội dung…',
                  submitLabel: 'Lưu',
                  submitting: submitting,
                  onSubmit: onSaveEdit,
                  onCancel: onCancelEdit,
                ),
              ] else ...[
                Text(
                  comment.content,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.55,
                    color: AppColors.homeTextDark.withValues(alpha: 0.9),
                  ),
                ),
                if (canManage) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      EditorialLinkButton(label: 'Sửa', onPressed: onEdit),
                      const SizedBox(width: 8),
                      EditorialLinkButton(
                        label: 'Xóa',
                        onPressed: onDelete,
                        destructive: true,
                      ),
                    ],
                  ),
                ],
              ],
              if (showReplyComposer &&
                  replyController != null &&
                  replyingToLabel != null) ...[
                const SizedBox(height: 10),
                CommentComposerBar(
                  controller: replyController!,
                  hint: 'Trả lời $replyingToLabel…',
                  submitLabel: 'Gửi',
                  submitting: submitting,
                  onSubmit: onSubmitReply,
                  onCancel: onCancelReply,
                  compact: true,
                ),
              ],
            ],
          ),
        ),
      ],
    );

    return EditorialSurfaceCard(
      showAccentBar: true,
      accentColor: isReply ? AppColors.coverSand : AppColors.primaryBrown,
      padding: const EdgeInsets.all(12),
      margin: EdgeInsets.zero,
      child: body,
    );
  }
}
