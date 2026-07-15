// JSON models aligned with **be-blog** entities / DTOs (camelCase from Jackson).

import 'package:mobile/core/constants/api_url_remap.dart';

class PostGalleryImageDto {
  final String id;
  final String url;
  final int sortOrder;

  const PostGalleryImageDto({
    required this.id,
    required this.url,
    this.sortOrder = 0,
  });

  factory PostGalleryImageDto.fromJson(Map<String, dynamic> json) {
    return PostGalleryImageDto(
      id: json['id'].toString(),
      url: json['url'] as String? ?? '',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  String resolveUrl(String baseUrl) => _toAbsoluteUrl(url, baseUrl);
}

/// Trạng thái duyệt bài (be-blog `PostStatus`).
enum PostStatus { pending, approved, rejected, unknown }

PostStatus postStatusFromApi(String? raw) {
  switch (raw?.toUpperCase()) {
    case 'PENDING':
      return PostStatus.pending;
    case 'APPROVED':
      return PostStatus.approved;
    case 'REJECTED':
      return PostStatus.rejected;
    default:
      return PostStatus.unknown;
  }
}

class PostDto {
  final String id;
  final String? userId;
  final String title;
  final String content;

  /// Ảnh tiêu đề (API: `titleImageUrl`, alias `imageUrl`).
  final String? titleImageUrl;
  final List<PostGalleryImageDto> galleryImages;
  final DateTime? createdAt;
  final bool canDelete;
  final bool canEdit;
  final bool canApprove;
  final PostStatus status;
  final String? rejectionReason;

  const PostDto({
    required this.id,
    this.userId,
    required this.title,
    required this.content,
    this.titleImageUrl,
    this.galleryImages = const [],
    this.createdAt,
    this.canDelete = false,
    this.canEdit = false,
    this.canApprove = false,
    this.status = PostStatus.unknown,
    this.rejectionReason,
  });

  factory PostDto.fromJson(Map<String, dynamic> json) {
    final galleryRaw = json['galleryImages'];
    return PostDto(
      id: json['id'].toString(),
      userId: json['userId']?.toString(),
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      titleImageUrl:
          json['titleImageUrl'] as String? ?? json['imageUrl'] as String?,
      galleryImages: galleryRaw is List
          ? galleryRaw
                .map(
                  (e) => PostGalleryImageDto.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ),
                )
                .toList()
          : const [],
      createdAt: _parseDateTime(json['createdAt']),
      canDelete: json['canDelete'] as bool? ?? false,
      canEdit: json['canEdit'] as bool? ?? false,
      canApprove: json['canApprove'] as bool? ?? false,
      status: postStatusFromApi(json['status'] as String?),
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  bool get isPending => status == PostStatus.pending;
  bool get isRejected => status == PostStatus.rejected;

  /// Absolute URL for ảnh tiêu đề (`GET /api/images/posts/{id}/title`).
  String resolveTitleImageUrl(String baseUrl) {
    if (titleImageUrl != null && titleImageUrl!.isNotEmpty) {
      return _toAbsoluteUrl(titleImageUrl!, baseUrl);
    }
    return '$baseUrl/api/images/posts/$id/title';
  }

  /// Có ảnh tiêu đề (URL từ API hoặc endpoint mặc định).
  bool get hasTitleImage => titleImageUrl != null && titleImageUrl!.isNotEmpty;

  /// @deprecated dùng [resolveTitleImageUrl].
  String resolveImageUrl(String baseUrl) => resolveTitleImageUrl(baseUrl);
}

/// Ghép path tương đối hoặc sửa URL tuyệt đối từ server (thường là `localhost`).
String _toAbsoluteUrl(String path, String baseUrl) {
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return remapDevAssetUrl(path, baseUrl);
  }
  // Support inline images (base64) stored in coverImageUrl.
  // We must not prefix `baseUrl` before data scheme.
  if (path.startsWith('data:')) return path;
  return '$baseUrl${path.startsWith('/') ? '' : '/'}$path';
}

class BookDto {
  final String id;
  final String title;
  final String? isbn;
  final String? description;
  final String? coverImageUrl;
  final DateTime? publishedDate;
  final int? pageCount;
  final String? language;
  final DateTime? createdAt;

  const BookDto({
    required this.id,
    required this.title,
    this.isbn,
    this.description,
    this.coverImageUrl,
    this.publishedDate,
    this.pageCount,
    this.language,
    this.createdAt,
  });

  factory BookDto.fromJson(Map<String, dynamic> json) {
    return BookDto(
      id: json['id'].toString(),
      title: json['title'] as String? ?? '',
      isbn: json['isbn'] as String?,
      description: json['description'] as String?,
      coverImageUrl: json['coverImageUrl'] as String?,
      publishedDate: _parseDate(json['publishedDate']),
      pageCount: (json['pageCount'] as num?)?.toInt(),
      language: json['language'] as String?,
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  bool get hasCoverImage =>
      coverImageUrl != null &&
      coverImageUrl!.isNotEmpty &&
      !coverImageUrl!.startsWith('data:');

  String? resolveCoverImageUrl(String baseUrl) {
    if (hasCoverImage) {
      return _toAbsoluteUrl(coverImageUrl!, baseUrl);
    }
    if (id.isNotEmpty) {
      return '$baseUrl/api/images/books/$id/cover';
    }
    return null;
  }
}

class ReviewDto {
  final String id;
  final String userId;
  final String bookId;
  final String title;
  final String content;
  final int rating;
  final bool containsSpoilers;
  final String status;
  final int readCount;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ReviewDto({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.title,
    required this.content,
    required this.rating,
    required this.containsSpoilers,
    required this.status,
    required this.readCount,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory ReviewDto.fromJson(Map<String, dynamic> json) {
    return ReviewDto(
      id: json['id'].toString(),
      userId: json['userId'].toString(),
      bookId: json['bookId'].toString(),
      title: json['title'] as String? ?? '',
      content:
          json['content'] as String? ?? json['contentPreview'] as String? ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      containsSpoilers: json['containsSpoilers'] as bool? ?? false,
      status: json['status'] as String? ?? 'draft',
      readCount: (json['readCount'] as num?)?.toInt() ?? 0,
      publishedAt: _parseDateTime(json['publishedAt']),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }
}

/// Request body for `POST/PUT /api/reviews`
class ReviewWriteRequest {
  final String bookId;
  final String title;
  final String content;
  final int rating;
  final bool? containsSpoilers;
  final String? status;
  final DateTime? publishedAt;

  const ReviewWriteRequest({
    required this.bookId,
    required this.title,
    required this.content,
    required this.rating,
    this.containsSpoilers,
    this.status,
    this.publishedAt,
  });

  Map<String, dynamic> toJson() => {
    'bookId': bookId,
    'title': title,
    'content': content,
    'rating': rating,
    if (containsSpoilers != null) 'containsSpoilers': containsSpoilers,
    if (status != null) 'status': status,
    if (publishedAt != null) 'publishedAt': publishedAt!.toIso8601String(),
  };
}

class CommentDto {
  final String id;
  final String? reviewId;
  final String? postId;
  final String userId;
  final String? username;
  final String? parentId;
  final String? rootId;
  final String content;
  final bool isApproved;
  final bool canEdit;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<CommentDto> replies;

  const CommentDto({
    required this.id,
    this.reviewId,
    this.postId,
    required this.userId,
    this.username,
    this.parentId,
    this.rootId,
    required this.content,
    required this.isApproved,
    this.canEdit = false,
    this.createdAt,
    this.updatedAt,
    this.replies = const [],
  });

  bool get isReply => parentId != null && parentId!.isNotEmpty;

  int get threadSize => 1 + replies.length;

  factory CommentDto.fromJson(Map<String, dynamic> json) {
    final repliesRaw = json['replies'];
    return CommentDto(
      id: json['id'].toString(),
      reviewId: json['reviewId']?.toString(),
      postId: json['postId']?.toString(),
      userId: json['userId'].toString(),
      username: json['username'] as String?,
      parentId: json['parentId']?.toString(),
      rootId: json['rootId']?.toString(),
      content: json['content'] as String? ?? '',
      isApproved: json['isApproved'] as bool? ?? false,
      canEdit: json['canEdit'] as bool? ?? false,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      replies: repliesRaw is List
          ? repliesRaw
                .map(
                  (e) =>
                      CommentDto.fromJson(Map<String, dynamic>.from(e as Map)),
                )
                .toList()
          : const [],
    );
  }
}

class ReadingListDto {
  final String id;
  final String userId;
  final String bookId;
  final String status;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final DateTime? createdAt;

  const ReadingListDto({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.status,
    this.startedAt,
    this.finishedAt,
    this.createdAt,
  });

  factory ReadingListDto.fromJson(Map<String, dynamic> json) {
    return ReadingListDto(
      id: json['id'].toString(),
      userId: json['userId'].toString(),
      bookId: json['bookId'].toString(),
      status: json['status'] as String? ?? 'want_to_read',
      startedAt: _parseDate(json['startedAt']),
      finishedAt: _parseDate(json['finishedAt']),
      createdAt: _parseDateTime(json['createdAt']),
    );
  }
}

class ReadingListWriteRequest {
  final String bookId;
  final String? status;
  final DateTime? startedAt;
  final DateTime? finishedAt;

  const ReadingListWriteRequest({
    required this.bookId,
    this.status,
    this.startedAt,
    this.finishedAt,
  });

  Map<String, dynamic> toJson() => {
    'bookId': bookId,
    if (status != null) 'status': status,
    if (startedAt != null) 'startedAt': _dateOnly(startedAt!),
    if (finishedAt != null) 'finishedAt': _dateOnly(finishedAt!),
  };

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class TagDto {
  final String id;
  final String name;
  final String slug;
  final String? color;

  const TagDto({
    required this.id,
    required this.name,
    required this.slug,
    this.color,
  });

  factory TagDto.fromJson(Map<String, dynamic> json) {
    return TagDto(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      color: json['color'] as String?,
    );
  }
}

class GenreDto {
  final String id;
  final String name;
  final String slug;

  const GenreDto({required this.id, required this.name, required this.slug});

  factory GenreDto.fromJson(Map<String, dynamic> json) {
    return GenreDto(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
    );
  }
}

class AuthorDto {
  final String id;
  final String name;
  final String slug;
  final String? bio;
  final String? photoUrl;
  final DateTime? createdAt;

  const AuthorDto({
    required this.id,
    required this.name,
    required this.slug,
    this.bio,
    this.photoUrl,
    this.createdAt,
  });

  factory AuthorDto.fromJson(Map<String, dynamic> json) {
    return AuthorDto(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      bio: json['bio'] as String?,
      photoUrl: json['photoUrl'] as String?,
      createdAt: _parseDateTime(json['createdAt']),
    );
  }
}

/// Public author card on feed items.
class UserPublicDto {
  final String id;
  final String username;
  final String? avatarUrl;
  final String? bio;
  final String? title;

  const UserPublicDto({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.bio,
    this.title,
  });

  factory UserPublicDto.fromJson(Map<String, dynamic> json) {
    return UserPublicDto(
      id: json['id'].toString(),
      username: json['username'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      title: json['title'] as String?,
    );
  }

  String get displayName =>
      title?.trim().isNotEmpty == true ? title!.trim() : username;
}

/// `FriendshipResponse` from `/api/friends/**`.
class FriendshipDto {
  final String id;
  final String requesterId;
  final String addresseeId;
  final String status;
  final UserPublicDto? requester;
  final UserPublicDto? addressee;
  final DateTime? createdAt;
  final DateTime? respondedAt;

  const FriendshipDto({
    required this.id,
    required this.requesterId,
    required this.addresseeId,
    required this.status,
    this.requester,
    this.addressee,
    this.createdAt,
    this.respondedAt,
  });

  factory FriendshipDto.fromJson(Map<String, dynamic> json) {
    return FriendshipDto(
      id: json['id'].toString(),
      requesterId: json['requesterId'].toString(),
      addresseeId: json['addresseeId'].toString(),
      status: json['status'] as String? ?? '',
      requester: json['requester'] is Map
          ? UserPublicDto.fromJson(
              Map<String, dynamic>.from(json['requester'] as Map),
            )
          : null,
      addressee: json['addressee'] is Map
          ? UserPublicDto.fromJson(
              Map<String, dynamic>.from(json['addressee'] as Map),
            )
          : null,
      createdAt: _parseDateTime(json['createdAt']),
      respondedAt: _parseDateTime(json['respondedAt']),
    );
  }
}

/// `GET /api/feed` timeline item (`FeedItemResponse`).
enum FeedItemType { review, post }

class FeedItemDto {
  final FeedItemType type;
  final String id;
  final String? authorId;
  final UserPublicDto? author;
  final DateTime? createdAt;
  final ReviewDto? review;
  final PostDto? post;

  const FeedItemDto({
    required this.type,
    required this.id,
    this.authorId,
    this.author,
    this.createdAt,
    this.review,
    this.post,
  });

  factory FeedItemDto.fromJson(Map<String, dynamic> json) {
    final typeRaw = (json['type'] as String? ?? '').toUpperCase();
    final type = typeRaw == 'POST' ? FeedItemType.post : FeedItemType.review;
    final reviewJson = json['review'];
    final postJson = json['post'];
    return FeedItemDto(
      type: type,
      id: json['id'].toString(),
      authorId: json['authorId']?.toString(),
      author: json['author'] is Map
          ? UserPublicDto.fromJson(
              Map<String, dynamic>.from(json['author'] as Map),
            )
          : null,
      createdAt: _parseDateTime(json['createdAt']),
      review: reviewJson is Map
          ? ReviewDto.fromJson(Map<String, dynamic>.from(reviewJson))
          : null,
      post: postJson is Map
          ? PostDto.fromJson(Map<String, dynamic>.from(postJson))
          : null,
    );
  }
}

/// `GET /api/users/{id}/profile` — public profile + friendship context.
class UserProfileViewDto {
  final String id;
  final String username;
  final String? avatarUrl;
  final String? bio;
  final String? title;
  final String? feedVisibility;
  final DateTime? createdAt;
  final String? relationStatus;
  final bool canViewFeed;
  final int friendsCount;

  const UserProfileViewDto({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.bio,
    this.title,
    this.feedVisibility,
    this.createdAt,
    this.relationStatus,
    this.canViewFeed = false,
    this.friendsCount = 0,
  });

  factory UserProfileViewDto.fromJson(Map<String, dynamic> json) {
    return UserProfileViewDto(
      id: json['id'].toString(),
      username: json['username'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      title: json['title'] as String?,
      feedVisibility: json['feedVisibility'] as String?,
      createdAt: _parseDateTime(json['createdAt']),
      relationStatus: json['relationStatus'] as String?,
      canViewFeed: json['canViewFeed'] as bool? ?? false,
      friendsCount: (json['friendsCount'] as num?)?.toInt() ?? 0,
    );
  }

  String get displayName =>
      title?.trim().isNotEmpty == true ? title!.trim() : username;
}

/// Safe subset of `User` JSON (ignore passwordHash if present).
class UserProfileDto {
  final String id;
  final String username;
  final String? email;
  final String? avatarUrl;
  final String? bio;
  final String? title;
  final String? feedVisibility;
  final DateTime? createdAt;
  final String? roles;

  const UserProfileDto({
    required this.id,
    required this.username,
    this.email,
    this.avatarUrl,
    this.bio,
    this.title,
    this.feedVisibility,
    this.createdAt,
    this.roles,
  });

  factory UserProfileDto.fromJson(Map<String, dynamic> json) {
    return UserProfileDto(
      id: json['id'].toString(),
      username: json['username'] as String? ?? '',
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      title: json['title'] as String?,
      feedVisibility: json['feedVisibility'] as String?,
      createdAt: _parseDateTime(json['createdAt']),
      roles: json['roles'] as String?,
    );
  }

  bool get isAdmin =>
      roles != null && roles!.split(',').any((r) => r.trim() == 'ROLE_ADMIN');
}

class ReviewTagDto {
  final String reviewId;
  final String tagId;

  const ReviewTagDto({required this.reviewId, required this.tagId});

  factory ReviewTagDto.fromJson(Map<String, dynamic> json) {
    final nested = json['id'];
    if (nested is Map) {
      final m = Map<String, dynamic>.from(nested);
      return ReviewTagDto(
        reviewId: m['reviewId'].toString(),
        tagId: m['tagId'].toString(),
      );
    }
    return ReviewTagDto(
      reviewId: json['reviewId'].toString(),
      tagId: json['tagId'].toString(),
    );
  }
}

class BookAuthorDto {
  final String bookId;
  final String authorId;
  final String? role;

  const BookAuthorDto({
    required this.bookId,
    required this.authorId,
    this.role,
  });

  factory BookAuthorDto.fromJson(Map<String, dynamic> json) {
    final nested = json['id'];
    if (nested is Map) {
      final m = Map<String, dynamic>.from(nested);
      return BookAuthorDto(
        bookId: m['bookId'].toString(),
        authorId: m['authorId'].toString(),
        role: json['role'] as String?,
      );
    }
    return BookAuthorDto(
      bookId: json['bookId'].toString(),
      authorId: json['authorId'].toString(),
      role: json['role'] as String?,
    );
  }
}

class BookGenreDto {
  final String bookId;
  final String genreId;

  const BookGenreDto({required this.bookId, required this.genreId});

  factory BookGenreDto.fromJson(Map<String, dynamic> json) {
    final nested = json['id'];
    if (nested is Map) {
      final m = Map<String, dynamic>.from(nested);
      return BookGenreDto(
        bookId: m['bookId'].toString(),
        genreId: m['genreId'].toString(),
      );
    }
    return BookGenreDto(
      bookId: json['bookId'].toString(),
      genreId: json['genreId'].toString(),
    );
  }
}

/// Các loại cảm xúc — khớp `ReactionType` trên be-blog và bản web.
const List<String> kReactionTypes = ['HEART', 'WOW', 'CLAP', 'THINKING', 'SAD'];

const Map<String, String> kReactionEmoji = {
  'HEART': '💖',
  'WOW': '😍',
  'CLAP': '👏',
  'THINKING': '🤔',
  'SAD': '😢',
};

/// Trạng thái like của post/review — mirror `LikeStatus` trên web
/// (`GET/POST/DELETE …/likes` đều trả về shape này).
class LikeStatusDto {
  final int count;
  final bool likedByMe;

  /// Cảm xúc hiện tại của viewer (null khi chưa thả).
  final String? myReaction;

  /// Số lượng theo từng loại cảm xúc (chỉ chứa loại có count > 0).
  final Map<String, int> reactions;

  const LikeStatusDto({
    required this.count,
    required this.likedByMe,
    this.myReaction,
    this.reactions = const {},
  });

  factory LikeStatusDto.fromJson(Map<String, dynamic> json) {
    final rawReactions = json['reactions'];
    final reactions = <String, int>{};
    if (rawReactions is Map) {
      for (final entry in rawReactions.entries) {
        final key = entry.key.toString();
        final value = (entry.value as num?)?.toInt() ?? 0;
        if (kReactionTypes.contains(key) && value > 0) {
          reactions[key] = value;
        }
      }
    }
    final myReaction = json['myReaction']?.toString();
    return LikeStatusDto(
      count: (json['count'] as num?)?.toInt() ?? 0,
      likedByMe: json['likedByMe'] == true,
      myReaction: kReactionTypes.contains(myReaction) ? myReaction : null,
      reactions: reactions,
    );
  }
}

class ReviewLikeDto {
  final String id;
  final String userId;
  final String reviewId;
  final DateTime? createdAt;

  const ReviewLikeDto({
    required this.id,
    required this.userId,
    required this.reviewId,
    this.createdAt,
  });

  factory ReviewLikeDto.fromJson(Map<String, dynamic> json) {
    return ReviewLikeDto(
      id: json['id'].toString(),
      userId: json['userId'].toString(),
      reviewId: json['reviewId'].toString(),
      createdAt: _parseDateTime(json['createdAt']),
    );
  }
}

class PostLikeDto {
  final String id;
  final String userId;
  final String postId;
  final DateTime? createdAt;

  const PostLikeDto({
    required this.id,
    required this.userId,
    required this.postId,
    this.createdAt,
  });

  factory PostLikeDto.fromJson(Map<String, dynamic> json) {
    return PostLikeDto(
      id: json['id'].toString(),
      userId: json['userId'].toString(),
      postId: json['postId'].toString(),
      createdAt: _parseDateTime(json['createdAt']),
    );
  }
}

/// `GET /api/notifications` — aligned with [NotificationType] on be-blog.
enum NotificationType {
  reviewLike,
  postLike,
  reviewComment,
  reviewCommentReply,
  postComment,
  postCommentReply,
  friendRequest,
  friendRequestAccepted,
  unknown,
}

NotificationType notificationTypeFromApi(String? raw) {
  switch (raw) {
    case 'REVIEW_LIKE':
      return NotificationType.reviewLike;
    case 'POST_LIKE':
      return NotificationType.postLike;
    case 'REVIEW_COMMENT':
      return NotificationType.reviewComment;
    case 'REVIEW_COMMENT_REPLY':
      return NotificationType.reviewCommentReply;
    case 'POST_COMMENT':
      return NotificationType.postComment;
    case 'POST_COMMENT_REPLY':
      return NotificationType.postCommentReply;
    case 'FRIEND_REQUEST':
      return NotificationType.friendRequest;
    case 'FRIEND_REQUEST_ACCEPTED':
      return NotificationType.friendRequestAccepted;
    default:
      return NotificationType.unknown;
  }
}

class NotificationDto {
  final String id;
  final NotificationType type;
  final UserPublicDto? actor;
  final String? reviewId;
  final String? postId;
  final String? commentId;
  final String? friendshipId;
  final String message;
  final bool read;
  final DateTime? createdAt;

  const NotificationDto({
    required this.id,
    required this.type,
    this.actor,
    this.reviewId,
    this.postId,
    this.commentId,
    this.friendshipId,
    required this.message,
    this.read = false,
    this.createdAt,
  });

  factory NotificationDto.fromJson(Map<String, dynamic> json) {
    final actorJson = json['actor'];
    return NotificationDto(
      id: json['id'].toString(),
      type: notificationTypeFromApi(json['type'] as String?),
      actor: actorJson is Map
          ? UserPublicDto.fromJson(Map<String, dynamic>.from(actorJson))
          : null,
      reviewId: json['reviewId']?.toString(),
      postId: json['postId']?.toString(),
      commentId: json['commentId']?.toString(),
      friendshipId: json['friendshipId']?.toString(),
      message: json['message'] as String? ?? '',
      read:
          json['read'] as bool? ??
          json['isRead'] as bool? ??
          json['readFlag'] as bool? ??
          false,
      createdAt: _parseDateTime(json['createdAt']),
    );
  }
}

DateTime? _parseDateTime(dynamic v) {
  if (v == null) return null;
  if (v is String && v.isNotEmpty) {
    return DateTime.tryParse(v);
  }
  return null;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is String && v.isNotEmpty) {
    final d = DateTime.tryParse(v);
    return d;
  }
  return null;
}
