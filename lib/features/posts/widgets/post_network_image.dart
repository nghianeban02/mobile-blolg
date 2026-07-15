import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/widgets/app_cached_image.dart';

/// Cover image with disk cache, decode limits, and optional tap-to-view.
class PostNetworkImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final Color fallbackColor;
  final VoidCallback? onTap;

  const PostNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.fallbackColor = AppColors.coverSand,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : width * 0.75;

        return AppCachedImage.sized(
          context: context,
          url: url,
          logicalWidth: width,
          logicalHeight: height,
          fit: fit,
          fallbackColor: fallbackColor,
          onTap: onTap,
          showTapHint: onTap != null,
        );
      },
    );
  }
}
