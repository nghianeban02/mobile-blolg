import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/features/posts/widgets/create_post/create_post_image_slot.dart';
import 'package:mobile/features/posts/widgets/create_post/create_post_section.dart';

class CreatePostGalleryPicker extends StatelessWidget {
  final List<File> imageFiles;
  final VoidCallback onAdd;
  final void Function(int index) onRemoveAt;

  const CreatePostGalleryPicker({
    super.key,
    required this.imageFiles,
    required this.onAdd,
    required this.onRemoveAt,
  });

  static const double _thumbSize = 120;

  @override
  Widget build(BuildContext context) {
    return CreatePostSection(
      label: 'In this story',
      subtitle: 'Ảnh phụ trong bài — chọn nhiều ảnh từ thư viện.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (imageFiles.isEmpty)
            const CreatePostImageSlot(
              height: 100,
              title: 'Gallery',
              subtitle: 'Horizontal strip on the post detail page',
              icon: Icons.collections_outlined,
            )
          else
            SizedBox(
              height: _thumbSize,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: imageFiles.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return _GalleryThumb(
                    file: imageFiles[index],
                    onRemove: () => onRemoveAt(index),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          _AddGalleryButton(count: imageFiles.length, onPressed: onAdd),
        ],
      ),
    );
  }
}

class _GalleryThumb extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;

  const _GalleryThumb({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: AppRadius.input,
          child: Image.file(
            file,
            width: CreatePostGalleryPicker._thumbSize,
            height: CreatePostGalleryPicker._thumbSize,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Material(
            color: Colors.black54,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onRemove,
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddGalleryButton extends StatelessWidget {
  final int count;
  final VoidCallback onPressed;

  const _AddGalleryButton({required this.count, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.pill,
        boxShadow: AppShadows.primaryButton,
      ),
      child: Material(
        color: AppColors.primaryBrown,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  count == 0 ? 'Thêm ảnh gallery' : 'Thêm ảnh ($count đã chọn)',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
