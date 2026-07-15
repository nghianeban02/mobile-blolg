import 'package:flutter/foundation.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/images/app_image_cache.dart';
import 'package:mobile/core/images/image_auth_headers.dart';
import 'package:mobile/data/models/dtos.dart';

/// Warms disk cache for post cover images (e.g. right after home loads).
class PostImagePrefetch {
  PostImagePrefetch._();

  static const int _maxCovers = 8;

  /// Fire-and-forget prefetch; safe to call after every home refresh.
  static void prefetchPostCovers(List<PostDto> posts, {int? maxCount}) {
    final limit = maxCount ?? _maxCovers;
    final urls = <String>[];
    for (final post in posts) {
      if (urls.length >= limit) break;
      if (!post.hasTitleImage) continue;
      urls.add(post.resolveTitleImageUrl(ApiConstants.baseUrl));
    }
    if (urls.isEmpty) return;
    _prefetchUrls(urls);
  }

  static void _prefetchUrls(List<String> urls) {
    Future<void>(() async {
      final headers = await ImageAuthHeaders.get();
      await Future.wait(
        urls.map((url) async {
          try {
            await AppImageCache.manager.downloadFile(url, authHeaders: headers);
          } catch (e, st) {
            if (kDebugMode) {
              debugPrint('Prefetch failed: $url — $e\n$st');
            }
          }
        }),
        eagerError: false,
      );
    });
  }
}
