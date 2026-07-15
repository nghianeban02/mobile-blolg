import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/data/models/dtos.dart';

/// All viewable image URLs for a post (title first, then gallery order).
List<String> postDetailImageUrls(PostDto post) {
  final urls = <String>[];
  if (post.hasTitleImage) {
    urls.add(post.resolveTitleImageUrl(ApiConstants.baseUrl));
  }
  for (final image in post.galleryImages) {
    urls.add(image.resolveUrl(ApiConstants.baseUrl));
  }
  return urls;
}

/// Page index in [postDetailImageUrls] for a gallery thumbnail.
int galleryViewerIndex(PostDto post, int galleryIndex) {
  return (post.hasTitleImage ? 1 : 0) + galleryIndex;
}
