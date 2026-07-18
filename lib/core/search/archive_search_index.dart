import 'package:mobile/core/network/be_blog_http.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/data/repositories/books_repository.dart';
import 'package:mobile/data/repositories/feed_repository.dart';
import 'package:mobile/data/repositories/posts_repository.dart';

enum ArchiveSearchHitType { post, review, book }

class ArchiveSearchHit {
  final ArchiveSearchHitType type;
  final String id;
  final String title;
  final String subtitle;
  final String excerpt;
  final PostDto? post;
  final ReviewDto? review;
  final BookDto? book;

  const ArchiveSearchHit({
    required this.type,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.excerpt,
    this.post,
    this.review,
    this.book,
  });
}

/// Client-side search: posts + reviews từ feed (mình + bạn bè), sách từ catalog.
class ArchiveSearchIndex {
  ArchiveSearchIndex._();

  static final _feedRepo = BeBlogFeedRepository();
  static final _postsRepo = BeBlogPostsRepository();
  static final _booksRepo = BeBlogBooksRepository();

  static Future<
    ({List<PostDto> posts, List<ReviewDto> reviews, List<BookDto> books})
  >
  load({bool forceRefresh = false}) async {
    final results = await Future.wait([
      _feedRepo.getHomeFeed(forceRefresh: forceRefresh),
      _booksRepo.getAll(forceRefresh: forceRefresh),
    ]);

    final feedResult = results[0] as BeBlogRepoResult<List<FeedItemDto>>;
    final booksResult = results[1] as BeBlogRepoResult<List<BookDto>>;

    final feedItems = feedResult.data ?? const [];
    var posts = postsFromFeedItems(feedItems);
    final reviews = reviewsFromFeedItems(feedItems);

    if (!feedResult.success || (posts.isEmpty && reviews.isEmpty)) {
      final networkPosts = await _postsRepo.getNetwork(
        forceRefresh: forceRefresh,
      );
      if (networkPosts.success && (networkPosts.data?.isNotEmpty ?? false)) {
        posts = networkPosts.data!;
      }
    }

    return (
      posts: posts,
      reviews: reviews,
      books: booksResult.data ?? const [],
    );
  }

  static List<ArchiveSearchHit> search(
    String query, {
    required List<PostDto> posts,
    required List<ReviewDto> reviews,
    required List<BookDto> books,
    int maxResults = 24,
  }) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];

    final hits = <ArchiveSearchHit>[];

    for (final post in posts) {
      if (_matches(q, post.title, post.content)) {
        hits.add(
          ArchiveSearchHit(
            type: ArchiveSearchHitType.post,
            id: post.id,
            title: post.title,
            subtitle: 'Editorial post',
            excerpt: post.content,
            post: post,
          ),
        );
      }
    }
    for (final review in reviews) {
      if (_matches(q, review.title, review.content)) {
        hits.add(
          ArchiveSearchHit(
            type: ArchiveSearchHitType.review,
            id: review.id,
            title: review.title,
            subtitle: 'Book review • ${review.rating}/5',
            excerpt: review.content,
            review: review,
          ),
        );
      }
    }
    for (final book in books) {
      if (_matches(q, book.title, book.description, book.isbn, book.language)) {
        hits.add(
          ArchiveSearchHit(
            type: ArchiveSearchHitType.book,
            id: book.id,
            title: book.title,
            subtitle: book.language ?? 'Catalog title',
            excerpt: book.description ?? '',
            book: book,
          ),
        );
      }
    }

    return hits.take(maxResults).toList();
  }

  static bool _matches(
    String q,
    String? title,
    String? body, [
    String? a,
    String? b,
  ]) {
    final haystack = [
      title,
      body,
      a,
      b,
    ].whereType<String>().join(' ').toLowerCase();
    return haystack.contains(q);
  }
}
