import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/features/posts/widgets/post_section_label.dart';
import 'package:mobile/features/reading_list/utils/library_book_style.dart';

class BookDetailInfo extends StatelessWidget {
  final BookDto book;

  const BookDetailInfo({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PostSectionLabel(text: 'Catalog entry'),
          const SizedBox(height: 12),
          Text(
            book.title,
            style: GoogleFonts.playfairDisplay(
              color: AppColors.homeTextDark,
              fontSize: 34,
              height: 1.12,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            LibraryBookStyle.metaLine(book),
            style: GoogleFonts.inter(
              color: AppColors.primaryBrown,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          _MetaGrid(book: book),
          const SizedBox(height: 28),
          Divider(
            height: 1,
            color: AppColors.homeTextDark.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 24),
          const PostSectionLabel(text: 'About this title'),
          const SizedBox(height: 12),
          Text(
            _descriptionText(book),
            style: GoogleFonts.inter(
              color: AppColors.homeTextLight,
              fontSize: 15,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  String _descriptionText(BookDto book) {
    final raw = book.description?.trim();
    if (raw != null && raw.isNotEmpty) return raw;
    return 'No description has been added for this title yet.';
  }
}

class _MetaGrid extends StatelessWidget {
  final BookDto book;

  const _MetaGrid({required this.book});

  @override
  Widget build(BuildContext context) {
    final items = <_MetaItem>[];
    if (book.isbn != null && book.isbn!.trim().isNotEmpty) {
      items.add(_MetaItem(label: 'ISBN', value: book.isbn!.trim()));
    }
    if (book.language != null && book.language!.trim().isNotEmpty) {
      items.add(_MetaItem(label: 'Language', value: book.language!.trim()));
    }
    if (book.pageCount != null) {
      items.add(_MetaItem(label: 'Pages', value: '${book.pageCount}'));
    }
    if (book.publishedDate != null) {
      items.add(
        _MetaItem(
          label: 'Published',
          value: LibraryBookStyle.formatDate(book.publishedDate!),
        ),
      );
    }
    if (book.createdAt != null) {
      items.add(
        _MetaItem(
          label: 'Added',
          value: LibraryBookStyle.formatDate(book.createdAt!),
        ),
      );
    }

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items
          .map(
            (item) => Container(
              width: (MediaQuery.sizeOf(context).width - 48 - 12) / 2,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label.toUpperCase(),
                    style: GoogleFonts.inter(
                      color: AppColors.homeTextLight,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.value,
                    style: GoogleFonts.inter(
                      color: AppColors.homeTextDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _MetaItem {
  final String label;
  final String value;

  const _MetaItem({required this.label, required this.value});
}
