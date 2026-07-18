import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/cache/session_cache.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/network/be_blog_http.dart';
import 'package:mobile/core/widgets/async_loading_view.dart';
import 'package:mobile/core/widgets/detail_app_bar.dart';
import 'package:mobile/data/auth/auth_repository.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/data/repositories/books_repository.dart';
import 'package:mobile/data/repositories/reviews_repository.dart';
import 'package:mobile/data/repositories/users_repository.dart';
import 'package:mobile/features/reading_list/screens/edit_book_screen.dart';
import 'package:mobile/features/reading_list/widgets/book_detail/book_detail_catalog_section.dart';
import 'package:mobile/features/reading_list/widgets/book_detail/book_detail_cover_hero.dart';
import 'package:mobile/features/reading_list/widgets/book_detail/book_detail_info.dart';
import 'package:mobile/features/reading_list/widgets/book_detail/book_detail_reading_list_bar.dart';
import 'package:mobile/features/reading_list/widgets/book_detail/book_detail_reviews_section.dart';
import 'package:mobile/features/review/screens/book_detail_screen.dart';

/// Catalog book detail from `GET /api/books/{id}` + reviews for this book.
class LibraryBookDetailScreen extends StatefulWidget {
  final String bookId;
  final BookDto? initialBook;
  final int colorIndex;

  const LibraryBookDetailScreen({
    super.key,
    required this.bookId,
    this.initialBook,
    this.colorIndex = 0,
  });

  @override
  State<LibraryBookDetailScreen> createState() =>
      _LibraryBookDetailScreenState();
}

class _LibraryBookDetailScreenState extends State<LibraryBookDetailScreen> {
  final _booksRepo = BeBlogBooksRepository();
  final _reviewsRepo = BeBlogReviewsRepository();
  final _usersRepo = BeBlogUsersRepository();
  final _authRepo = AuthRepository();

  bool _isLoading = true;
  bool _isAdmin = SessionCache.isAdmin;
  String? _error;
  BookDto? _book;
  List<ReviewDto> _reviews = const [];

  @override
  void initState() {
    super.initState();
    final seed = widget.initialBook;
    if (seed != null && seed.id == widget.bookId) {
      _book = seed;
      _isLoading = false;
    }
    _load();
    _loadAdminStatus();
  }

  Future<void> _loadAdminStatus() async {
    if (SessionCache.isAdmin) {
      if (!_isAdmin) setState(() => _isAdmin = true);
      return;
    }
    final token = await _authRepo.getToken();
    if (token == null || token.isEmpty) return;
    final me = await _usersRepo.me();
    if (!mounted) return;
    setState(() => _isAdmin = me.success && (me.data?.isAdmin ?? false));
  }

  Future<void> _openEditBook() async {
    final book = _book;
    if (book == null) return;
    final result = await Navigator.push<Object?>(
      context,
      MaterialPageRoute<Object?>(builder: (_) => EditBookScreen(book: book)),
    );
    if (!mounted) return;
    if (result == 'deleted') {
      Navigator.pop(context);
      return;
    }
    if (result is BookDto) {
      setState(() => _book = result);
    }
  }

  Future<void> _load() async {
    if (_book == null) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    final results = await Future.wait([
      _booksRepo.getOne(widget.bookId, forceRefresh: true),
      _reviewsRepo.getAll(bookId: widget.bookId),
    ]);
    if (!mounted) return;

    final bookResult = results[0] as BeBlogRepoResult<BookDto>;
    final reviewsResult = results[1] as BeBlogRepoResult<List<ReviewDto>>;

    setState(() {
      _isLoading = false;
      if (bookResult.success && bookResult.data != null) {
        _book = bookResult.data;
        _error = null;
      } else if (_book == null) {
        _error = bookResult.message ?? 'Không tải được thông tin sách.';
      }
      _reviews = reviewsResult.data ?? const [];
    });
  }

  void _openPrimaryReview() {
    if (_reviews.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BookDetailScreen(
          reviewId: _reviews.first.id,
          initialReview: _reviews.first,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = _book;

    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const DetailSliverAppBar(),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  AsyncLoadingView(
                    isLoading: _isLoading,
                    errorMessage: _error,
                    onRetry: _load,
                  ),
                  if (!_isLoading && _error == null && book != null) ...[
                    BookDetailCoverHero(
                      book: book,
                      colorIndex: widget.colorIndex,
                    ),
                    const SizedBox(height: 32),
                    BookDetailInfo(book: book),
                    if (_isAdmin) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton(
                            onPressed: _openEditBook,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryBrown,
                              side: BorderSide(
                                color: AppColors.primaryBrown.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                            child: Text(
                              'Edit book',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    BookDetailCatalogSection(bookId: book.id),
                    const SizedBox(height: 24),
                    BookDetailReadingListBar(bookId: book.id),
                    const SizedBox(height: 32),
                    BookDetailReviewsSection(reviews: _reviews),
                    if (_reviews.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _openPrimaryReview,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBrown,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: const StadiumBorder(),
                            ),
                            child: Text(
                              _reviews.length == 1
                                  ? 'READ REVIEW'
                                  : 'READ LATEST REVIEW',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
