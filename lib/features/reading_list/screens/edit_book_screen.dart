import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/widgets/detail_app_bar.dart';
import 'package:mobile/core/widgets/editorial_confirm_dialog.dart';
import 'package:mobile/core/widgets/editorial_form_field.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/data/repositories/books_repository.dart';
import 'package:mobile/features/review/widgets/create_review/create_book_catalog_picker.dart';
import 'package:mobile/features/review/widgets/create_review/create_book_cover_picker.dart';

/// Edit or delete catalog book: `PUT/DELETE /api/books/{id}`.
class EditBookScreen extends StatefulWidget {
  final BookDto book;

  const EditBookScreen({super.key, required this.book});

  @override
  State<EditBookScreen> createState() => _EditBookScreenState();
}

class _EditBookScreenState extends State<EditBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _booksRepo = BeBlogBooksRepository();
  final _imagePicker = ImagePicker();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _isbnController = TextEditingController();
  final _languageController = TextEditingController();
  final _pageCountController = TextEditingController();

  bool _saving = false;
  bool _deleting = false;
  File? _coverImageFile;
  DateTime? _publishedDate;
  Set<String> _selectedAuthorIds = {};
  Set<String> _selectedGenreIds = {};
  Set<String> _originalAuthorIds = {};
  Set<String> _originalGenreIds = {};

  @override
  void initState() {
    super.initState();
    final b = widget.book;
    _titleController.text = b.title;
    _descriptionController.text = b.description ?? '';
    _isbnController.text = b.isbn ?? '';
    _languageController.text = b.language ?? '';
    _pageCountController.text = b.pageCount?.toString() ?? '';
    _publishedDate = b.publishedDate;
    _loadRelations();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _isbnController.dispose();
    _languageController.dispose();
    _pageCountController.dispose();
    super.dispose();
  }

  Future<void> _loadRelations() async {
    final authors = await _booksRepo.getAuthors(widget.book.id);
    final genres = await _booksRepo.getGenres(widget.book.id);
    if (!mounted) return;
    setState(() {
      _originalAuthorIds =
          authors.data?.map((item) => item.authorId).toSet() ?? {};
      _originalGenreIds =
          genres.data?.map((item) => item.genreId).toSet() ?? {};
      _selectedAuthorIds = {..._originalAuthorIds};
      _selectedGenreIds = {..._originalGenreIds};
    });
  }

  String? _optional(String value) => value.trim().isEmpty ? null : value.trim();

  Future<void> _pickCover(ImageSource source) async {
    final image = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 2000,
    );
    if (image != null) setState(() => _coverImageFile = File(image.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final pageRaw = _pageCountController.text.trim();
    final pageCount = pageRaw.isEmpty ? null : int.tryParse(pageRaw);
    if (pageRaw.isNotEmpty && (pageCount == null || pageCount <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Page count must be a positive number.')),
      );
      return;
    }
    setState(() => _saving = true);
    final result = await _booksRepo.updateMultipart(
      id: widget.book.id,
      title: _titleController.text.trim(),
      description: _optional(_descriptionController.text),
      isbn: _optional(_isbnController.text),
      language: _optional(_languageController.text),
      pageCount: pageCount,
      publishedDate: _publishedDate,
      coverImageFile: _coverImageFile,
    );
    if (!mounted) return;
    if (result.success && result.data != null) {
      for (final id in _originalAuthorIds.difference(_selectedAuthorIds)) {
        await _booksRepo.removeAuthor(bookId: widget.book.id, authorId: id);
      }
      for (final id in _selectedAuthorIds.difference(_originalAuthorIds)) {
        await _booksRepo.addAuthor(bookId: widget.book.id, authorId: id);
      }
      for (final id in _originalGenreIds.difference(_selectedGenreIds)) {
        await _booksRepo.removeGenre(bookId: widget.book.id, genreId: id);
      }
      for (final id in _selectedGenreIds.difference(_originalGenreIds)) {
        await _booksRepo.addGenre(bookId: widget.book.id, genreId: id);
      }
      if (!mounted) return;
      Navigator.pop(context, result.data);
    } else {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Could not save book.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _delete() async {
    final ok = await showEditorialConfirmDialog(
      context,
      title: 'Delete book?',
      message: '“${widget.book.title}” and linked reviews may be affected.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    setState(() => _deleting = true);
    final result = await _booksRepo.delete(widget.book.id);
    if (!mounted) return;
    setState(() => _deleting = false);
    if (result.success) {
      Navigator.pop(context, 'deleted');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Could not delete book.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: CustomScrollView(
            slivers: [
              const DetailSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Edit book',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 28),
                      EditorialFormField(
                        label: 'Title',
                        controller: _titleController,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),
                      EditorialFormField(
                        label: 'Description',
                        controller: _descriptionController,
                        maxLines: 5,
                      ),
                      const SizedBox(height: 20),
                      EditorialFormField(
                        label: 'ISBN',
                        controller: _isbnController,
                      ),
                      const SizedBox(height: 20),
                      EditorialFormField(
                        label: 'Language',
                        controller: _languageController,
                      ),
                      const SizedBox(height: 20),
                      EditorialFormField(
                        label: 'Page count',
                        controller: _pageCountController,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 20),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Published date'),
                        subtitle: Text(
                          _publishedDate == null
                              ? 'Not set'
                              : '${_publishedDate!.day}/${_publishedDate!.month}/${_publishedDate!.year}',
                        ),
                        trailing: const Icon(Icons.calendar_today_outlined),
                        onTap: _saving
                            ? null
                            : () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _publishedDate ?? DateTime.now(),
                                  firstDate: DateTime(1000),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  setState(() => _publishedDate = date);
                                }
                              },
                      ),
                      const SizedBox(height: 20),
                      CreateBookCatalogPicker(
                        selectedAuthorIds: _selectedAuthorIds,
                        selectedGenreIds: _selectedGenreIds,
                        onAuthorsChanged: (value) =>
                            setState(() => _selectedAuthorIds = value),
                        onGenresChanged: (value) =>
                            setState(() => _selectedGenreIds = value),
                        enabled: !_saving && !_deleting,
                      ),
                      const SizedBox(height: 20),
                      CreateBookCoverPicker(
                        imageFile: _coverImageFile,
                        enabled: !_saving && !_deleting,
                        onPickGallery: () => _pickCover(ImageSource.gallery),
                        onPickCamera: () => _pickCover(ImageSource.camera),
                        onRemove: () => setState(() => _coverImageFile = null),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _saving || _deleting ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBrown,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          _saving ? 'Saving…' : 'Save changes',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: _saving || _deleting ? null : _delete,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(
                            color: AppColors.error.withValues(alpha: 0.4),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          _deleting ? 'Deleting…' : 'Delete book',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
