import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/data/models/dtos.dart';

/// Editorial palette and copy helpers for library book cards.
class LibraryBookStyle {
  LibraryBookStyle._();

  static const _coverColors = [
    AppColors.coverSand,
    AppColors.coverTeal,
    Color(0xFFE2DFCD),
    Color(0xFFF3EED9),
    Color(0xFF88C9A1),
  ];

  static Color coverColor(int index) =>
      _coverColors[index % _coverColors.length];

  static String metaLine(BookDto book) {
    final parts = <String>[];
    if (book.language != null && book.language!.trim().isNotEmpty) {
      parts.add(book.language!.trim().toUpperCase());
    }
    if (book.publishedDate != null) {
      parts.add('${book.publishedDate!.year}');
    } else if (book.pageCount != null) {
      parts.add('${book.pageCount} pp');
    }
    if (parts.isEmpty && book.isbn != null && book.isbn!.isNotEmpty) {
      parts.add('ISBN');
    }
    return parts.isEmpty ? 'CATALOG' : parts.join('  •  ');
  }

  static String catalogTag(BookDto book, int index) {
    if (book.language != null && book.language!.trim().isNotEmpty) {
      return book.language!.trim().toUpperCase();
    }
    const tags = ['MUST READ', 'FICTION', 'ESSAY', 'DESIGN', 'MEMOIR'];
    return tags[index % tags.length];
  }

  static Color tagColor(int index) {
    if (index == 0) return const Color(0xFFD3554A);
    return AppColors.homeTextLight;
  }

  static String formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = date.toLocal();
    return '${months[local.month - 1]} ${local.day}, ${local.year}';
  }

  static String description(BookDto book, {int maxLines = 3}) {
    final raw = book.description?.trim();
    if (raw == null || raw.isEmpty) {
      return 'No description yet — open the catalog entry to learn more.';
    }
    final lines = raw.split(RegExp(r'\r?\n'));
    final joined = lines.take(maxLines).join('\n');
    if (lines.length > maxLines) return '$joined…';
    if (raw.length > 160) return '${raw.substring(0, 157)}…';
    return joined;
  }
}
