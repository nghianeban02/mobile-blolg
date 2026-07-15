import 'package:flutter/material.dart';
import 'package:mobile/core/widgets/main_bottom_nav.dart';
import 'package:mobile/features/home/screens/home_screen.dart';
import 'package:mobile/features/posts/screens/create_post_screen.dart';
import 'package:mobile/features/reading_list/screens/reading_list_screen.dart';
import 'package:mobile/features/review/screens/create_book_review_screen.dart';
import 'package:mobile/features/search/screens/search_screen.dart';
import 'package:mobile/features/settings/screens/settings_screen.dart';

/// Root scaffold after login: preserves tab state via [IndexedStack].
class MainShell extends StatefulWidget {
  final int initialIndex;

  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;

  final _homeKey = GlobalKey<HomeScreenState>();
  final _libraryKey = GlobalKey<ReadingListScreenState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 3);
    if (_currentIndex == 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _libraryKey.currentState?.ensureLoaded();
      });
    }
  }

  /// Nút Write luôn hiển thị (đồng bộ bottom nav web):
  /// mặc định tạo bài viết, riêng tab Library tạo review sách.
  void _onCreateTap() {
    if (_currentIndex == 2) {
      _openCreateBookReview();
    } else {
      _openCreatePost();
    }
  }

  Future<void> _openCreatePost() async {
    final created = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const CreatePostScreen()));
    if (created == true) {
      _homeKey.currentState?.refresh();
    }
  }

  Future<void> _openCreateBookReview() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateBookReviewScreen()),
    );
    if (created == true) {
      _homeKey.currentState?.refresh();
      _libraryKey.currentState?.refresh();
    }
  }

  void _onTabChanged(int index) {
    if (_currentIndex != index) {
      setState(() => _currentIndex = index);
    }
    if (index == 2) {
      _libraryKey.currentState?.ensureLoaded();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          RepaintBoundary(child: HomeScreen(key: _homeKey)),
          const RepaintBoundary(child: SearchScreen()),
          RepaintBoundary(
            child: ReadingListScreen(key: _libraryKey, loadOnMount: false),
          ),
          const RepaintBoundary(child: SettingsScreen()),
        ],
      ),
      bottomNavigationBar: MainBottomNavBar(
        currentIndex: _currentIndex,
        onCreateTap: _onCreateTap,
        onIndexChanged: _onTabChanged,
      ),
    );
  }
}
