import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';

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
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.homeBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      title: Text(
        title,
        style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
      ),
      content: Text(message, style: GoogleFonts.inter(height: 1.5)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel, style: GoogleFonts.inter()),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(
            foregroundColor: destructive
                ? AppColors.error
                : AppColors.primaryBrown,
          ),
          child: Text(
            confirmLabel,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
