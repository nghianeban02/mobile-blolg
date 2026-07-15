import 'dart:io';

class BookReviewRequest {
  final String reviewTitle;
  final String bookTitle;
  final String bookAuthor;
  final String reviewText;
  final String? summary;
  final int rating;
  final bool? published;
  final String? slug;
  final File? coverImage;
  final List<File>? images;

  BookReviewRequest({
    required this.reviewTitle,
    required this.bookTitle,
    required this.bookAuthor,
    required this.reviewText,
    required this.rating,
    this.summary,
    this.published,
    this.slug,
    this.coverImage,
    this.images,
  });
}
