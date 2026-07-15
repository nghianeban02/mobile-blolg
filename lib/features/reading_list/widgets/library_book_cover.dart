import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/widgets/app_cached_image.dart';
import 'package:mobile/data/models/dtos.dart';

/// In-memory cache for decoded `data:` cover URLs (avoid re-decoding on rebuild).
final Map<String, Uint8List> _dataUrlImageCache = {};
const int _dataUrlCacheMaxEntries = 24;

/// Book cover: network image or editorial color block.
class LibraryBookCover extends StatefulWidget {
  final BookDto book;
  final Color fallbackColor;
  final double width;
  final double height;

  const LibraryBookCover({
    super.key,
    required this.book,
    required this.fallbackColor,
    required this.width,
    required this.height,
  });

  @override
  State<LibraryBookCover> createState() => _LibraryBookCoverState();
}

class _LibraryBookCoverState extends State<LibraryBookCover> {
  Uint8List? _dataUrlBytes;

  @override
  void initState() {
    super.initState();
    _resolveDataUrlBytes();
  }

  @override
  void didUpdateWidget(LibraryBookCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.book.id != widget.book.id ||
        oldWidget.book.coverImageUrl != widget.book.coverImageUrl) {
      _resolveDataUrlBytes();
    }
  }

  void _resolveDataUrlBytes() {
    final coverUrl = widget.book.resolveCoverImageUrl(ApiConstants.baseUrl);
    if (coverUrl == null || !coverUrl.startsWith('data:')) {
      _dataUrlBytes = null;
      return;
    }

    final cached = _dataUrlImageCache[coverUrl];
    if (cached != null) {
      _dataUrlBytes = cached;
      return;
    }

    final commaIndex = coverUrl.indexOf(',');
    if (commaIndex <= 0 || commaIndex == coverUrl.length - 1) {
      _dataUrlBytes = null;
      return;
    }

    try {
      final bytes = base64Decode(coverUrl.substring(commaIndex + 1));
      if (_dataUrlImageCache.length >= _dataUrlCacheMaxEntries) {
        _dataUrlImageCache.remove(_dataUrlImageCache.keys.first);
      }
      _dataUrlImageCache[coverUrl] = bytes;
      _dataUrlBytes = bytes;
    } catch (_) {
      _dataUrlBytes = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final coverUrl = widget.book.resolveCoverImageUrl(ApiConstants.baseUrl);
    final bytes = _dataUrlBytes;

    if (bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: widget.width,
          height: widget.height,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
        ),
      );
    }

    if (coverUrl != null && !coverUrl.startsWith('data:')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: AppCachedImage.sized(
          context: context,
          url: coverUrl,
          logicalWidth: widget.width,
          logicalHeight: widget.height,
          fallbackColor: widget.fallbackColor,
        ),
      );
    }

    return _fallback();
  }

  Widget _fallback() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: widget.fallbackColor,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.book.title.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: Colors.black38,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
