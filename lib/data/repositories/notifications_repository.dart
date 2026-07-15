import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/be_blog_http.dart';
import 'package:mobile/core/network/be_blog_response_parser.dart';
import 'package:mobile/data/models/dtos.dart';

/// Mirrors [NotificationController].
class BeBlogNotificationsRepository {
  Future<BeBlogRepoResult<List<NotificationDto>>> list({
    int page = 0,
    int size = 50,
  }) async {
    final response = await BeBlogHttp.get(
      ApiConstants.notifications,
      query: {'page': '$page', 'size': '$size'},
    );
    return BeBlogResponseParser.list(response, NotificationDto.fromJson);
  }

  Future<BeBlogRepoResult<int>> unreadCount() async {
    final response = await BeBlogHttp.get(
      ApiConstants.notificationsUnreadCount,
    );
    if (!BeBlogResponseParser.isSuccess(response.statusCode)) {
      return BeBlogRepoResult.fail(
        response.statusCode,
        BeBlogHttp.extractServerMessage(response.body),
      );
    }
    try {
      final map = BeBlogHttp.decodeJsonObject(
        BeBlogHttp.decodeBody(response.body),
      );
      final count = map['unreadCount'];
      final value = count is int ? count : (count as num?)?.toInt() ?? 0;
      return BeBlogRepoResult.ok(value, response.statusCode);
    } catch (e) {
      return BeBlogRepoResult.fail(response.statusCode, 'Parse error: $e');
    }
  }

  Future<BeBlogRepoResult<NotificationDto>> markRead(String id) async {
    final response = await BeBlogHttp.patchJson(
      ApiConstants.notificationMarkRead(id),
      auth: true,
    );
    return BeBlogResponseParser.one(response, NotificationDto.fromJson);
  }

  Future<BeBlogRepoResult<void>> markAllRead() async {
    final response = await BeBlogHttp.postEmpty(
      ApiConstants.notificationsMarkAllRead,
      auth: true,
    );
    return BeBlogResponseParser.delete(response);
  }
}
