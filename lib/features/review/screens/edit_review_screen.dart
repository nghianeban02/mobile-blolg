import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/widgets/detail_app_bar.dart';
import 'package:mobile/core/widgets/editorial_form_field.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/data/repositories/reviews_repository.dart';
import 'package:mobile/features/review/widgets/create_review/create_review_rating_row.dart';

/// Edit review: `PUT /api/reviews/{id}`.
class EditReviewScreen extends StatefulWidget {
  final ReviewDto review;

  const EditReviewScreen({super.key, required this.review});

  @override
  State<EditReviewScreen> createState() => _EditReviewScreenState();
}

class _EditReviewScreenState extends State<EditReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reviewsRepo = BeBlogReviewsRepository();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  late int _rating;
  late String _status;
  late bool _containsSpoilers;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.review.title;
    _contentController.text = widget.review.content;
    _rating = widget.review.rating;
    _status = widget.review.status;
    _containsSpoilers = widget.review.containsSpoilers;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final req = ReviewWriteRequest(
      bookId: widget.review.bookId,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      rating: _rating,
      containsSpoilers: _containsSpoilers,
      status: _status,
      publishedAt: widget.review.publishedAt,
    );
    final result = await _reviewsRepo.update(widget.review.id, req);
    if (!mounted) return;
    setState(() => _saving = false);
    if (result.success && result.data != null) {
      Navigator.pop(context, result.data);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Could not save review.'),
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
                        'Edit review',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 28),
                      EditorialFormField(
                        label: 'Headline',
                        controller: _titleController,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),
                      EditorialFormField(
                        label: 'Critique',
                        controller: _contentController,
                        maxLines: 8,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 24),
                      CreateReviewRatingRow(
                        rating: _rating,
                        onRatingChanged: (r) => setState(() => _rating = r),
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        key: ValueKey(_status),
                        initialValue: _status,
                        decoration: InputDecoration(
                          labelText: 'STATUS',
                          labelStyle: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'draft',
                            child: Text('Draft'),
                          ),
                          DropdownMenuItem(
                            value: 'published',
                            child: Text('Published'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _status = v);
                        },
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Contains spoilers',
                          style: GoogleFonts.inter(fontSize: 14),
                        ),
                        value: _containsSpoilers,
                        activeThumbColor: AppColors.primaryBrown,
                        onChanged: (v) => setState(() => _containsSpoilers = v),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _saving ? null : _save,
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
                            letterSpacing: 1,
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
