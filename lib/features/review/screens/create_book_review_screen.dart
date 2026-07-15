import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/widgets/editorial_form_field.dart';
import 'package:mobile/data/auth/auth_repository.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/data/repositories/books_repository.dart';
import 'package:mobile/data/repositories/reviews_repository.dart';
import 'package:mobile/features/posts/widgets/create_post/create_post_section.dart';
import 'package:mobile/features/posts/widgets/post_section_label.dart';
import 'package:mobile/features/review/widgets/create_review/create_book_catalog_picker.dart';
import 'package:mobile/features/review/widgets/create_review/create_book_cover_picker.dart';
import 'package:mobile/features/review/widgets/create_review/create_review_rating_row.dart';
import 'package:mobile/features/review/widgets/create_review/create_review_submit_bar.dart';

/// Creates a catalog book (`POST /api/books`) then a review (`POST /api/reviews`).
class CreateBookReviewScreen extends StatefulWidget {
  const CreateBookReviewScreen({super.key});

  @override
  State<CreateBookReviewScreen> createState() => _CreateBookReviewScreenState();
}

class _CreateBookReviewScreenState extends State<CreateBookReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _booksRepo = BeBlogBooksRepository();
  final _reviewsRepo = BeBlogReviewsRepository();
  final _authRepo = AuthRepository();
  final _imagePicker = ImagePicker();

  final _bookTitleController = TextEditingController();
  final _bookDescriptionController = TextEditingController();
  final _isbnController = TextEditingController();
  final _languageController = TextEditingController();
  final _pageCountController = TextEditingController();

  File? _coverImageFile;

  final _reviewTitleController = TextEditingController();
  final _reviewContentController = TextEditingController();

  bool _isLoading = false;
  int _rating = 4;
  String _status = 'draft';
  bool _containsSpoilers = false;
  Set<String> _selectedAuthorIds = {};
  Set<String> _selectedGenreIds = {};

  @override
  void dispose() {
    _bookTitleController.dispose();
    _bookDescriptionController.dispose();
    _isbnController.dispose();
    _languageController.dispose();
    _pageCountController.dispose();
    _reviewTitleController.dispose();
    _reviewContentController.dispose();
    super.dispose();
  }

  int? _parsePageCount() {
    final raw = _pageCountController.text.trim();
    if (raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final token = await _authRepo.getToken();
    if (token == null || token.isEmpty) {
      _finishWithError(
        'Chưa đăng nhập hoặc phiên hết hạn. Vui lòng đăng nhập lại.',
      );
      return;
    }

    setState(() => _isLoading = true);

    final bookResult = await _booksRepo.createMultipart(
      title: _bookTitleController.text.trim(),
      description: _trimOrNull(_bookDescriptionController.text),
      isbn: _trimOrNull(_isbnController.text),
      language: _trimOrNull(_languageController.text),
      pageCount: _parsePageCount(),
      coverImageFile: _coverImageFile,
    );
    if (!mounted) return;

    if (!bookResult.success || bookResult.data == null) {
      _finishWithError(
        _messageForBookApi(bookResult.statusCode, bookResult.message),
      );
      return;
    }

    final bookId = bookResult.data!.id;

    for (final authorId in _selectedAuthorIds) {
      final link = await _booksRepo.addAuthor(
        bookId: bookId,
        authorId: authorId,
      );
      if (!link.success) {
        _finishWithError(
          link.message ?? 'Sách đã tạo nhưng gắn tác giả thất bại.',
        );
        return;
      }
    }
    for (final genreId in _selectedGenreIds) {
      final link = await _booksRepo.addGenre(bookId: bookId, genreId: genreId);
      if (!link.success) {
        _finishWithError(
          link.message ?? 'Sách đã tạo nhưng gắn thể loại thất bại.',
        );
        return;
      }
    }

    final reviewReq = ReviewWriteRequest(
      bookId: bookId,
      title: _reviewTitleController.text.trim(),
      content: _reviewContentController.text.trim(),
      rating: _rating,
      containsSpoilers: _containsSpoilers,
      status: _status,
      publishedAt: _status == 'published' ? DateTime.now() : null,
    );

    final reviewResult = await _reviewsRepo.create(reviewReq);
    if (!mounted) return;

    if (!reviewResult.success) {
      _finishWithError(
        reviewResult.message ??
            'Sách đã tạo nhưng review thất bại (HTTP ${reviewResult.statusCode}).',
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thêm sách và review.', style: GoogleFonts.inter()),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context, true);
  }

  String _messageForBookApi(int? statusCode, String? serverMessage) {
    switch (statusCode) {
      case 401:
        return 'Phiên đăng nhập hết hạn hoặc chưa gửi token. '
            'Đăng xuất và đăng nhập lại, rồi thử lại.';
      case 403:
        return serverMessage ??
            'Không có quyền tạo sách (HTTP 403). Kiểm tra tài khoản hoặc quyền trên server.';
      default:
        return serverMessage ?? 'Không thể tạo sách (HTTP $statusCode).';
    }
  }

  void _finishWithError(String message) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String? _trimOrNull(String value) {
    final t = value.trim();
    return t.isEmpty ? null : t;
  }

  String? _required(String? value, String message) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
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
          'Library entry',
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
            SliverToBoxAdapter(child: _buildBookCard()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                child: _buildReviewCard(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: _buildOptionsSection(),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
          ],
        ),
      ),
      bottomNavigationBar: CreateReviewSubmitBar(
        isLoading: _isLoading,
        bookTitle: _bookTitleController.text,
        rating: _rating,
        status: _status,
        hasCover: _coverImageFile != null,
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
          const PostSectionLabel(text: 'Library compose'),
          const SizedBox(height: 12),
          Text(
            'Catalog &\ncritique',
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
            'Thêm sách vào thư viện và viết review editorial của bạn.',
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

  Widget _buildBookCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: CreatePostSection(
          label: 'The book',
          subtitle: 'Thông tin sách trong catalog.',
          child: Column(
            children: [
              EditorialFormField(
                label: 'Book title',
                hint: 'e.g. The Great Gatsby',
                controller: _bookTitleController,
                validator: (v) => _required(v, 'Nhập tên sách'),
              ),
              const SizedBox(height: 24),
              EditorialFormField(
                label: 'Description',
                hint: 'Synopsis or catalog note…',
                controller: _bookDescriptionController,
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              EditorialFormField(
                label: 'ISBN',
                hint: 'Optional',
                controller: _isbnController,
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: EditorialFormField(
                      label: 'Language',
                      hint: 'en',
                      controller: _languageController,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: EditorialFormField(
                      label: 'Pages',
                      hint: '320',
                      controller: _pageCountController,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        if (int.tryParse(v.trim()) == null) {
                          return 'Số trang không hợp lệ';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              CreateBookCatalogPicker(
                selectedAuthorIds: _selectedAuthorIds,
                selectedGenreIds: _selectedGenreIds,
                enabled: !_isLoading,
                onAuthorsChanged: (ids) =>
                    setState(() => _selectedAuthorIds = ids),
                onGenresChanged: (ids) =>
                    setState(() => _selectedGenreIds = ids),
              ),
              const SizedBox(height: 24),
              CreateBookCoverPicker(
                imageFile: _coverImageFile,
                enabled: !_isLoading,
                onPickGallery: () => _pickCover(ImageSource.gallery),
                onPickCamera: () => _pickCover(ImageSource.camera),
                onRemove: () => setState(() => _coverImageFile = null),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickCover(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 720,
        maxHeight: 1080,
        imageQuality: 80,
      );
      if (picked == null) return;

      if (!mounted) return;
      setState(() => _coverImageFile = File(picked.path));
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể chọn ảnh: ${e.message ?? e.code}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể chọn ảnh.', style: GoogleFonts.inter()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildReviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: CreatePostSection(
        label: 'Your review',
        subtitle: 'Critique gắn với sách vừa tạo.',
        child: Column(
          children: [
            EditorialFormField(
              label: 'Review title',
              hint: 'Headline for your critique',
              controller: _reviewTitleController,
              validator: (v) => _required(v, 'Nhập tiêu đề review'),
            ),
            const SizedBox(height: 24),
            EditorialFormField(
              label: 'Review body',
              hint: 'Your thoughts, verdict, highlights…',
              controller: _reviewContentController,
              maxLines: 8,
              validator: (v) => _required(v, 'Nhập nội dung review'),
            ),
            const SizedBox(height: 28),
            CreateReviewRatingRow(
              rating: _rating,
              onRatingChanged: (v) => setState(() => _rating = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsSection() {
    return CreatePostSection(
      label: 'Publishing',
      child: Column(
        children: [
          _StatusSelector(
            value: _status,
            onChanged: _isLoading ? null : (v) => setState(() => _status = v),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Contains spoilers',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.homeTextDark,
              ),
            ),
            subtitle: Text(
              'Đánh dấu nếu review lộ tình tiết quan trọng.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.homeTextLight,
              ),
            ),
            value: _containsSpoilers,
            activeThumbColor: AppColors.primaryBrown,
            onChanged: _isLoading
                ? null
                : (v) => setState(() => _containsSpoilers = v),
          ),
        ],
      ),
    );
  }
}

class _StatusSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String>? onChanged;

  const _StatusSelector({required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatusChip(
            label: 'Draft',
            selected: value == 'draft',
            onTap: onChanged == null ? null : () => onChanged!('draft'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatusChip(
            label: 'Published',
            selected: value == 'published',
            onTap: onChanged == null ? null : () => onChanged!('published'),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _StatusChip({required this.label, required this.selected, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryBrown : AppColors.white,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: selected
                ? null
                : Border.all(
                    color: AppColors.homeTextDark.withValues(alpha: 0.12),
                  ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.homeTextDark,
            ),
          ),
        ),
      ),
    );
  }
}
