import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/data/models/engagement_dtos.dart';
import 'package:mobile/data/repositories/engagement_repository.dart';

class BookmarkButton extends StatefulWidget {
  final BookmarkEntityType entityType;
  final String entityId;
  final bool light;

  const BookmarkButton({
    super.key,
    required this.entityType,
    required this.entityId,
    this.light = false,
  });

  @override
  State<BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends State<BookmarkButton> {
  final _repository = BeBlogEngagementRepository();
  bool _bookmarked = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await _repository.getBookmarkStatus(
      widget.entityType,
      widget.entityId,
    );
    if (mounted && result.success) {
      setState(() => _bookmarked = result.data ?? false);
    }
  }

  Future<void> _toggle() async {
    if (_busy) return;
    final previous = _bookmarked;
    setState(() {
      _busy = true;
      _bookmarked = !previous;
    });
    final result = previous
        ? await _repository.removeBookmark(widget.entityType, widget.entityId)
        : await _repository.addBookmark(widget.entityType, widget.entityId);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _bookmarked = result.success ? (result.data ?? !previous) : previous;
    });
    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.statusCode == 403
                ? 'Tài khoản khách không thể lưu nội dung.'
                : (result.message ?? 'Không cập nhật được mục đã lưu.'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: _bookmarked ? 'Bỏ lưu' : 'Lưu để đọc sau',
    onPressed: _busy ? null : _toggle,
    icon: _busy
        ? SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: widget.light ? Colors.white : AppColors.primaryBrown,
            ),
          )
        : Icon(
            _bookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: widget.light ? Colors.white : AppColors.homeTextDark,
          ),
  );
}
