import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/features/posts/widgets/create_post/create_post_image_slot.dart';
import 'package:mobile/features/posts/widgets/create_post/create_post_pick_actions.dart';
import 'package:mobile/features/posts/widgets/create_post/create_post_section.dart';

class CreatePostTitleImagePicker extends StatelessWidget {
  final File? imageFile;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;
  final VoidCallback onRemove;

  const CreatePostTitleImagePicker({
    super.key,
    required this.imageFile,
    required this.onPickGallery,
    required this.onPickCamera,
    required this.onRemove,
  });

  static const double _previewHeight = 220;

  @override
  Widget build(BuildContext context) {
    return CreatePostSection(
      label: 'Cover image',
      subtitle: 'Ảnh bìa hiển thị trên home và đầu bài viết.',
      child: Column(
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
                  child: _RemoveButton(onPressed: onRemove),
                ),
              ],
            )
          else
            const CreatePostImageSlot(
              height: _previewHeight,
              title: 'Cover image',
              subtitle: 'Optional — sets the editorial hero on the post',
            ),
          const SizedBox(height: 12),
          CreatePostPickActions(
            onGallery: onPickGallery,
            onCamera: onPickCamera,
          ),
        ],
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _RemoveButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.close, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                'Remove',
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
    );
  }
}
