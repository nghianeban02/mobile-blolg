import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';

/// Confirm dialog kiểu web (ConfirmDialog): surface bo góc lớn,
/// overlay tối + nút pill outline (Hủy) / filled (Xác nhận).
Future<bool> showEditorialConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Xác nhận',
  String cancelLabel = 'Hủy',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final confirmColor = destructive
          ? AppColors.error
          : (isDark ? AppColors.darkAccent : AppColors.primaryBrown);

      return AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
        ),
        content: Text(message, style: GoogleFonts.inter(height: 1.5)),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              shape: const StadiumBorder(),
              side: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.borderStrong,
              ),
              foregroundColor: isDark
                  ? AppColors.darkForeground
                  : AppColors.homeTextDark,
            ),
            child: Text(cancelLabel, style: GoogleFonts.inter()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              shape: const StadiumBorder(),
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
            ),
            child: Text(
              confirmLabel,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
