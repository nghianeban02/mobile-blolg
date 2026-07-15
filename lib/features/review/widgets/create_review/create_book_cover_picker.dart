import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/features/posts/widgets/create_post/create_post_image_slot.dart';
import 'package:mobile/features/posts/widgets/create_post/create_post_pick_actions.dart';

/// Device cover picker aligned with create-post editorial style.
class CreateBookCoverPicker extends StatelessWidget {
  final File? imageFile;
  final bool enabled;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;
  final VoidCallback onRemove;

  const CreateBookCoverPicker({
    super.key,
    required this.imageFile,
    required this.enabled,
    required this.onPickGallery,
    required this.onPickCamera,
    required this.onRemove,
  });

  static const double _previewHeight = 220;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (imageFile != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: _previewHeight,
                  width: double.infinity,
                  child: Image.file(imageFile!, fit: BoxFit.cover),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                  child: InkWell(
                    onTap: enabled ? onRemove : null,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Xóa ảnh',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          const CreatePostImageSlot(
            height: _previewHeight,
            title: 'Ảnh bìa sách',
            subtitle: 'Chọn từ thư viện hoặc chụp bằng máy ảnh',
          ),
        const SizedBox(height: 12),
        IgnorePointer(
          ignoring: !enabled,
          child: Opacity(
            opacity: enabled ? 1 : 0.5,
            child: CreatePostPickActions(
              onGallery: onPickGallery,
              onCamera: onPickCamera,
            ),
          ),
        ),
      ],
    );
  }
}
