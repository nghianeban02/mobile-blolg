import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/widgets/editorial_ui.dart';
import 'package:mobile/core/widgets/editorial_surface_card.dart';

/// Ô nhập bình luận — filled rounded field trong surface card.
class CommentComposerBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String submitLabel;
  final VoidCallback? onSubmit;
  final VoidCallback? onCancel;
  final bool submitting;
  final int maxLines;
  final bool compact;

  const CommentComposerBar({
    super.key,
    required this.controller,
    this.hint = 'Viết bình luận…',
    this.submitLabel = 'Gửi',
    this.onSubmit,
    this.onCancel,
    this.submitting = false,
    this.maxLines = 2,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final field = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          compact ? 'TRẢ LỜI' : 'BÌNH LUẬN',
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.4,
            color: AppColors.homeTextLight,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          minLines: 1,
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.45,
            color: AppColors.homeTextDark,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.homeTextLight,
            ),
            filled: true,
            fillColor: AppColors.homeTextDark.withValues(alpha: 0.04),
            border: OutlineInputBorder(
              borderRadius: AppRadius.input,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.input,
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.input,
              borderSide: BorderSide(
                color: AppColors.primaryBrown.withValues(alpha: 0.45),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (onCancel != null) ...[
              EditorialLinkButton(
                label: 'Hủy',
                onPressed: submitting ? null : onCancel,
              ),
              const SizedBox(width: 12),
            ],
            EditorialLinkButton(
              label: submitting ? 'Đang gửi…' : submitLabel,
              onPressed: submitting ? null : onSubmit,
              emphasized: true,
            ),
          ],
        ),
      ],
    );

    if (compact) {
      return Padding(padding: const EdgeInsets.only(top: 4), child: field);
    }

    return EditorialSurfaceCard(
      showAccentBar: true,
      accentColor: AppColors.primaryBrown,
      padding: const EdgeInsets.all(14),
      child: field,
    );
  }
}
