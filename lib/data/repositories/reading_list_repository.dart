import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/be_blog_http.dart';
import 'package:mobile/core/network/be_blog_response_parser.dart';
import 'package:mobile/data/models/dtos.dart';

/// Mirrors [ReadingListController].
class BeBlogReadingListRepository {
  Future<BeBlogRepoResult<List<ReadingListDto>>> getMine() async {
    final response = await BeBlogHttp.get(
      ApiConstants.readingListMe,
      auth: true,
    );
    return BeBlogResponseParser.list(response, ReadingListDto.fromJson);
  }

  Future<BeBlogRepoResult<ReadingListDto>> add(
    ReadingListWriteRequest req,
  ) async {
    final response = await BeBlogHttp.postJson(
      ApiConstants.readingListMe,
      auth: true,
      body: req.toJson(),
    );
    return BeBlogResponseParser.one(response, ReadingListDto.fromJson);
  }

  Future<BeBlogRepoResult<ReadingListDto>> update(
    String id,
    ReadingListWriteRequest req,
  ) async {
    final response = await BeBlogHttp.putJson(
      '${ApiConstants.readingListMe}/$id',
      auth: true,
      body: req.toJson(),
    );
    return BeBlogResponseParser.one(response, ReadingListDto.fromJson);
  }

  Future<BeBlogRepoResult<void>> remove(String id) async {
    final response = await BeBlogHttp.delete(
      '${ApiConstants.readingListMe}/$id',
      auth: true,
    );
    return BeBlogResponseParser.delete(response);
  }
}
