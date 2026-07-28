import 'package:flutter/material.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/i18n/locale_controller.dart';
import 'package:mobile/core/theme/app_palette.dart';
import 'package:mobile/core/theme/app_spacing.dart';
import 'package:mobile/core/theme/app_typography.dart';
import 'package:mobile/core/utils/app_date_format.dart';
import 'package:mobile/core/utils/text_excerpt.dart';
import 'package:mobile/core/widgets/app_cached_image.dart';
import 'package:mobile/core/widgets/editorial_star_rating.dart';
import 'package:mobile/core/widgets/editorial_surface_card.dart';
import 'package:mobile/core/widgets/editorial_ui.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/features/posts/screens/post_detail_screen.dart';
import 'package:mobile/features/review/screens/book_detail_screen.dart';

/// Featured hero review — mirror web `FeaturedReviewCard` (stacked on mobile).
class FeaturedReviewCard extends StatelessWidget {
  final ReviewDto review;
  final UserPublicDto? author;

  const FeaturedReviewCard({super.key, required this.review, this.author});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final coverUrl =
        '${ApiConstants.baseUrl}/api/images/books/${review.bookId}/cover';
    final authorName = author?.displayName;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageX,
        0,
        AppSpacing.pageX,
        AppSpacing.homeSectionGap,
      ),
      child: EditorialSurfaceCard(
        padding: EdgeInsets.zero,
        showAccentBar: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => BookDetailScreen(
                reviewId: review.id,
                initialReview: review,
                authorId: author?.id ?? review.userId,
                authorDisplayName: authorName,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: ColoredBox(
                color: p.coverTeal.withValues(alpha: 0.4),
                child: AppCachedImage(
                  url: coverUrl,
                  fit: BoxFit.cover,
                  fallbackColor: p.coverSand,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.t('common.featuredReview'),
                    style: AppTypography.accentLabel(context),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    review.title,
                    style: AppTypography.cardTitle(context, size: 24),
                  ),
                  if (authorName != null) ...[
                    const SizedBox(height: 16),
                    Text.rich(
                      TextSpan(
                        style: AppTypography.body(context, size: 14),
                        children: [
                          TextSpan(text: '${context.t('common.by')} '),
                          TextSpan(
                            text: authorName,
                            style: TextStyle(color: p.foreground),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    textExcerpt(review.content, maxLength: 220),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(context, size: 16),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      EditorialStarRating(rating: review.rating),
                      if (review.createdAt != null) ...[
                        const SizedBox(width: 16),
                        Text(
                          AppDateFormat.formatDate(
                            review.createdAt,
                          ).toUpperCase(),
                          style: AppTypography.meta(context),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Feed review card — mirror web `FeedReviewCard`.
class FeedReviewCard extends StatelessWidget {
  final FeedItemDto item;

  const FeedReviewCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final review = item.review!;
    final author = item.author;
    final preview = textExcerpt(review.content, maxLength: 140);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageX,
        0,
        AppSpacing.pageX,
        16,
      ),
      child: EditorialSurfaceCard(
        showAccentBar: true,
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => BookDetailScreen(
                reviewId: review.id,
                initialReview: review,
                authorId: item.authorId ?? author?.id ?? review.userId,
                authorDisplayName: author?.displayName,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (author != null)
              _CardAuthorHeader(author: author, createdAt: review.createdAt),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        context.t('feed.reviewType'),
                        style: AppTypography.accentLabel(context),
                      ),
                      if (review.status.toLowerCase() != 'published')
                        EditorialStatusChip(label: review.status),
                      if (review.containsSpoilers)
                        EditorialStatusChip(
                          label: context.t('common.spoilers'),
                          backgroundColor: context.palette.danger.withValues(
                            alpha: 0.1,
                          ),
                          textColor: context.palette.danger,
                        ),
                    ],
                  ),
                ),
                EditorialStarRating(rating: review.rating),
              ],
            ),
            const SizedBox(height: 8),
            Text(review.title, style: AppTypography.cardTitle(context)),
            if (preview.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(preview, style: AppTypography.body(context)),
            ],
            if (author == null && review.createdAt != null) ...[
              const SizedBox(height: 20),
              Text(
                AppDateFormat.formatDate(review.createdAt).toUpperCase(),
                style: AppTypography.meta(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Feed post card — mirror web `FeedPostCard`.
class FeedPostCard extends StatelessWidget {
  final FeedItemDto item;
  final VoidCallback? onChanged;

  const FeedPostCard({super.key, required this.item, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final post = item.post!;
    final author = item.author;
    final preview = textExcerpt(post.content, maxLength: 120);
    final titleSrc = post.titleImageUrl;
    final hasImage = titleSrc != null && titleSrc.isNotEmpty;
    final imageUrl = hasImage
        ? (titleSrc.startsWith('http')
              ? titleSrc
              : '${ApiConstants.baseUrl}$titleSrc')
        : null;
    final showAuthor = _shouldShowPostAuthor(author);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageX,
        0,
        AppSpacing.pageX,
        16,
      ),
      child: EditorialSurfaceCard(
        padding: EdgeInsets.zero,
        onTap: () async {
          final changed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  PostDetailScreen(postId: post.id, initialPost: post),
            ),
          );
          if (changed == true) onChanged?.call();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasImage && imageUrl != null)
              AspectRatio(
                aspectRatio: 16 / 10,
                child: ColoredBox(
                  color: context.palette.coverTeal.withValues(alpha: 0.3),
                  child: AppCachedImage(
                    url: imageUrl,
                    fit: BoxFit.cover,
                    fallbackColor: AppColors.coverTeal,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showAuthor && author != null)
                    _CardAuthorHeader(
                      author: author,
                      createdAt: post.createdAt,
                    ),
                  Wrap(
                    spacing: 8,
                    children: [
                      Text(
                        context.t('feed.postType'),
                        style: AppTypography.accentLabel(context),
                      ),
                      if (post.status != PostStatus.approved &&
                          post.status != PostStatus.unknown)
                        EditorialStatusChip(label: post.status.name),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(post.title, style: AppTypography.cardTitle(context)),
                  if (!showAuthor && post.createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      AppDateFormat.formatTimeAgo(post.createdAt),
                      style: AppTypography.meta(context),
                    ),
                  ],
                  if (preview.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(preview, style: AppTypography.body(context)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mirror web `shouldShowPostAuthor`.
  bool _shouldShowPostAuthor(UserPublicDto? author) {
    if (author == null || author.username.isEmpty) return false;
    const hidden = {'admin', 'admin@123'};
    return !hidden.contains(author.username.toLowerCase());
  }
}

class _CardAuthorHeader extends StatelessWidget {
  final UserPublicDto author;
  final DateTime? createdAt;

  const _CardAuthorHeader({required this.author, this.createdAt});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          EditorialAvatarInitial(name: author.displayName, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  author.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(
                    context,
                    color: context.palette.foreground,
                    size: 14,
                  ).copyWith(fontWeight: FontWeight.w500),
                ),
                if (createdAt != null)
                  Text(
                    AppDateFormat.formatTimeAgo(createdAt),
                    style: AppTypography.body(context, size: 11).copyWith(
                      color: context.palette.muted.withValues(alpha: 0.8),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
