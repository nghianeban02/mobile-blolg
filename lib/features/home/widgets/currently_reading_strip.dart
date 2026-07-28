import 'package:flutter/material.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/i18n/locale_controller.dart';
import 'package:mobile/core/theme/app_palette.dart';
import 'package:mobile/core/theme/app_spacing.dart';
import 'package:mobile/core/theme/app_typography.dart';
import 'package:mobile/core/widgets/app_cached_image.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/data/repositories/books_repository.dart';
import 'package:mobile/data/repositories/reading_list_repository.dart';
import 'package:mobile/features/reading_list/screens/library_book_detail_screen.dart';
import 'package:mobile/features/reading_list/screens/my_reading_list_screen.dart';

/// Horizontal "Đang đọc" strip — mirror web `CurrentlyReadingStrip`.
class CurrentlyReadingStrip extends StatefulWidget {
  const CurrentlyReadingStrip({super.key});

  @override
  State<CurrentlyReadingStrip> createState() => _CurrentlyReadingStripState();
}

class _CurrentlyReadingStripState extends State<CurrentlyReadingStrip> {
  final _listRepo = BeBlogReadingListRepository();
  final _booksRepo = BeBlogBooksRepository();
  List<_ReadingItem> _items = const [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await _listRepo.getMine();
      if (!list.success || list.data == null) {
        if (mounted) setState(() => _loaded = true);
        return;
      }
      final reading = list.data!
          .where((e) => e.status.toLowerCase() == 'reading')
          .take(5)
          .toList();
      final items = <_ReadingItem>[];
      for (final entry in reading) {
        BookDto? book;
        try {
          final res = await _booksRepo.getOne(entry.bookId);
          if (res.success) book = res.data;
        } catch (_) {}
        items.add(_ReadingItem(entry: entry, book: book));
      }
      if (mounted) {
        setState(() {
          _items = items;
          _loaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _items.isEmpty) return const SizedBox.shrink();
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageX),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.t('home.currentlyReading').toUpperCase(),
                    style: AppTypography.sectionEyebrow(context),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const MyReadingListScreen(),
                      ),
                    );
                  },
                  child: Text(
                    context.t('common.viewAll'),
                    style: AppTypography.accentLabel(
                      context,
                    ).copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageX),
              scrollDirection: Axis.horizontal,
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = _items[index];
                final title = item.book?.title ?? context.t('common.book');
                final cover =
                    item.book?.resolveCoverImageUrl(ApiConstants.baseUrl) ??
                    '${ApiConstants.baseUrl}/api/images/books/${item.entry.bookId}/cover';
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => LibraryBookDetailScreen(
                          bookId: item.entry.bookId,
                          initialBook: item.book,
                        ),
                      ),
                    );
                  },
                  child: SizedBox(
                    width: 88,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: p.coverSand,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: p.border.withValues(alpha: 0.6),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: AppCachedImage(
                              url: cover,
                              fit: BoxFit.cover,
                              fallbackColor: p.coverSand,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body(
                            context,
                            color: p.foreground,
                            size: 11,
                          ).copyWith(fontWeight: FontWeight.w500, height: 1.25),
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

class _ReadingItem {
  final ReadingListDto entry;
  final BookDto? book;
  const _ReadingItem({required this.entry, this.book});
}
