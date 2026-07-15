import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/data/repositories/posts_repository.dart';
import 'package:mobile/core/widgets/editorial_form_field.dart';
import 'package:mobile/features/posts/widgets/create_post/create_post_gallery_picker.dart';
import 'package:mobile/features/posts/widgets/create_post/create_post_submit_bar.dart';
import 'package:mobile/features/posts/widgets/create_post/create_post_title_image_picker.dart';
import 'package:mobile/features/posts/widgets/post_section_label.dart';

/// `POST /api/posts` (multipart: title, content, titleImage, images[]) — any logged-in user.
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _postsRepo = BeBlogPostsRepository();
  final _imagePicker = ImagePicker();

  bool _isLoading = false;
  File? _titleImageFile;
  final List<File> _galleryImageFiles = [];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickTitleImage(ImageSource source) async {
    final file = await _pickSingleImage(source);
    if (file != null) setState(() => _titleImageFile = file);
  }

  Future<void> _pickGalleryImages() async {
    try {
      final picked = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (picked.isEmpty) return;
      setState(() {
        _galleryImageFiles.addAll(picked.map((x) => File(x.path)));
      });
    } on PlatformException catch (e) {
      _showPickError(e);
    } catch (e) {
      _showPickError(e);
    }
  }

  Future<File?> _pickSingleImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (picked == null) return null;
      return File(picked.path);
    } on PlatformException catch (e) {
      _showPickError(e);
      return null;
    } catch (e) {
      _showPickError(e);
      return null;
    }
  }

  void _showPickError(Object e) {
    if (!mounted) return;
    final message = e is PlatformException
        ? (e.message ?? e.code)
        : e.toString();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Không thể chọn ảnh: $message',
          style: GoogleFonts.inter(),
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _removeGalleryAt(int index) {
    setState(() => _galleryImageFiles.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await _postsRepo.createMultipart(
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      titleImageFile: _titleImageFile,
      galleryImageFiles: List.unmodifiable(_galleryImageFiles),
    );

    if (!mounted) return;

    final message = result.success
        ? 'Đã tạo bài viết.'
        : (result.message ??
              'Không thể tạo bài viết (HTTP ${result.statusCode}).');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        backgroundColor: result.success ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (result.success) {
      Navigator.pop(context, true);
      return;
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppColors.homeBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          color: AppColors.homeTextDark,
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
        title: Text(
          'New entry',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.homeTextLight,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildCopyCard()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: CreatePostTitleImagePicker(
                  imageFile: _titleImageFile,
                  onPickGallery: () => _pickTitleImage(ImageSource.gallery),
                  onPickCamera: () => _pickTitleImage(ImageSource.camera),
                  onRemove: () => setState(() => _titleImageFile = null),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: CreatePostGalleryPicker(
                  imageFiles: _galleryImageFiles,
                  onAdd: _pickGalleryImages,
                  onRemoveAt: _removeGalleryAt,
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
          ],
        ),
      ),
      bottomNavigationBar: CreatePostSubmitBar(
        isLoading: _isLoading,
        hasCover: _titleImageFile != null,
        galleryCount: _galleryImageFiles.length,
        onPublish: _submit,
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PostSectionLabel(text: 'Editorial compose'),
          const SizedBox(height: 12),
          Text(
            'Write a\nnew story',
            style: GoogleFonts.playfairDisplay(
              color: AppColors.homeTextDark,
              fontSize: 36,
              height: 1.08,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Bài đăng của bạn sẽ xuất hiện trên feed và thư viện cá nhân.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.homeTextLight,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EditorialFormField(
              label: 'Title',
              hint: 'The headline of your piece',
              controller: _titleController,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Nhập tiêu đề' : null,
            ),
            const SizedBox(height: 28),
            EditorialFormField(
              label: 'Body',
              hint: 'Your essay, critique, or notes…',
              controller: _contentController,
              maxLines: 10,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Nhập nội dung' : null,
            ),
          ],
        ),
      ),
    );
  }
}
