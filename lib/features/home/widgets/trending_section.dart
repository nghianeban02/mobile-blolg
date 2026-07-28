import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/i18n/locale_controller.dart';
import 'package:mobile/core/theme/app_palette.dart';
import 'package:mobile/core/theme/app_spacing.dart';
import 'package:mobile/core/theme/app_typography.dart';
import 'package:mobile/core/widgets/editorial_surface_card.dart';
import 'package:mobile/data/models/engagement_dtos.dart';
import 'package:mobile/data/repositories/engagement_repository.dart';
import 'package:mobile/features/posts/screens/post_detail_screen.dart';

/// "Nổi bật tuần này" — mirror web `TrendingSection`.
class TrendingSection extends StatefulWidget {
  const TrendingSection({super.key});

  @override
  State<TrendingSection> createState() => _TrendingSectionState();
}

class _TrendingSectionState extends State<TrendingSection> {
  final _repo = BeBlogEngagementRepository();
  List<TrendingItemDto> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await _repo.getTrendingPosts();
    if (!mounted) return;
    if (result.success && result.data != null && result.data!.isNotEmpty) {
      setState(() => _items = result.data!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageX),
            child: Row(
              children: [
                const Text('📈', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  context.t('trending.title').toUpperCase(),
                  style: AppTypography.sectionEyebrow(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageX),
              scrollDirection: Axis.horizontal,
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = _items[index];
                return SizedBox(
                  width: 256,
                  child: EditorialSurfaceCard(
                    padding: const EdgeInsets.all(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => PostDetailScreen(postId: item.id),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${index + 1}',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                height: 1,
                                color: p.accent.withValues(alpha: 0.3),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        AppTypography.body(
                                          context,
                                          color: p.foreground,
                                          size: 14,
                                        ).copyWith(
                                          fontWeight: FontWeight.w600,
                                          height: 1.3,
                                        ),
                                  ),
                                  if (item.excerpt.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      item.excerpt,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.body(
                                        context,
                                        size: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            if (item.authorUsername != null)
                              Expanded(
                                child: Text(
                                  item.authorUsername!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.body(
                                    context,
                                    size: 12,
                                    color: p.foreground.withValues(alpha: 0.7),
                                  ).copyWith(fontWeight: FontWeight.w500),
                                ),
                              ),
                            Text(
                              '💖 ${item.likeCount}',
                              style: AppTypography.body(context, size: 12),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '💬 ${item.commentCount}',
                              style: AppTypography.body(context, size: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
