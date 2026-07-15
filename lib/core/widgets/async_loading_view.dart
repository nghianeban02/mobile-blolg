import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/widgets/editorial_surface_card.dart';
import 'package:mobile/core/widgets/editorial_ui.dart';

/// Loading / lỗi inline cho section async.
class AsyncLoadingView extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const AsyncLoadingView({
    super.key,
    required this.isLoading,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primaryBrown,
            ),
          ),
        ),
      );
    }
    if (errorMessage == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: EditorialSurfaceCard(
        showAccentBar: true,
        accentColor: AppColors.error,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.5,
                color: AppColors.homeTextDark,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              EditorialLinkButton(
                label: 'Thử lại',
                onPressed: onRetry,
                emphasized: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
