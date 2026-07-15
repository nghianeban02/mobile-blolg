import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/features/posts/widgets/post_section_label.dart';
import 'package:mobile/features/reading_list/widgets/reading_list_item.dart';

class LibraryBooksSection extends StatelessWidget {
  final List<BookDto> books;
  final Map<String, ReviewDto> reviewByBookId;
  final void Function(ReviewDto review) onOpenReview;

  const LibraryBooksSection({
    super.key,
    required this.books,
    required this.reviewByBookId,
    required this.onOpenReview,
  });

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'Chưa có sách trong catalog. Nhấn + để thêm sách và review.',
          style: GoogleFonts.inter(
            color: AppColors.homeTextLight,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: PostSectionLabel(text: 'Your catalog'),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            '${books.length} ${books.length == 1 ? 'title' : 'titles'} from the archive',
            style: GoogleFonts.inter(
              color: AppColors.homeTextLight,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(height: 24),
        ...List.generate(books.length, (index) {
          final book = books[index];
          final review = reviewByBookId[book.id];
          // Offset 2: first books used in featured / editor's choice slots.
          final listIndex = index + 2;
          return Padding(
            padding: EdgeInsets.only(bottom: index < books.length - 1 ? 32 : 0),
            child: ReadingListItem(
              book: book,
              listIndex: listIndex,
              review: review,
              onReadReview: review != null ? () => onOpenReview(review) : null,
            ),
          );
        }),
      ],
    );
  }
}
