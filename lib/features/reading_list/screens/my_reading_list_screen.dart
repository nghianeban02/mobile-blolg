import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/widgets/async_loading_view.dart';
import 'package:mobile/core/widgets/detail_app_bar.dart';
import 'package:mobile/core/widgets/editorial_surface_card.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/data/repositories/books_repository.dart';
import 'package:mobile/data/repositories/reading_list_repository.dart';
import 'package:mobile/features/posts/widgets/post_section_label.dart';
import 'package:mobile/features/reading_list/screens/library_book_detail_screen.dart';
import 'package:mobile/features/reading_list/utils/library_book_style.dart';
import 'package:mobile/features/reading_list/widgets/library_book_cover.dart';
import 'package:mobile/features/reading_list/widgets/reading_status_sheet.dart';

/// Personal reading list: `GET /api/reading-list/me`, update via `PUT`.
class MyReadingListScreen extends StatefulWidget {
  const MyReadingListScreen({super.key});

  @override
  State<MyReadingListScreen> createState() => _MyReadingListScreenState();
}

class _MyReadingListScreenState extends State<MyReadingListScreen> {
  final _readingListRepo = BeBlogReadingListRepository();
  final _booksRepo = BeBlogBooksRepository();

  bool _loading = true;
  String? _error;
  List<ReadingListDto> _entries = const [];
  Map<String, BookDto> _bookById = const {};

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

    final listResult = await _readingListRepo.getMine();
    final booksResult = await _booksRepo.getAll();
    if (!mounted) return;

    if (!listResult.success) {
      setState(() {
        _loading = false;
        _error = listResult.message ?? 'Không tải được reading list.';
      });
      return;
    }

    final entries = listResult.data ?? const [];
    final books = booksResult.data ?? const [];
    final bookById = {for (final b in books) b.id: b};

    setState(() {
      _loading = false;
      _entries = entries;
      _bookById = bookById;
    });
  }

  Future<void> _remove(ReadingListDto entry) async {
    final result = await _readingListRepo.remove(entry.id);
    if (!mounted) return;
    if (result.success) {
      await _load();
    }
  }

  Future<void> _updateStatus(ReadingListDto entry) async {
    final next = await showReadingStatusSheet(
      context,
      currentStatus: entry.status,
    );
    if (next == null || next == entry.status) return;

    final result = await _readingListRepo.update(
      entry.id,
      ReadingListWriteRequest(bookId: entry.bookId, status: next),
    );
    if (!mounted) return;
    if (result.success) {
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Could not update status.')),
      );
    }
  }

  String _statusLabel(String status) {
    for (final entry in readingListStatuses) {
      if (entry.$1 == status) return entry.$2;
    }
    return status.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            const DetailSliverAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My reading\nlist',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 36,
                        fontWeight: FontWeight.w600,
                        color: AppColors.homeTextDark,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AsyncLoadingView(
                      isLoading: _loading,
                      errorMessage: _error,
                      onRetry: _load,
                    ),
                    if (!_loading && _error == null) ...[
                      PostSectionLabel(
                        text: '${_entries.length} titles tracked',
                      ),
                      const SizedBox(height: 20),
                      if (_entries.isEmpty)
                        Text(
                          'Chưa có sách nào. Mở một cuốn trong Library và nhấn Add to reading list.',
                          style: GoogleFonts.inter(
                            color: AppColors.homeTextLight,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        )
                      else
                        ..._entries.asMap().entries.map((e) {
                          final entry = e.value;
                          final book = _bookById[entry.bookId];
                          final index = e.key;
                          return EditorialSurfaceCard(
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.all(16),
                            onTap: book != null
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            LibraryBookDetailScreen(
                                              bookId: book.id,
                                              initialBook: book,
                                              colorIndex: index,
                                            ),
                                      ),
                                    );
                                  }
                                : null,
                            child: Row(
                              children: [
                                if (book != null)
                                  LibraryBookCover(
                                    book: book,
                                    fallbackColor: LibraryBookStyle.coverColor(
                                      index,
                                    ),
                                    width: 56,
                                    height: 76,
                                  )
                                else
                                  Container(
                                    width: 56,
                                    height: 76,
                                    decoration: BoxDecoration(
                                      color: AppColors.coverSand,
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.md,
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        book?.title ?? entry.bookId,
                                        style: GoogleFonts.playfairDisplay(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      GestureDetector(
                                        onTap: () => _updateStatus(entry),
                                        behavior: HitTestBehavior.opaque,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryBrown
                                                .withValues(alpha: 0.1),
                                            borderRadius: AppRadius.pill,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                _statusLabel(
                                                  entry.status,
                                                ).toUpperCase(),
                                                style: GoogleFonts.inter(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1,
                                                  color:
                                                      AppColors.primaryBrown,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(
                                                Icons.expand_more,
                                                size: 14,
                                                color: AppColors.primaryBrown,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _remove(entry),
                                  icon: const Icon(
                                    Icons.close,
                                    size: 18,
                                    color: AppColors.homeTextLight,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
