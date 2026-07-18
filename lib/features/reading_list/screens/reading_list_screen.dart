import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/cache/session_cache.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/images/book_image_prefetch.dart';
import 'package:mobile/core/network/be_blog_http.dart';
import 'package:mobile/core/widgets/async_loading_view.dart';
import 'package:mobile/core/widgets/main_app_bar.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/data/repositories/books_repository.dart';
import 'package:mobile/data/repositories/posts_repository.dart';
import 'package:mobile/data/repositories/reviews_repository.dart';
import 'package:mobile/data/repositories/users_repository.dart';
import 'package:mobile/features/posts/widgets/post_section_label.dart';
import 'package:mobile/features/reading_list/screens/library_book_detail_screen.dart';
import 'package:mobile/features/reading_list/widgets/currently_reading_card.dart';
import 'package:mobile/features/reading_list/widgets/editors_choice_banner.dart';
import 'package:mobile/features/reading_list/widgets/library_my_posts_section.dart';
import 'package:mobile/features/reading_list/widgets/reading_header.dart';
import 'package:mobile/features/reading_list/widgets/reading_list_item.dart';
import 'package:mobile/features/reading_list/widgets/reading_streak_box.dart';
import 'package:mobile/features/review/screens/book_detail_screen.dart';

/// Library tab: `GET /api/books/me` + `GET /api/users/me/posts` + user reviews.
class ReadingListScreen extends StatefulWidget {
  final bool loadOnMount;

  const ReadingListScreen({super.key, this.loadOnMount = true});

  @override
  State<ReadingListScreen> createState() => ReadingListScreenState();
}

class ReadingListScreenState extends State<ReadingListScreen> {
  final _booksRepo = BeBlogBooksRepository();
  final _postsRepo = BeBlogPostsRepository();
  final _reviewsRepo = BeBlogReviewsRepository();
  final _usersRepo = BeBlogUsersRepository();

  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _error;
  List<BookDto> _books = const [];
  List<PostDto> _myPosts = const [];
  Map<String, ReviewDto> _reviewByBookId = const {};

  @override
  void initState() {
    super.initState();
    if (widget.loadOnMount) {
      _loadLibrary();
    }
  }

  void ensureLoaded() {
    if (!_hasLoaded && !_isLoading) _loadLibrary();
  }

  void refresh() => _loadLibrary(forceRefresh: true);

  Future<void> _loadLibrary({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final userId = SessionCache.profile?.id;
    final meFuture = userId == null ? _usersRepo.me() : null;

    final results = await Future.wait([
      _booksRepo.getMine(forceRefresh: forceRefresh),
      _postsRepo.getMine(forceRefresh: forceRefresh),
      if (meFuture != null) meFuture else Future.value(null),
    ]);
    if (!mounted) return;

    final booksResult = results[0] as BeBlogRepoResult<List<BookDto>>;
    final postsResult = results[1] as BeBlogRepoResult<List<PostDto>>;

    if (!booksResult.success) {
      setState(() {
        _isLoading = false;
        _hasLoaded = true;
        _error = booksResult.message ?? 'Không tải được thư viện sách.';
      });
      return;
    }

    var resolvedUserId = SessionCache.profile?.id;
    if (resolvedUserId == null && results.length > 2) {
      final me = results[2] as BeBlogRepoResult<UserProfileDto>?;
      resolvedUserId = me?.data?.id;
    }

    final reviewsResult = await _reviewsRepo.getAll(forceRefresh: forceRefresh);
    final reviews = reviewsResult.data ?? const [];

    if (!mounted) return;

    final reviewMap = <String, ReviewDto>{};
    for (final review in reviews) {
      reviewMap.putIfAbsent(review.bookId, () => review);
    }

    final books = booksResult.data ?? const [];

    setState(() {
      _isLoading = false;
      _hasLoaded = true;
      _books = books;
      _myPosts = postsResult.data ?? const [];
      _reviewByBookId = reviewMap;
      _error = null;
    });

    BookImagePrefetch.prefetchBookCovers(books);
  }

  void _openBook(BookDto book, {int colorIndex = 0}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LibraryBookDetailScreen(
          bookId: book.id,
          initialBook: book,
          colorIndex: colorIndex,
        ),
      ),
    );
  }

  void _openReview(ReviewDto review) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            BookDetailScreen(reviewId: review.id, initialReview: review),
      ),
    );
  }

  BookDto? _bookAt(int index) =>
      index >= 0 && index < _books.length ? _books[index] : null;

  List<BookDto> get _listBooks =>
      _books.length > 2 ? _books.sublist(2) : const [];

  @override
  Widget build(BuildContext context) {
    final featured = _bookAt(0);
    final editorsPick = _bookAt(1);
    final listBooks = _listBooks;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.primaryBrown,
        onRefresh: () => _loadLibrary(forceRefresh: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            const MainAppBar(),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ReadingHeader(),
                  const SizedBox(height: 32),
                  AsyncLoadingView(
                    isLoading: _isLoading,
                    errorMessage: _error,
                    onRetry: () => _loadLibrary(forceRefresh: true),
                  ),
                  if (!_isLoading && _error == null) ...[
                    LibraryMyPostsSection(posts: _myPosts),
                    CurrentlyReadingCard(
                      book: featured,
                      review: featured != null
                          ? _reviewByBookId[featured.id]
                          : null,
                      onOpenBook: featured != null
                          ? () => _openBook(featured, colorIndex: 0)
                          : null,
                      onReadReview:
                          featured != null &&
                              _reviewByBookId[featured.id] != null
                          ? () => _openReview(_reviewByBookId[featured.id]!)
                          : null,
                    ),
                    const SizedBox(height: 40),
                    EditorsChoiceBanner(
                      book: editorsPick,
                      onTap: editorsPick != null
                          ? () => _openBook(editorsPick, colorIndex: 1)
                          : null,
                    ),
                    const SizedBox(height: 24),
                    const ReadingStreakBox(),
                    const SizedBox(height: 40),
                  ],
                ],
              ),
            ),
            if (!_isLoading &&
                _error == null &&
                listBooks.isEmpty &&
                _books.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Chưa có sách trong thư viện. Nhấn + để thêm sách và review.',
                    style: GoogleFonts.inter(
                      color: AppColors.homeTextLight,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            if (!_isLoading && _error == null && listBooks.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: PostSectionLabel(text: 'Your books'),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Text(
                    '${listBooks.length} ${listBooks.length == 1 ? 'title' : 'titles'} in your library',
                    style: GoogleFonts.inter(
                      color: AppColors.homeTextLight,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
              SliverList.builder(
                itemCount: listBooks.length,
                itemBuilder: (context, index) {
                  final book = listBooks[index];
                  final review = _reviewByBookId[book.id];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < listBooks.length - 1 ? 32 : 0,
                    ),
                    child: ReadingListItem(
                      key: ValueKey(book.id),
                      book: book,
                      listIndex: index + 2,
                      review: review,
                      onTap: () => _openBook(book, colorIndex: index + 2),
                      onReadReview: review != null
                          ? () => _openReview(review)
                          : null,
                    ),
                  );
                },
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 48)),
          ],
        ),
      ),
    );
  }
}
