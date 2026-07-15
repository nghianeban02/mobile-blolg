import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/be_blog_http.dart';
import 'package:mobile/core/network/be_blog_response_parser.dart';
import 'package:mobile/data/models/dtos.dart';

/// Mirrors [FriendController] — `/api/friends`.
class BeBlogFriendsRepository {
  Future<BeBlogRepoResult<List<UserPublicDto>>> listFriends() async {
    final response = await BeBlogHttp.get(ApiConstants.friends);
    return BeBlogResponseParser.list(response, UserPublicDto.fromJson);
  }

  Future<BeBlogRepoResult<List<FriendshipDto>>> incomingRequests() async {
    final response = await BeBlogHttp.get(ApiConstants.friendsRequestsIncoming);
    return BeBlogResponseParser.list(response, FriendshipDto.fromJson);
  }

  Future<BeBlogRepoResult<List<FriendshipDto>>> outgoingRequests() async {
    final response = await BeBlogHttp.get(ApiConstants.friendsRequestsOutgoing);
    return BeBlogResponseParser.list(response, FriendshipDto.fromJson);
  }

  Future<BeBlogRepoResult<FriendshipDto>> sendRequest(String userId) async {
    final response = await BeBlogHttp.postEmpty(
      '${ApiConstants.friends}/requests/$userId',
    );
    return BeBlogResponseParser.one(response, FriendshipDto.fromJson);
  }

  Future<BeBlogRepoResult<FriendshipDto>> acceptRequest(
    String requestId,
  ) async {
    final response = await BeBlogHttp.postEmpty(
      '${ApiConstants.friends}/requests/$requestId/accept',
    );
    return BeBlogResponseParser.one(response, FriendshipDto.fromJson);
  }

  Future<BeBlogRepoResult<void>> rejectRequest(String requestId) async {
    final response = await BeBlogHttp.postEmpty(
      '${ApiConstants.friends}/requests/$requestId/reject',
    );
    return BeBlogResponseParser.delete(response);
  }

  Future<BeBlogRepoResult<void>> cancelRequest(String requestId) async {
    final response = await BeBlogHttp.delete(
      '${ApiConstants.friends}/requests/$requestId',
    );
    return BeBlogResponseParser.delete(response);
  }

  Future<BeBlogRepoResult<void>> unfriend(String userId) async {
    final response = await BeBlogHttp.delete('${ApiConstants.friends}/$userId');
    return BeBlogResponseParser.delete(response);
  }
}
