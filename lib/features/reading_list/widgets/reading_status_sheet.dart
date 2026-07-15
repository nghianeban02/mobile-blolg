import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';

const readingListStatuses = [
  ('want_to_read', 'Want to read'),
  ('reading', 'Currently reading'),
  ('finished', 'Finished'),
];

Future<String?> showReadingStatusSheet(
  BuildContext context, {
  required String currentStatus,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.homeBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Reading status',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.homeTextDark,
                ),
              ),
              const SizedBox(height: 16),
              ...readingListStatuses.map((entry) {
                final selected = entry.$1 == currentStatus;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    entry.$2,
                    style: GoogleFonts.inter(
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: AppColors.homeTextDark,
                    ),
                  ),
                  trailing: selected
                      ? const Icon(
                          Icons.check,
                          color: AppColors.primaryBrown,
                          size: 20,
                        )
                      : null,
                  onTap: () => Navigator.pop(context, entry.$1),
                );
              }),
            ],
          ),
        ),
      );
    },
  );
}
