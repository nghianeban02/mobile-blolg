import 'package:flutter/material.dart';
import 'package:mobile/core/i18n/locale_controller.dart';
import 'package:mobile/core/theme/app_palette.dart';
import 'package:mobile/core/theme/app_spacing.dart';
import 'package:mobile/core/theme/app_typography.dart';
import 'package:mobile/core/utils/format_datetime.dart';
import 'package:mobile/core/widgets/editorial_page_header.dart';
import 'package:mobile/core/widgets/editorial_states.dart';
import 'package:mobile/core/widgets/editorial_surface_card.dart';
import 'package:mobile/data/models/engagement_dtos.dart';
import 'package:mobile/data/repositories/engagement_repository.dart';
import 'package:mobile/features/posts/screens/post_detail_screen.dart';
import 'package:mobile/features/review/screens/book_detail_screen.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  final _repository = BeBlogEngagementRepository();
  bool _loading = true;
  String? _error;
  List<BookmarkItemDto> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repository.getBookmarks();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _items = result.data ?? const [];
      _error = result.success
          ? null
          : (result.message ?? 'Không tải được nội dung đã lưu.');
    });
  }

  void _open(BookmarkItemDto item) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => item.entityType == BookmarkEntityType.post
            ? PostDetailScreen(postId: item.entityId)
            : BookDetailScreen(reviewId: item.entityId),
      ),
    );
  }

  Future<void> _remove(BookmarkItemDto item) async {
    final index = _items.indexOf(item);
    setState(() => _items = _items.where((value) => value != item).toList());
    final result = await _repository.removeBookmark(
      item.entityType,
      item.entityId,
    );
    if (!mounted || result.success) return;
    setState(() {
      final restored = [..._items];
      restored.insert(index.clamp(0, restored.length), item);
      _items = restored;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.background,
      body: RefreshIndicator(
        color: p.accent,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 48),
          children: [
            EditorialPageHeader(
              title: context.t('bookmarks.pageTitle'),
              subtitle: context.t('bookmarks.pageSubtitle'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageX),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_loading)
                    Padding(
                      padding: const EdgeInsets.all(48),
                      child: Center(
                        child: CircularProgressIndicator(color: p.accent),
                      ),
                    )
                  else if (_error != null)
                    EditorialErrorState(message: _error!, onRetry: _load)
                  else if (_items.isEmpty)
                    EditorialEmptyState(
                      title: context.t('bookmarks.emptyTitle'),
                      message: context.t('bookmarks.emptyMessage'),
                      icon: EditorialEmptyIcon.books,
                    )
                  else
                    ..._items.map(
                      (item) => EditorialSurfaceCard(
                        onTap: () => _open(item),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.fromLTRB(18, 16, 8, 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.entityType == BookmarkEntityType.post
                                        ? context
                                              .t('public.postLabel')
                                              .toUpperCase()
                                        : context
                                              .t('bookmarks.reviewLabel')
                                              .toUpperCase(),
                                    style: AppTypography.sectionEyebrow(
                                      context,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    item.title,
                                    style: AppTypography.cardTitle(
                                      context,
                                      size: 19,
                                    ),
                                  ),
                                  if (item.excerpt.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      item.excerpt,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.body(context),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Text(
                                    context.t('bookmarks.savedAt', {
                                      'date': formatCommentDateTime(
                                        item.savedAt,
                                      ),
                                    }),
                                    style: AppTypography.meta(context),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: context.t('bookmarks.remove'),
                              onPressed: () => _remove(item),
                              icon: Icon(Icons.bookmark, color: p.accent),
                            ),
                          ],
                        ),
                      ),
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
