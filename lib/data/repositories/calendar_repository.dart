import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/be_blog_http.dart';
import 'package:mobile/core/network/be_blog_response_parser.dart';
import 'package:mobile/data/models/productivity_dtos.dart';

class BeBlogCalendarRepository {
  Future<BeBlogRepoResult<List<CalendarEntryDto>>> getEntries({
    required DateTime from,
    required DateTime to,
  }) async {
    final response = await BeBlogHttp.get(
      ApiConstants.calendarMe,
      query: {'from': _date(from), 'to': _date(to)},
    );
    return BeBlogResponseParser.list(response, CalendarEntryDto.fromJson);
  }

  Future<BeBlogRepoResult<CalendarEntryDto>> create(
    CalendarEntryDto entry,
  ) async {
    final response = await BeBlogHttp.postJson(
      ApiConstants.calendarMe,
      body: entry.toJson(),
    );
    return BeBlogResponseParser.one(response, CalendarEntryDto.fromJson);
  }

  Future<BeBlogRepoResult<CalendarEntryDto>> update(
    CalendarEntryDto entry,
  ) async {
    final response = await BeBlogHttp.putJson(
      '${ApiConstants.calendarMe}/${entry.id}',
      body: entry.toJson(),
    );
    return BeBlogResponseParser.one(response, CalendarEntryDto.fromJson);
  }

  Future<BeBlogRepoResult<void>> delete(String id) async {
    final response = await BeBlogHttp.delete('${ApiConstants.calendarMe}/$id');
    return BeBlogResponseParser.delete(response);
  }

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
