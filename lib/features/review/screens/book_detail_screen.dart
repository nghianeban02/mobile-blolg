import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/cache/session_cache.dart';
import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/network/be_blog_http.dart';
import 'package:mobile/core/widgets/async_loading_view.dart';
import 'package:mobile/core/widgets/editorial_confirm_dialog.dart';
import 'package:mobile/core/widgets/share_button.dart';
import 'package:mobile/data/auth/auth_repository.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/data/models/engagement_dtos.dart';
import 'package:mobile/data/repositories/books_repository.dart';
import 'package:mobile/data/repositories/reviews_repository.dart';
import 'package:mobile/data/repositories/users_repository.dart';
import 'package:mobile/features/posts/widgets/post_network_image.dart';
import 'package:mobile/features/reading_list/utils/library_book_style.dart';
import 'package:mobile/features/review/screens/edit_review_screen.dart';
import 'package:mobile/features/review/widgets/related_reviews_section.dart';
import 'package:mobile/features/review/widgets/review_comments_section.dart';
import 'package:mobile/features/review/widgets/review_detail_body.dart';
import 'package:mobile/features/review/widgets/review_engagement_bar.dart';
import 'package:mobile/features/review/widgets/review_tags_section.dart';
import 'package:mobile/features/saved/widgets/bookmark_button.dart';

/// Chi tiết một review sách — layout editorial giống [PostDetailScreen].
class BookDetailScreen extends StatefulWidget {
  final String reviewId;
  final ReviewDto? initialReview;
  final String? authorId;
  final String? authorDisplayName;

  const BookDetailScreen({
    super.key,
    required this.reviewId,
    this.initialReview,
    this.authorId,
    this.authorDisplayName,
  });

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final _reviewsRepo = BeBlogReviewsRepository();
  final _booksRepo = BeBlogBooksRepository();
  final _usersRepo = BeBlogUsersRepository();
  final _authRepo = AuthRepository();

  static const double _heroHeight = 280;

  bool _isLoading = true;
  bool _isDeleting = false;
  bool _canManage = SessionCache.isAdmin;
  String? _error;
  ReviewDto? _review;
  BookDto? _book;
  List<ReviewDto> _bookReviews = const [];
  String? _authorName;
  String? _authorId;

  @override
  void initState() {
    super.initState();
    final seed = widget.initialReview;
    if (seed != null && seed.id == widget.reviewId) {
      _review = seed;
      _isLoading = false;
    }
    _authorName = widget.authorDisplayName;
    _authorId = widget.authorId;
    _load();
  }

  Future<void> _load() async {
    if (_review == null) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    final reviewResult = await _reviewsRepo.getOne(widget.reviewId);
    if (!mounted) return;

    if (!reviewResult.success || reviewResult.data == null) {
      setState(() {
        _isLoading = false;
        if (_review == null) {
          _error = reviewResult.message ?? 'Không tải được review.';
        }
      });
      return;
    }

    final review = reviewResult.data!;
    final results = await Future.wait([
      _booksRepo.getOne(review.bookId),
      _reviewsRepo.getAll(bookId: review.bookId),
      if (_authorName == null || _authorName!.isEmpty)
        _usersRepo.getProfile(review.userId)
      else
        Future.value(null),
    ]);
    if (!mounted) return;

    final bookResult = results[0] as BeBlogRepoResult<BookDto>;
    final reviewsResult = results[1] as BeBlogRepoResult<List<ReviewDto>>;
    final profileResult = results.length > 2
        ? results[2] as BeBlogRepoResult<UserProfileViewDto>?
        : null;

    var authorName = _authorName ?? widget.authorDisplayName;
    var authorId = _authorId ?? widget.authorId ?? review.userId;
    if ((authorName == null || authorName.isEmpty) &&
        profileResult?.success == true &&
        profileResult?.data != null) {
      authorName = profileResult!.data!.displayName;
      authorId = profileResult.data!.id;
    }

    setState(() {
      _isLoading = false;
      _review = review;
      _error = null;
      _book = bookResult.data;
      _bookReviews = reviewsResult.data ?? const [];
      _authorName = authorName;
      _authorId = authorId;
    });
    await _resolveCanManage();
  }

  Future<void> _resolveCanManage() async {
    final review = _review;
    if (review == null) return;
    if (SessionCache.isAdmin) {
      if (!_canManage) setState(() => _canManage = true);
      return;
    }
    final token = await _authRepo.getToken();
    if (token == null || token.isEmpty) return;
    final me = await _usersRepo.me();
    if (!mounted) return;
    final userId = me.data?.id;
    setState(() {
      _canManage =
          me.data?.isAdmin == true ||
          (userId != null && userId == review.userId);
    });
  }

  Future<void> _openEdit() async {
    final review = _review;
    if (review == null) return;
    final updated = await Navigator.push<ReviewDto>(
      context,
      MaterialPageRoute(builder: (_) => EditReviewScreen(review: review)),
    );
    if (updated != null && mounted) {
      setState(() => _review = updated);
      unawaited(_load());
    }
  }

  Future<void> _confirmDelete() async {
    final review = _review;
    if (review == null) return;
    final ok = await showEditorialConfirmDialog(
      context,
      title: 'Xóa review?',
      message: '“${review.title}” sẽ bị xóa khỏi thư viện.',
      confirmLabel: 'Xóa',
      destructive: true,
    );
    if (!ok) return;
    setState(() => _isDeleting = true);
    final result = await _reviewsRepo.delete(review.id);
    if (!mounted) return;
    setState(() => _isDeleting = false);
    if (result.success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Không thể xóa review.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final review = _review;
    final book = _book;
    final hasHero = book?.hasCoverImage == true;
    final coverUrl = book?.resolveCoverImageUrl(ApiConstants.baseUrl);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: hasHero ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.homeBackground,
        body: _buildBody(review, book, hasHero, coverUrl),
      ),
    );
  }

  Widget _buildBody(
    ReviewDto? review,
    BookDto? book,
    bool hasHero,
    String? coverUrl,
  ) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBrown),
      );
    }

    if (_error != null) {
      return SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFlatAppBar(useLightIcons: false),
            Expanded(
              child: AsyncLoadingView(
                isLoading: false,
                errorMessage: _error,
                onRetry: _load,
              ),
            ),
          ],
        ),
      );
    }

    if (review == null) return const SizedBox.shrink();

    final related = _bookReviews.where((r) => r.id != review.id).toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          pinned: true,
          stretch: hasHero,
          expandedHeight: hasHero ? _heroHeight : 0,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: AppColors.homeBackground,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          leading: _NavIconButton(
            onPressed: _isDeleting ? null : () => Navigator.pop(context),
            icon: Icons.arrow_back_ios_new,
            light: hasHero,
          ),
          actions: [
            BookmarkButton(
              entityType: BookmarkEntityType.review,
              entityId: review.id,
              light: hasHero,
            ),
            if (_canManage) ...[
              _NavIconButton(
                onPressed: _isDeleting ? null : _openEdit,
                icon: Icons.edit_outlined,
                light: hasHero,
              ),
              _NavIconButton(
                onPressed: _isDeleting ? null : _confirmDelete,
                icon: Icons.delete_outline,
                light: hasHero,
                iconColor: hasHero ? Colors.white : AppColors.error,
                child: _isDeleting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: hasHero ? Colors.white : AppColors.error,
                        ),
                      )
                    : null,
              ),
            ],
            const SizedBox(width: 8),
          ],
          flexibleSpace: hasHero && coverUrl != null
              ? FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      PostNetworkImage(
                        url: coverUrl,
                        fallbackColor: LibraryBookStyle.coverColor(0),
                      ),
                      IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.45),
                                Colors.transparent,
                                AppColors.homeBackground,
                              ],
                              stops: const [0.0, 0.55, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : null,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, hasHero ? 8 : 0, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!hasHero) const SizedBox(height: 8),
                ReviewDetailBody(
                  review: review,
                  bookTitle: book?.title,
                  authorId: _authorId,
                  authorDisplayName: _authorName,
                ),
                ReviewEngagementBar(reviewId: review.id),
                const SizedBox(height: 12),
                ShareButton(
                  title: review.title,
                  url: AppConfig.publicReviewUrl(review.id),
                ),
                const SizedBox(height: 8),
                ReviewTagsSection(
                  reviewId: review.id,
                  reviewUserId: review.userId,
                ),
                const SizedBox(height: 24),
                ReviewCommentsSection(reviewId: review.id),
                if (related.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  RelatedReviewsSection(
                    reviews: related,
                    excludeReviewId: review.id,
                    authorId: _authorId,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 48)),
      ],
    );
  }

  Widget _buildFlatAppBar({required bool useLightIcons}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          _NavIconButton(
            onPressed: _isDeleting ? null : () => Navigator.pop(context),
            icon: Icons.arrow_back_ios_new,
            light: useLightIcons,
          ),
        ],
      ),
    );
  }
}

class _NavIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final bool light;
  final Color? iconColor;
  final Widget? child;

  const _NavIconButton({
    required this.onPressed,
    required this.icon,
    this.light = false,
    this.iconColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? (light ? Colors.white : AppColors.homeTextDark);

    return IconButton(
      onPressed: onPressed,
      icon: child ?? Icon(icon, size: 20, color: color),
    );
  }
}
