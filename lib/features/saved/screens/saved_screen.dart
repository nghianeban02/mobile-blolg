import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/utils/format_datetime.dart';
import 'package:mobile/data/models/engagement_dtos.dart';
import 'package:mobile/data/repositories/engagement_repository.dart';
import 'package:mobile/features/posts/screens/post_detail_screen.dart';
import 'package:mobile/features/review/screens/book_detail_screen.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  final _repository = BeBlogEngagementRepository();
  bool _loading = true;
  String? _error;
  List<BookmarkItemDto> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repository.getBookmarks();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _items = result.data ?? const [];
      _error = result.success
          ? null
          : (result.message ?? 'Không tải được nội dung đã lưu.');
    });
  }

  void _open(BookmarkItemDto item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => item.entityType == BookmarkEntityType.post
            ? PostDetailScreen(postId: item.entityId)
            : BookDetailScreen(reviewId: item.entityId),
      ),
    );
  }

  Future<void> _remove(BookmarkItemDto item) async {
    final index = _items.indexOf(item);
    setState(() => _items = _items.where((value) => value != item).toList());
    final result = await _repository.removeBookmark(
      item.entityType,
      item.entityId,
    );
    if (!mounted || result.success) return;
    setState(() {
      final restored = [..._items];
      restored.insert(index.clamp(0, restored.length), item);
      _items = restored;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.homeBackground,
    appBar: AppBar(title: const Text('Đã lưu')),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 48),
        children: [
          Text(
            'Đọc lại sau',
            style: GoogleFonts.playfairDisplay(
              fontSize: 34,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bài viết và review bạn đã đánh dấu được đồng bộ với web-blog.',
            style: TextStyle(color: AppColors.homeTextLight),
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primaryBrown),
              ),
            )
          else if (_error != null)
            Center(
              child: Column(
                children: [
                  Text(_error!),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _load,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            )
          else if (_items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 64),
              child: Column(
                children: [
                  Icon(Icons.bookmark_border, size: 52),
                  SizedBox(height: 12),
                  Text('Bạn chưa lưu nội dung nào.'),
                ],
              ),
            )
          else
            ..._items.map(
              (item) => Card(
                elevation: 0,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => _open(item),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 8, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.entityType == BookmarkEntityType.post
                                    ? 'BÀI VIẾT'
                                    : 'REVIEW',
                                style: const TextStyle(
                                  color: AppColors.primaryBrown,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                item.title,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (item.excerpt.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  item.excerpt,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.homeTextLight,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Text(
                                'Đã lưu ${formatCommentDateTime(item.savedAt)}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.homeTextLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Bỏ lưu',
                          onPressed: () => _remove(item),
                          icon: const Icon(
                            Icons.bookmark,
                            color: AppColors.primaryBrown,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
