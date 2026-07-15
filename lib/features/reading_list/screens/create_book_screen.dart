import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/widgets/editorial_form_field.dart';
import 'package:mobile/data/repositories/books_repository.dart';
import 'package:mobile/features/review/widgets/create_review/create_book_catalog_picker.dart';
import 'package:mobile/features/review/widgets/create_review/create_book_cover_picker.dart';

class CreateBookScreen extends StatefulWidget {
  const CreateBookScreen({super.key});

  @override
  State<CreateBookScreen> createState() => _CreateBookScreenState();
}

class _CreateBookScreenState extends State<CreateBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = BeBlogBooksRepository();
  final _picker = ImagePicker();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _isbn = TextEditingController();
  final _language = TextEditingController();
  final _pages = TextEditingController();
  Set<String> _authorIds = {};
  Set<String> _genreIds = {};
  File? _cover;
  DateTime? _publishedDate;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _isbn.dispose();
    _language.dispose();
    _pages.dispose();
    super.dispose();
  }

  String? _optional(String value) => value.trim().isEmpty ? null : value.trim();

  Future<void> _pickCover(ImageSource source) async {
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 2000,
    );
    if (image != null) setState(() => _cover = File(image.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final pages = _pages.text.trim().isEmpty ? null : int.tryParse(_pages.text);
    if (_pages.text.trim().isNotEmpty && (pages == null || pages <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số trang phải là số nguyên dương.')),
      );
      return;
    }
    setState(() => _saving = true);
    final created = await _repository.createMultipart(
      title: _title.text.trim(),
      description: _optional(_description.text),
      isbn: _optional(_isbn.text),
      language: _optional(_language.text),
      pageCount: pages,
      publishedDate: _publishedDate,
      coverImageFile: _cover,
    );
    if (!mounted) return;
    if (!created.success || created.data == null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(created.message ?? 'Không tạo được sách.')),
      );
      return;
    }
    for (final authorId in _authorIds) {
      await _repository.addAuthor(bookId: created.data!.id, authorId: authorId);
    }
    for (final genreId in _genreIds) {
      await _repository.addGenre(bookId: created.data!.id, genreId: genreId);
    }
    if (!mounted) return;
    Navigator.pop(context, created.data);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.homeBackground,
    appBar: AppBar(title: const Text('Thêm sách')),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 48),
        children: [
          Text(
            'Sách mới trong catalog',
            style: GoogleFonts.playfairDisplay(
              fontSize: 32,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 26),
          EditorialFormField(
            label: 'Tiêu đề *',
            controller: _title,
            validator: (value) =>
                value?.trim().isEmpty ?? true ? 'Vui lòng nhập tiêu đề' : null,
          ),
          const SizedBox(height: 18),
          EditorialFormField(
            label: 'Mô tả',
            controller: _description,
            maxLines: 5,
          ),
          const SizedBox(height: 18),
          EditorialFormField(label: 'ISBN', controller: _isbn),
          const SizedBox(height: 18),
          EditorialFormField(label: 'Ngôn ngữ', controller: _language),
          const SizedBox(height: 18),
          EditorialFormField(
            label: 'Số trang',
            controller: _pages,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 18),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Ngày xuất bản'),
            subtitle: Text(
              _publishedDate == null
                  ? 'Chưa chọn'
                  : '${_publishedDate!.day}/${_publishedDate!.month}/${_publishedDate!.year}',
            ),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _publishedDate ?? DateTime.now(),
                firstDate: DateTime(1000),
                lastDate: DateTime.now(),
              );
              if (date != null) setState(() => _publishedDate = date);
            },
          ),
          const SizedBox(height: 18),
          CreateBookCatalogPicker(
            selectedAuthorIds: _authorIds,
            selectedGenreIds: _genreIds,
            onAuthorsChanged: (value) => setState(() => _authorIds = value),
            onGenresChanged: (value) => setState(() => _genreIds = value),
            enabled: !_saving,
          ),
          const SizedBox(height: 22),
          CreateBookCoverPicker(
            imageFile: _cover,
            enabled: !_saving,
            onPickCamera: () => _pickCover(ImageSource.camera),
            onPickGallery: () => _pickCover(ImageSource.gallery),
            onRemove: () => setState(() => _cover = null),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBrown,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 17),
            ),
            child: _saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('TẠO SÁCH'),
          ),
        ],
      ),
    ),
  );
}
