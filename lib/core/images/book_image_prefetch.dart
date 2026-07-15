import 'package:flutter/foundation.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/images/app_image_cache.dart';
import 'package:mobile/core/images/image_auth_headers.dart';
import 'package:mobile/data/models/dtos.dart';

/// Warms disk cache for book cover URLs after library/home loads.
class BookImagePrefetch {
  BookImagePrefetch._();

  static const int _maxCovers = 10;

  static void prefetchBookCovers(List<BookDto> books, {int? maxCount}) {
    final limit = maxCount ?? _maxCovers;
    final urls = <String>[];
    for (final book in books) {
      if (urls.length >= limit) break;
      if (!book.hasCoverImage) continue;
      final url = book.resolveCoverImageUrl(ApiConstants.baseUrl);
      if (url == null || url.startsWith('data:')) continue;
      urls.add(url);
    }
    if (urls.isEmpty) return;

    Future<void>(() async {
      final headers = await ImageAuthHeaders.get();
      await Future.wait(
        urls.map((url) async {
          try {
            await AppImageCache.manager.downloadFile(url, authHeaders: headers);
          } catch (e, st) {
            if (kDebugMode) {
              debugPrint('Book prefetch failed: $url — $e\n$st');
            }
          }
        }),
        eagerError: false,
      );
    });
  }
}
