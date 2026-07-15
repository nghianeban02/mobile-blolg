import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Shared disk cache for post/review images (7 days, capped object count).
class AppImageCache {
  AppImageCache._();

  static const _cacheKey = 'mobile_blog_images';

  static final CacheManager manager = CacheManager(
    Config(
      _cacheKey,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 250,
    ),
  );
}
