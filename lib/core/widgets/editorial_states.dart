import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/i18n/locale_controller.dart';
import 'package:mobile/core/theme/app_palette.dart';
import 'package:mobile/core/theme/app_spacing.dart';
import 'package:mobile/core/theme/app_typography.dart';
import 'package:mobile/core/widgets/editorial_button.dart';

enum EditorialEmptyIcon {
  feed,
  books,
  friends,
  search,
  notifications,
  defaultIcon,
}

/// Empty state — mirror web `EmptyState`.
class EditorialEmptyState extends StatelessWidget {
  final String? title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EditorialEmptyIcon icon;

  const EditorialEmptyState({
    super.key,
    this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.icon = EditorialEmptyIcon.defaultIcon,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.pageX),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
      decoration: BoxDecoration(
        color: p.emptyWash,
        borderRadius: AppRadius.card,
        border: Border.all(color: p.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: p.accentSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(_iconData, size: 22, color: p.accent),
          ),
          if (title != null && title!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              title!,
              textAlign: TextAlign.center,
              style: AppTypography.sectionTitle(context).copyWith(fontSize: 18),
            ),
          ],
          SizedBox(height: title != null ? 8 : 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.body(context),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 24),
            EditorialButton(label: actionLabel!, onPressed: onAction),
          ],
        ],
      ),
    );
  }

  IconData get _iconData => switch (icon) {
    EditorialEmptyIcon.feed => Icons.menu_book_outlined,
    EditorialEmptyIcon.books => Icons.auto_stories_outlined,
    EditorialEmptyIcon.friends => Icons.people_outline,
    EditorialEmptyIcon.search => Icons.search,
    EditorialEmptyIcon.notifications => Icons.notifications_none,
    EditorialEmptyIcon.defaultIcon => Icons.inbox_outlined,
  };
}

/// Error state — mirror web `ErrorState`.
class EditorialErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const EditorialErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.body(context, color: p.danger, size: 14),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            EditorialButton(
              label: context.t('common.retry'),
              variant: EditorialButtonVariant.outline,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}

/// Feed card skeleton — mirror web `FeedGridSkeleton` / `FeedPostCardSkeleton`.
class EditorialFeedSkeleton extends StatelessWidget {
  final int count;

  const EditorialFeedSkeleton({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageX),
      child: Column(
        children: List.generate(count, (i) {
          return Container(
            margin: EdgeInsets.only(bottom: i == count - 1 ? 0 : 16),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: AppRadius.card,
              border: Border.all(color: p.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: p.foreground.withValues(alpha: 0.05),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.xl),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _bar(p, width: 64, height: 10),
                      const SizedBox(height: 12),
                      _bar(p, width: double.infinity, height: 18),
                      const SizedBox(height: 8),
                      _bar(p, width: 180, height: 14),
                      const SizedBox(height: 12),
                      _bar(p, width: double.infinity, height: 10),
                      const SizedBox(height: 6),
                      _bar(p, width: 220, height: 10),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _bar(AppPalette p, {required double width, required double height}) {
    return Container(
      width: width == double.infinity ? null : width,
      height: height,
      decoration: BoxDecoration(
        color: p.foreground.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
