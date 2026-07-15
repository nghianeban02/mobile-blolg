import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/be_blog_http.dart';
import 'package:mobile/core/network/be_blog_response_parser.dart';
import 'package:mobile/data/models/dtos.dart';

/// Mirrors [TagController], [GenreController], [AuthorController].
class BeBlogCatalogRepository {
  // --- Tags ---
  Future<BeBlogRepoResult<List<TagDto>>> getTags() async {
    final response = await BeBlogHttp.get(
      ApiConstants.tags,
      auth: false,
      query: const {'page': '0', 'size': '100'},
    );
    return BeBlogResponseParser.list(response, TagDto.fromJson);
  }

  Future<BeBlogRepoResult<TagDto>> getTag(String id) async {
    final response = await BeBlogHttp.get(
      '${ApiConstants.tags}/$id',
      auth: false,
    );
    return BeBlogResponseParser.one(response, TagDto.fromJson);
  }

  Future<BeBlogRepoResult<TagDto>> createTag(TagDto draft) async {
    final response = await BeBlogHttp.postJson(
      ApiConstants.tags,
      auth: true,
      body: _tagBody(draft, omitId: true),
    );
    return BeBlogResponseParser.one(response, TagDto.fromJson);
  }

  Future<BeBlogRepoResult<TagDto>> updateTag(String id, TagDto patch) async {
    final response = await BeBlogHttp.putJson(
      '${ApiConstants.tags}/$id',
      auth: true,
      body: _tagBody(patch, omitId: false),
    );
    return BeBlogResponseParser.one(response, TagDto.fromJson);
  }

  Future<BeBlogRepoResult<void>> deleteTag(String id) async {
    final response = await BeBlogHttp.delete(
      '${ApiConstants.tags}/$id',
      auth: true,
    );
    return BeBlogResponseParser.delete(response);
  }

  // --- Genres ---
  Future<BeBlogRepoResult<List<GenreDto>>> getGenres() async {
    final response = await BeBlogHttp.get(
      ApiConstants.genres,
      auth: false,
      query: const {'page': '0', 'size': '100'},
    );
    return BeBlogResponseParser.list(response, GenreDto.fromJson);
  }

  Future<BeBlogRepoResult<GenreDto>> getGenre(String id) async {
    final response = await BeBlogHttp.get(
      '${ApiConstants.genres}/$id',
      auth: false,
    );
    return BeBlogResponseParser.one(response, GenreDto.fromJson);
  }

  Future<BeBlogRepoResult<GenreDto>> createGenre(GenreDto draft) async {
    final response = await BeBlogHttp.postJson(
      ApiConstants.genres,
      auth: true,
      body: _genreBody(draft, omitId: true),
    );
    return BeBlogResponseParser.one(response, GenreDto.fromJson);
  }

  Future<BeBlogRepoResult<GenreDto>> updateGenre(
    String id,
    GenreDto patch,
  ) async {
    final response = await BeBlogHttp.putJson(
      '${ApiConstants.genres}/$id',
      auth: true,
      body: _genreBody(patch, omitId: false),
    );
    return BeBlogResponseParser.one(response, GenreDto.fromJson);
  }

  Future<BeBlogRepoResult<void>> deleteGenre(String id) async {
    final response = await BeBlogHttp.delete(
      '${ApiConstants.genres}/$id',
      auth: true,
    );
    return BeBlogResponseParser.delete(response);
  }

  // --- Authors ---
  Future<BeBlogRepoResult<List<AuthorDto>>> getAuthors() async {
    final response = await BeBlogHttp.get(
      ApiConstants.authors,
      auth: false,
      query: const {'page': '0', 'size': '100'},
    );
    return BeBlogResponseParser.list(response, AuthorDto.fromJson);
  }

  Future<BeBlogRepoResult<AuthorDto>> getAuthor(String id) async {
    final response = await BeBlogHttp.get(
      '${ApiConstants.authors}/$id',
      auth: false,
    );
    return BeBlogResponseParser.one(response, AuthorDto.fromJson);
  }

  Future<BeBlogRepoResult<AuthorDto>> createAuthor(AuthorDto draft) async {
    final response = await BeBlogHttp.postJson(
      ApiConstants.authors,
      auth: true,
      body: _authorBody(draft, omitId: true),
    );
    return BeBlogResponseParser.one(response, AuthorDto.fromJson);
  }

  Future<BeBlogRepoResult<AuthorDto>> updateAuthor(
    String id,
    AuthorDto patch,
  ) async {
    final response = await BeBlogHttp.putJson(
      '${ApiConstants.authors}/$id',
      auth: true,
      body: _authorBody(patch, omitId: false),
    );
    return BeBlogResponseParser.one(response, AuthorDto.fromJson);
  }

  Future<BeBlogRepoResult<void>> deleteAuthor(String id) async {
    final response = await BeBlogHttp.delete(
      '${ApiConstants.authors}/$id',
      auth: true,
    );
    return BeBlogResponseParser.delete(response);
  }

  Map<String, dynamic> _tagBody(TagDto t, {required bool omitId}) => {
    if (!omitId) 'id': t.id,
    'name': t.name,
    'slug': t.slug,
    'color': t.color,
  };

  Map<String, dynamic> _genreBody(GenreDto g, {required bool omitId}) => {
    if (!omitId) 'id': g.id,
    'name': g.name,
    'slug': g.slug,
  };

  Map<String, dynamic> _authorBody(AuthorDto a, {required bool omitId}) => {
    if (!omitId) 'id': a.id,
    'name': a.name,
    'slug': a.slug,
    'bio': a.bio,
    'photoUrl': a.photoUrl,
    if (a.createdAt != null) 'createdAt': a.createdAt!.toIso8601String(),
  };
}
