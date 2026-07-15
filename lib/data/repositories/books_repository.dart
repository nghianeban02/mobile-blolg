import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:mobile/core/cache/api_list_cache.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/be_blog_http.dart';
import 'package:mobile/core/network/be_blog_response_parser.dart';
import 'package:mobile/data/models/dtos.dart';

/// Mirrors [BookController].
class BeBlogBooksRepository {
  Future<BeBlogRepoResult<List<BookDto>>> getAll({
    bool forceRefresh = false,
  }) async {
    return ApiListCache.getOrFetch(
      key: ApiListCache.booksKey,
      forceRefresh: forceRefresh,
      fetch: () async {
        final response = await BeBlogHttp.get(
          ApiConstants.books,
          query: const {'page': '0', 'size': '100'},
        );
        return BeBlogResponseParser.list(response, BookDto.fromJson);
      },
    );
  }

  /// Current user's books: `GET /api/books/me`.
  Future<BeBlogRepoResult<List<BookDto>>> getMine({
    bool forceRefresh = false,
  }) async {
    return ApiListCache.getOrFetch(
      key: ApiListCache.myBooksKey,
      forceRefresh: forceRefresh,
      fetch: () async {
        final response = await BeBlogHttp.get(
          ApiConstants.booksMe,
          query: const {'page': '0', 'size': '100'},
        );
        return BeBlogResponseParser.list(response, BookDto.fromJson);
      },
    );
  }

  Future<BeBlogRepoResult<BookDto>> getOne(
    String id, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = ApiListCache.peek<BookDto>(ApiListCache.booksKey);
      if (cached != null) {
        for (final book in cached) {
          if (book.id == id) return BeBlogRepoResult.ok(book);
        }
      }
    }
    final response = await BeBlogHttp.get('${ApiConstants.books}/$id');
    return BeBlogResponseParser.one(response, BookDto.fromJson);
  }

  Future<BeBlogRepoResult<BookDto>> create(BookDto draft) async {
    final response = await BeBlogHttp.postJson(
      ApiConstants.books,
      auth: true,
      body: _bookToJson(draft, clearId: true),
    );
    final result = BeBlogResponseParser.one(response, BookDto.fromJson);
    if (result.success) ApiListCache.invalidateBooks();
    return result;
  }

  /// Multipart create with optional cover file (`POST /api/books`).
  Future<BeBlogRepoResult<BookDto>> createMultipart({
    required String title,
    String? description,
    String? isbn,
    String? language,
    int? pageCount,
    DateTime? publishedDate,
    File? coverImageFile,
  }) async {
    final uri = BeBlogHttp.uri(ApiConstants.books);
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(await BeBlogHttp.multipartHeaders(auth: true));
    request.fields['title'] = title;
    if (description != null && description.isNotEmpty) {
      request.fields['description'] = description;
    }
    if (isbn != null && isbn.isNotEmpty) request.fields['isbn'] = isbn;
    if (language != null && language.isNotEmpty) {
      request.fields['language'] = language;
    }
    if (pageCount != null) {
      request.fields['pageCount'] = pageCount.toString();
    }
    if (publishedDate != null) {
      final d = publishedDate;
      request.fields['publishedDate'] =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }
    if (coverImageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('coverImage', coverImageFile.path),
      );
    }

    try {
      final streamed = await request.send().timeout(
        ApiConstants.connectTimeout,
      );
      final response = await http.Response.fromStream(streamed);
      final result = BeBlogResponseParser.one(response, BookDto.fromJson);
      if (result.success) {
        ApiListCache.invalidateBooks();
        ApiListCache.invalidateFeed();
      }
      return result;
    } catch (e) {
      return BeBlogRepoResult.fail(0, e.toString());
    }
  }

  Future<BeBlogRepoResult<BookDto>> update(String id, BookDto patch) async {
    final response = await BeBlogHttp.putJson(
      '${ApiConstants.books}/$id',
      auth: true,
      body: _bookToJson(patch, clearId: false),
    );
    final result = BeBlogResponseParser.one(response, BookDto.fromJson);
    if (result.success) ApiListCache.invalidateBooks();
    return result;
  }

  Future<BeBlogRepoResult<BookDto>> updateMultipart({
    required String id,
    required String title,
    String? description,
    String? isbn,
    String? language,
    int? pageCount,
    DateTime? publishedDate,
    File? coverImageFile,
  }) async {
    final request = http.MultipartRequest(
      'PUT',
      BeBlogHttp.uri('${ApiConstants.books}/$id'),
    );
    request.headers.addAll(await BeBlogHttp.multipartHeaders(auth: true));
    request.fields['title'] = title;
    if (description?.isNotEmpty == true) {
      request.fields['description'] = description!;
    }
    if (isbn?.isNotEmpty == true) request.fields['isbn'] = isbn!;
    if (language?.isNotEmpty == true) request.fields['language'] = language!;
    if (pageCount != null) request.fields['pageCount'] = '$pageCount';
    if (publishedDate != null) {
      request.fields['publishedDate'] =
          '${publishedDate.year.toString().padLeft(4, '0')}-'
          '${publishedDate.month.toString().padLeft(2, '0')}-'
          '${publishedDate.day.toString().padLeft(2, '0')}';
    }
    if (coverImageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('coverImage', coverImageFile.path),
      );
    }
    try {
      final streamed = await request.send().timeout(
        ApiConstants.connectTimeout,
      );
      final response = await http.Response.fromStream(streamed);
      final result = BeBlogResponseParser.one(response, BookDto.fromJson);
      if (result.success) ApiListCache.invalidateBooks();
      return result;
    } catch (error) {
      return BeBlogRepoResult.fail(0, error.toString());
    }
  }

  Future<BeBlogRepoResult<void>> delete(String id) async {
    final response = await BeBlogHttp.delete(
      '${ApiConstants.books}/$id',
      auth: true,
    );
    final result = BeBlogResponseParser.delete(response);
    if (result.success) ApiListCache.invalidateBooks();
    return result;
  }

  Future<BeBlogRepoResult<List<BookAuthorDto>>> getAuthors(
    String bookId,
  ) async {
    final response = await BeBlogHttp.get(
      '${ApiConstants.books}/$bookId/authors',
    );
    return BeBlogResponseParser.list(response, BookAuthorDto.fromJson);
  }

  Future<BeBlogRepoResult<BookAuthorDto>> addAuthor({
    required String bookId,
    required String authorId,
    String? role,
  }) async {
    final response = await BeBlogHttp.postJson(
      '${ApiConstants.books}/$bookId/authors',
      auth: true,
      body: {'authorId': authorId, 'role': ?role},
    );
    return BeBlogResponseParser.one(response, BookAuthorDto.fromJson);
  }

  Future<BeBlogRepoResult<void>> removeAuthor({
    required String bookId,
    required String authorId,
  }) async {
    final response = await BeBlogHttp.delete(
      '${ApiConstants.books}/$bookId/authors/$authorId',
      auth: true,
    );
    return BeBlogResponseParser.delete(response);
  }

  Future<BeBlogRepoResult<List<BookGenreDto>>> getGenres(String bookId) async {
    final response = await BeBlogHttp.get(
      '${ApiConstants.books}/$bookId/genres',
    );
    return BeBlogResponseParser.list(response, BookGenreDto.fromJson);
  }

  Future<BeBlogRepoResult<BookGenreDto>> addGenre({
    required String bookId,
    required String genreId,
  }) async {
    final response = await BeBlogHttp.postJson(
      '${ApiConstants.books}/$bookId/genres',
      auth: true,
      body: {'genreId': genreId},
    );
    return BeBlogResponseParser.one(response, BookGenreDto.fromJson);
  }

  Future<BeBlogRepoResult<void>> removeGenre({
    required String bookId,
    required String genreId,
  }) async {
    final response = await BeBlogHttp.delete(
      '${ApiConstants.books}/$bookId/genres/$genreId',
      auth: true,
    );
    return BeBlogResponseParser.delete(response);
  }

  Map<String, dynamic> _bookToJson(BookDto b, {required bool clearId}) {
    return {
      if (!clearId && b.id.isNotEmpty) 'id': b.id,
      'title': b.title,
      'isbn': b.isbn,
      'description': b.description,
      'coverImageUrl': b.coverImageUrl,
      if (b.publishedDate != null)
        'publishedDate': b.publishedDate!.toIso8601String().split('T').first,
      'pageCount': b.pageCount,
      'language': b.language,
      if (b.createdAt != null) 'createdAt': b.createdAt!.toIso8601String(),
    };
  }
}
