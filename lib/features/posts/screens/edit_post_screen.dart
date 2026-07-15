import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/widgets/app_cached_image.dart';
import 'package:mobile/core/widgets/editorial_form_field.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/data/repositories/posts_repository.dart';
import 'package:mobile/features/posts/widgets/create_post/create_post_gallery_picker.dart';
import 'package:mobile/features/posts/widgets/create_post/create_post_pick_actions.dart';
import 'package:mobile/features/posts/widgets/create_post/create_post_section.dart';
import 'package:mobile/features/posts/widgets/post_section_label.dart';

/// Sửa bài: `PUT /api/posts/{id}` (multipart) + thêm/xóa ảnh gallery.
///
/// Trả về [PostDto] đã cập nhật khi pop (hoặc `null` nếu hủy).
class EditPostScreen extends StatefulWidget {
  final PostDto post;

  const EditPostScreen({super.key, required this.post});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _postsRepo = BeBlogPostsRepository();
  final _imagePicker = ImagePicker();

  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  bool _isSaving = false;

  /// Ảnh bìa mới được chọn (thay ảnh cũ). Null = giữ ảnh cũ.
  File? _newTitleImageFile;

  /// Ảnh gallery sẵn có còn giữ lại.
  late List<PostGalleryImageDto> _existingGallery;

  /// ID ảnh gallery sẵn có bị đánh dấu xóa.
  final Set<String> _removedGalleryIds = {};

  /// Ảnh gallery mới thêm.
  final List<File> _newGalleryFiles = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.post.title);
    _contentController = TextEditingController(text: widget.post.content);
    _existingGallery = List.of(widget.post.galleryImages);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  bool get _hasExistingCover =>
      widget.post.hasTitleImage && _newTitleImageFile == null;

  Future<void> _pickTitleImage(ImageSource source) async {
    final file = await _pickSingleImage(source);
    if (file != null) setState(() => _newTitleImageFile = file);
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
    } catch (e) {
      _showError('Không thể chọn ảnh: ${_describe(e)}');
      return null;
    }
  }

  Future<void> _pickGalleryImages() async {
    try {
      final picked = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (picked.isEmpty) return;
      setState(() => _newGalleryFiles.addAll(picked.map((x) => File(x.path))));
    } catch (e) {
      _showError('Không thể chọn ảnh: ${_describe(e)}');
    }
  }

  String _describe(Object e) =>
      e is PlatformException ? (e.message ?? e.code) : e.toString();

  void _removeNewGalleryAt(int index) {
    setState(() => _newGalleryFiles.removeAt(index));
  }

  void _toggleRemoveExisting(String id) {
    setState(() {
      if (!_removedGalleryIds.remove(id)) _removedGalleryIds.add(id);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final postId = widget.post.id;

    // 1) Xóa ảnh gallery đã bỏ chọn.
    for (final id in _removedGalleryIds) {
      final res = await _postsRepo.deleteGalleryImage(id: postId, imageId: id);
      if (!res.success) {
        _fail(res.message ?? 'Không thể xóa ảnh gallery.');
        return;
      }
    }

    // 2) Thêm ảnh gallery mới.
    if (_newGalleryFiles.isNotEmpty) {
      final res = await _postsRepo.appendGalleryImages(
        id: postId,
        imageFiles: List.unmodifiable(_newGalleryFiles),
      );
      if (!res.success) {
        _fail(res.message ?? 'Không thể thêm ảnh gallery.');
        return;
      }
    }

    // 3) Cập nhật tiêu đề / nội dung / ảnh bìa (giữ nguyên gallery hiện có).
    final result = await _postsRepo.updateMultipart(
      id: postId,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      titleImageFile: _newTitleImageFile,
    );

    if (!mounted) return;
    if (result.success && result.data != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã cập nhật bài viết.', style: GoogleFonts.inter()),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, result.data);
      return;
    }

    _fail(
      result.message ??
          'Không thể cập nhật bài viết (HTTP ${result.statusCode}).',
    );
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() => _isSaving = false);
    _showError(message);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
          onPressed: _isSaving ? null : () => Navigator.pop(context),
        ),
        title: Text(
          'Edit entry',
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
            if (widget.post.isRejected)
              SliverToBoxAdapter(child: _buildResubmitNote()),
            SliverToBoxAdapter(child: _buildCopyCard()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildCoverSection(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildGallerySection(),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
          ],
        ),
      ),
      bottomNavigationBar: _buildSaveBar(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PostSectionLabel(text: 'Editorial revise'),
          const SizedBox(height: 12),
          Text(
            'Refine your\nstory',
            style: GoogleFonts.playfairDisplay(
              color: AppColors.homeTextDark,
              fontSize: 36,
              height: 1.08,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResubmitNote() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.06),
          borderRadius: AppRadius.input,
          border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.error,
                ),
                const SizedBox(width: 8),
                Text(
                  'Bài bị từ chối',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              widget.post.rejectionReason?.trim().isNotEmpty == true
                  ? 'Lý do: ${widget.post.rejectionReason!.trim()}\nLưu thay đổi sẽ gửi lại để duyệt.'
                  : 'Lưu thay đổi sẽ gửi lại bài để duyệt.',
              style: GoogleFonts.inter(
                fontSize: 12,
                height: 1.5,
                color: AppColors.homeTextDark.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
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

  Widget _buildCoverSection() {
    return CreatePostSection(
      label: 'Cover image',
      subtitle: 'Chọn ảnh mới để thay ảnh bìa hiện tại.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: SizedBox(
              height: 220,
              width: double.infinity,
              child: _newTitleImageFile != null
                  ? Image.file(_newTitleImageFile!, fit: BoxFit.cover)
                  : _hasExistingCover
                  ? AppCachedImage(
                      url: widget.post.resolveTitleImageUrl(
                        ApiConstants.baseUrl,
                      ),
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: AppColors.coverSand.withValues(alpha: 0.4),
                      child: Center(
                        child: Text(
                          'Chưa có ảnh bìa',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.homeTextLight,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          CreatePostPickActions(
            onGallery: () => _pickTitleImage(ImageSource.gallery),
            onCamera: () => _pickTitleImage(ImageSource.camera),
          ),
          if (_newTitleImageFile != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _newTitleImageFile = null),
                icon: const Icon(Icons.undo, size: 16),
                label: Text(
                  'Hoàn tác ảnh bìa',
                  style: GoogleFonts.inter(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryBrown,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGallerySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_existingGallery.isNotEmpty) ...[
          const PostSectionLabel(text: 'Current gallery'),
          const SizedBox(height: 8),
          Text(
            'Chạm vào ảnh để đánh dấu xóa khi lưu.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.homeTextLight,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _existingGallery.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final image = _existingGallery[index];
                final marked = _removedGalleryIds.contains(image.id);
                return _ExistingGalleryThumb(
                  url: image.resolveUrl(ApiConstants.baseUrl),
                  markedForRemoval: marked,
                  onToggle: () => _toggleRemoveExisting(image.id),
                );
              },
            ),
          ),
          const SizedBox(height: 28),
        ],
        CreatePostGalleryPicker(
          imageFiles: _newGalleryFiles,
          onAdd: _pickGalleryImages,
          onRemoveAt: _removeNewGalleryAt,
        ),
      ],
    );
  }

  Widget _buildSaveBar() {
    final removeCount = _removedGalleryIds.length;
    final addCount = _newGalleryFiles.length;
    final parts = <String>[];
    if (_newTitleImageFile != null) parts.add('cover mới');
    if (addCount > 0) parts.add('+$addCount ảnh');
    if (removeCount > 0) parts.add('-$removeCount ảnh');
    final hint = parts.isEmpty ? 'Văn bản' : parts.join(' · ');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.homeBackground,
        border: Border(
          top: BorderSide(
            color: AppColors.homeTextDark.withValues(alpha: 0.08),
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.post.isRejected ? 'Lưu & gửi lại' : 'Lưu thay đổi',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.homeTextDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hint,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.homeTextLight,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.pill,
              boxShadow: _isSaving ? null : AppShadows.primaryButton,
            ),
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryBrown,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Save',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExistingGalleryThumb extends StatelessWidget {
  final String url;
  final bool markedForRemoval;
  final VoidCallback onToggle;

  const _ExistingGalleryThumb({
    required this.url,
    required this.markedForRemoval,
    required this.onToggle,
  });

  static const double _size = 120;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: AppRadius.input,
            child: SizedBox(
              width: _size,
              height: _size,
              child: AppCachedImage(url: url, fit: BoxFit.cover),
            ),
          ),
          if (markedForRemoval)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: AppRadius.input,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.55),
                  child: const Center(
                    child: Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: markedForRemoval ? AppColors.error : Colors.black54,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onToggle,
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    markedForRemoval ? Icons.undo : Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
