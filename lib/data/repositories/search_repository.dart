import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/be_blog_http.dart';
import 'package:mobile/core/network/be_blog_response_parser.dart';
import 'package:mobile/core/search/archive_search_index.dart';
import 'package:mobile/data/models/dtos.dart';

enum ArchiveSearchFilter { all, posts, reviews, books }

class SearchCountsDto {
  final int all;
  final int posts;
  final int reviews;
  final int books;

  const SearchCountsDto({
    this.all = 0,
    this.posts = 0,
    this.reviews = 0,
    this.books = 0,
  });

  factory SearchCountsDto.fromJson(Map<String, dynamic> json) =>
      SearchCountsDto(
        all: (json['all'] as num?)?.toInt() ?? 0,
        posts: (json['posts'] as num?)?.toInt() ?? 0,
        reviews: (json['reviews'] as num?)?.toInt() ?? 0,
        books: (json['books'] as num?)?.toInt() ?? 0,
      );
}

class SearchPageDto {
  final List<ArchiveSearchHit> hits;
  final int total;
  final SearchCountsDto counts;

  const SearchPageDto({
    this.hits = const [],
    this.total = 0,
    this.counts = const SearchCountsDto(),
  });
}

class BeBlogSearchRepository {
  Future<BeBlogRepoResult<SearchPageDto>> search(
    String query, {
    ArchiveSearchFilter filter = ArchiveSearchFilter.all,
    int page = 0,
    int size = 50,
  }) async {
    final response = await BeBlogHttp.get(
      ApiConstants.search,
      query: {
        'q': query.trim(),
        'type': filter.name,
        'page': '$page',
        'size': '$size',
      },
    );
    if (!BeBlogResponseParser.isSuccess(response.statusCode)) {
      return BeBlogRepoResult.fail(
        response.statusCode,
        BeBlogHttp.extractServerMessage(response.body),
      );
    }
    try {
      final json = BeBlogHttp.decodeJsonObject(
        BeBlogHttp.decodeBody(response.body),
      );
      final rawItems = json['items'] is List ? json['items'] as List : const [];
      final hits = <ArchiveSearchHit>[];
      for (final raw in rawItems.whereType<Map>()) {
        final item = Map<String, dynamic>.from(raw);
        switch (item['type']?.toString().toUpperCase()) {
          case 'POST':
            if (item['post'] is Map) {
              final post = PostDto.fromJson(
                Map<String, dynamic>.from(item['post'] as Map),
              );
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
          case 'REVIEW':
            if (item['review'] is Map) {
              final review = ReviewDto.fromJson(
                Map<String, dynamic>.from(item['review'] as Map),
              );
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
          case 'BOOK':
            if (item['book'] is Map) {
              final book = BookDto.fromJson(
                Map<String, dynamic>.from(item['book'] as Map),
              );
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
      }
      final countsJson = json['counts'] is Map
          ? Map<String, dynamic>.from(json['counts'] as Map)
          : <String, dynamic>{};
      return BeBlogRepoResult.ok(
        SearchPageDto(
          hits: hits,
          total: (json['total'] as num?)?.toInt() ?? hits.length,
          counts: SearchCountsDto.fromJson(countsJson),
        ),
        response.statusCode,
      );
    } catch (error) {
      return BeBlogRepoResult.fail(
        response.statusCode,
        'Dữ liệu tìm kiếm không hợp lệ: $error',
      );
    }
  }
}
