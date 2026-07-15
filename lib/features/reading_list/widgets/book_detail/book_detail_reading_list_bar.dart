import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/data/auth/auth_repository.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/data/repositories/reading_list_repository.dart';
import 'package:mobile/features/reading_list/screens/my_reading_list_screen.dart';

class BookDetailReadingListBar extends StatefulWidget {
  final String bookId;

  const BookDetailReadingListBar({super.key, required this.bookId});

  @override
  State<BookDetailReadingListBar> createState() =>
      _BookDetailReadingListBarState();
}

class _BookDetailReadingListBarState extends State<BookDetailReadingListBar> {
  final _readingListRepo = BeBlogReadingListRepository();
  final _authRepo = AuthRepository();

  bool _busy = false;
  bool _onList = false;

  Future<void> _toggle() async {
    final token = await _authRepo.getToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đăng nhập để thêm vào reading list.',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _busy = true);
    final result = await _readingListRepo.add(
      ReadingListWriteRequest(bookId: widget.bookId, status: 'reading'),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _onList = result.success;
    });

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã thêm vào reading list.',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Không thêm được.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _busy ? null : _toggle,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.homeTextDark,
                side: BorderSide(color: Colors.black.withValues(alpha: 0.12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                _onList ? 'ON YOUR LIST' : 'ADD TO READING LIST',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyReadingListScreen()),
              );
            },
            icon: const Icon(
              Icons.menu_book_outlined,
              color: AppColors.primaryBrown,
            ),
          ),
        ],
      ),
    );
  }
}
