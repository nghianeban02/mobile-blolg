import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/images/app_image_cache.dart';
import 'package:mobile/core/services/post_image_save_service.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

/// Fullscreen pinch-zoom viewer with save-to-gallery.
class PostImageViewerScreen extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const PostImageViewerScreen({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  static Future<void> open(
    BuildContext context, {
    required List<String> imageUrls,
    int initialIndex = 0,
  }) {
    if (imageUrls.isEmpty) return Future.value();
    final index = initialIndex.clamp(0, imageUrls.length - 1);
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) =>
            PostImageViewerScreen(imageUrls: imageUrls, initialIndex: index),
      ),
    );
  }

  @override
  State<PostImageViewerScreen> createState() => _PostImageViewerScreenState();
}

class _PostImageViewerScreenState extends State<PostImageViewerScreen> {
  late final PageController _pageController;
  late int _currentIndex;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _saveCurrentImage() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    final url = widget.imageUrls[_currentIndex];
    final error = await PostImageSaveService.saveFromUrl(url);
    if (!mounted) return;

    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ?? 'Đã lưu ảnh vào thư viện.',
          style: GoogleFonts.inter(),
        ),
        backgroundColor: error == null ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.imageUrls.length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            PhotoViewGallery.builder(
              pageController: _pageController,
              itemCount: count,
              backgroundDecoration: const BoxDecoration(color: Colors.black),
              loadingBuilder: (context, event) => Center(
                child: CircularProgressIndicator(
                  value: event == null
                      ? null
                      : event.cumulativeBytesLoaded /
                            (event.expectedTotalBytes ?? 1),
                  color: AppColors.primaryBrown,
                ),
              ),
              onPageChanged: (index) => setState(() => _currentIndex = index),
              builder: (context, index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider: CachedNetworkImageProvider(
                    widget.imageUrls[index],
                    cacheManager: AppImageCache.manager,
                  ),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 3,
                );
              },
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                    const Spacer(),
                    if (count > 1)
                      Text(
                        '${_currentIndex + 1} / $count',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    const Spacer(),
                    IconButton(
                      onPressed: _isSaving ? null : _saveCurrentImage,
                      tooltip: 'Lưu ảnh',
                      icon: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.download_rounded,
                              color: Colors.white,
                            ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.paddingOf(context).bottom + 16,
              child: Center(
                child: Text(
                  'Chụm để phóng to · Vuốt để đổi ảnh',
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
