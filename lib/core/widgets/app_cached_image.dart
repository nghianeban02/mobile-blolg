import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/images/app_image_cache.dart';
import 'package:mobile/core/images/image_auth_headers.dart';

/// Network image with JWT for protected `/api/images/**` URLs.
class AppCachedImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final Color fallbackColor;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final bool showTapHint;

  const AppCachedImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.fallbackColor = AppColors.coverSand,
    this.onTap,
    this.width,
    this.height,
    this.memCacheWidth,
    this.memCacheHeight,
    this.showTapHint = false,
  });

  factory AppCachedImage.sized({
    Key? key,
    required BuildContext context,
    required String url,
    required double logicalWidth,
    required double logicalHeight,
    BoxFit fit = BoxFit.cover,
    Color fallbackColor = AppColors.coverSand,
    VoidCallback? onTap,
    bool showTapHint = false,
  }) {
    final ratio = MediaQuery.devicePixelRatioOf(context);
    return AppCachedImage(
      key: key,
      url: url,
      fit: fit,
      fallbackColor: fallbackColor,
      onTap: onTap,
      width: logicalWidth,
      height: logicalHeight,
      memCacheWidth: (logicalWidth * ratio).round(),
      memCacheHeight: (logicalHeight * ratio).round(),
      showTapHint: showTapHint,
    );
  }

  static int decodePixels(BuildContext context, double logicalSize) {
    return (logicalSize * MediaQuery.devicePixelRatioOf(context)).round();
  }

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _errorBox();

    return FutureBuilder<Map<String, String>>(
      future: ImageAuthHeaders.get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _loadingBox();

        final image = CachedNetworkImage(
          imageUrl: url,
          httpHeaders: snapshot.data,
          cacheManager: AppImageCache.manager,
          fit: fit,
          width: width,
          height: height,
          memCacheWidth: memCacheWidth,
          memCacheHeight: memCacheHeight,
          fadeInDuration: const Duration(milliseconds: 180),
          fadeOutDuration: const Duration(milliseconds: 120),
          useOldImageOnUrlChange: true,
          placeholder: (context, _) => _loadingBox(),
          errorWidget: (context, url, error) => _errorBox(),
        );

        if (onTap == null) return image;

        return GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            fit: StackFit.expand,
            children: [
              image,
              if (showTapHint)
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Icon(
                    Icons.zoom_out_map,
                    size: 18,
                    color: Colors.white.withValues(alpha: 0.85),
                    shadows: const [
                      Shadow(blurRadius: 4, color: Colors.black54),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _loadingBox() {
    return ColoredBox(
      color: fallbackColor.withValues(alpha: 0.6),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primaryBrown,
          ),
        ),
      ),
    );
  }

  Widget _errorBox() {
    return ColoredBox(
      color: fallbackColor,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.homeTextLight.withValues(alpha: 0.45),
          size: 40,
        ),
      ),
    );
  }
}
