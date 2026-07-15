import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/be_blog_http.dart';
import 'package:mobile/core/network/be_blog_response_parser.dart';
import 'package:mobile/data/models/productivity_dtos.dart';

/// Complete client for `/api/notes/me`, including archive, trash, folders and labels.
class BeBlogNotesRepository {
  Future<BeBlogRepoResult<List<NoteDto>>> getNotes({
    String? folderId,
    int page = 0,
    int size = 50,
  }) => _list(
    ApiConstants.notesMe,
    query: {
      'page': '$page',
      'size': '$size',
      if (folderId != null && folderId.isNotEmpty) 'folderId': folderId,
    },
  );

  Future<BeBlogRepoResult<List<NoteDto>>> getArchived({
    int page = 0,
    int size = 50,
  }) => _list(
    '${ApiConstants.notesMe}/archived',
    query: {'page': '$page', 'size': '$size'},
  );

  Future<BeBlogRepoResult<List<NoteDto>>> getTrash({
    int page = 0,
    int size = 50,
  }) => _list(
    '${ApiConstants.notesMe}/trash',
    query: {'page': '$page', 'size': '$size'},
  );

  Future<BeBlogRepoResult<List<NoteDto>>> search(
    String query, {
    int page = 0,
    int size = 50,
  }) => _list(
    '${ApiConstants.notesMe}/search',
    query: {'q': query.trim(), 'page': '$page', 'size': '$size'},
  );

  Future<BeBlogRepoResult<List<NoteDto>>> _list(
    String path, {
    Map<String, String>? query,
  }) async {
    final response = await BeBlogHttp.get(path, query: query);
    return BeBlogResponseParser.list(response, NoteDto.fromJson);
  }

  Future<BeBlogRepoResult<NoteStatsDto>> stats() async {
    final response = await BeBlogHttp.get('${ApiConstants.notesMe}/stats');
    return BeBlogResponseParser.one(response, NoteStatsDto.fromJson);
  }

  Future<BeBlogRepoResult<NoteDto>> getOne(String id) async {
    final response = await BeBlogHttp.get('${ApiConstants.notesMe}/$id');
    return BeBlogResponseParser.one(response, NoteDto.fromJson);
  }

  Future<BeBlogRepoResult<NoteDto>> create(NoteWriteRequest request) async {
    final response = await BeBlogHttp.postJson(
      ApiConstants.notesMe,
      body: request.toJson(),
    );
    return BeBlogResponseParser.one(response, NoteDto.fromJson);
  }

  Future<BeBlogRepoResult<NoteDto>> update(
    String id,
    NoteWriteRequest request,
  ) async {
    final response = await BeBlogHttp.putJson(
      '${ApiConstants.notesMe}/$id',
      body: request.toJson(),
    );
    return BeBlogResponseParser.one(response, NoteDto.fromJson);
  }

  Future<BeBlogRepoResult<void>> moveToTrash(String id) async {
    final response = await BeBlogHttp.delete('${ApiConstants.notesMe}/$id');
    return BeBlogResponseParser.delete(response);
  }

  Future<BeBlogRepoResult<void>> restore(String id) async {
    final response = await BeBlogHttp.postEmpty(
      '${ApiConstants.notesMe}/$id/restore',
    );
    return BeBlogResponseParser.delete(response);
  }

  Future<BeBlogRepoResult<void>> permanentDelete(String id) async {
    final response = await BeBlogHttp.delete(
      '${ApiConstants.notesMe}/$id/permanent',
    );
    return BeBlogResponseParser.delete(response);
  }

  Future<BeBlogRepoResult<int>> emptyTrash() async {
    final response = await BeBlogHttp.delete('${ApiConstants.notesMe}/trash');
    if (!BeBlogResponseParser.isSuccess(response.statusCode)) {
      return BeBlogRepoResult.fail(
        response.statusCode,
        BeBlogHttp.extractServerMessage(response.body),
      );
    }
    try {
      final body = BeBlogHttp.decodeJsonObject(
        BeBlogHttp.decodeBody(response.body),
      );
      return BeBlogRepoResult.ok(
        (body['deleted'] as num?)?.toInt() ?? 0,
        response.statusCode,
      );
    } catch (e) {
      return BeBlogRepoResult.fail(response.statusCode, 'Parse error: $e');
    }
  }

  Future<BeBlogRepoResult<NoteDto>> togglePin(String id) =>
      _postNoteAction(id, 'pin');

  Future<BeBlogRepoResult<NoteDto>> archive(String id) =>
      _postNoteAction(id, 'archive');

  Future<BeBlogRepoResult<NoteDto>> unarchive(String id) =>
      _postNoteAction(id, 'unarchive');

  Future<BeBlogRepoResult<NoteDto>> duplicate(String id) =>
      _postNoteAction(id, 'duplicate');

  Future<BeBlogRepoResult<NoteDto>> _postNoteAction(
    String id,
    String action,
  ) async {
    final response = await BeBlogHttp.postEmpty(
      '${ApiConstants.notesMe}/$id/$action',
    );
    return BeBlogResponseParser.one(response, NoteDto.fromJson);
  }

  Future<BeBlogRepoResult<NoteDto>> moveToFolder(
    String id,
    String? folderId,
  ) async {
    final response = await BeBlogHttp.putJson(
      '${ApiConstants.notesMe}/$id/folder',
      query: {
        if (folderId != null && folderId.isNotEmpty) 'folderId': folderId,
      },
    );
    return BeBlogResponseParser.one(response, NoteDto.fromJson);
  }

  Future<BeBlogRepoResult<List<NoteFolderDto>>> getFolders() async {
    final response = await BeBlogHttp.get(ApiConstants.noteFolders);
    return BeBlogResponseParser.list(response, NoteFolderDto.fromJson);
  }

  Future<BeBlogRepoResult<NoteFolderDto>> createFolder({
    required String name,
    String? icon,
    String color = 'default',
  }) async {
    final response = await BeBlogHttp.postJson(
      ApiConstants.noteFolders,
      body: {'name': name.trim(), 'icon': icon, 'color': color},
    );
    return BeBlogResponseParser.one(response, NoteFolderDto.fromJson);
  }

  Future<BeBlogRepoResult<void>> deleteFolder(String id) async {
    final response = await BeBlogHttp.delete('${ApiConstants.noteFolders}/$id');
    return BeBlogResponseParser.delete(response);
  }

  Future<BeBlogRepoResult<List<NoteLabelDto>>> getLabels() async {
    final response = await BeBlogHttp.get(ApiConstants.noteLabels);
    return BeBlogResponseParser.list(response, NoteLabelDto.fromJson);
  }

  Future<BeBlogRepoResult<NoteLabelDto>> createLabel({
    required String name,
    String color = 'default',
  }) async {
    final response = await BeBlogHttp.postJson(
      ApiConstants.noteLabels,
      body: {'name': name.trim(), 'color': color},
    );
    return BeBlogResponseParser.one(response, NoteLabelDto.fromJson);
  }

  Future<BeBlogRepoResult<void>> deleteLabel(String id) async {
    final response = await BeBlogHttp.delete('${ApiConstants.noteLabels}/$id');
    return BeBlogResponseParser.delete(response);
  }
}
