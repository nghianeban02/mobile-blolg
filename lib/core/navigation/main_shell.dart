import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/widgets/app_drawer.dart';
import 'package:mobile/core/widgets/main_bottom_nav.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mobile/features/home/screens/home_screen.dart';
import 'package:mobile/features/messages/screens/conversations_screen.dart';
import 'package:mobile/features/posts/screens/create_post_screen.dart';
import 'package:mobile/features/reading_list/screens/reading_list_screen.dart';
import 'package:mobile/features/settings/screens/settings_screen.dart';

/// Root scaffold after login — bottom nav mirror web `MobileNav`:
/// Home · Messages · Write · Library · Settings.
class MainShell extends StatefulWidget {
  final int initialIndex;
  final String? initialSearchQuery;

  const MainShell({super.key, this.initialIndex = 0, this.initialSearchQuery});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;

  final _homeKey = GlobalKey<HomeScreenState>();
  final _libraryKey = GlobalKey<ReadingListScreenState>();
  final _settingsKey = GlobalKey<SettingsScreenState>();

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

  /// Nút Write — luôn tạo bài viết (parity web `/posts/create`).
  Future<void> _onCreateTap() async {
    final created = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const CreatePostScreen()));
    if (created == true) {
      _homeKey.currentState?.refresh();
    }
  }

  void _onTabChanged(int index) {
    if (_currentIndex != index) {
      setState(() => _currentIndex = index);
    }
    if (index == 2) {
      _libraryKey.currentState?.ensureLoaded();
    }
    if (index == 3) {
      _settingsKey.currentState?.refreshProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild when auth profile changes (settings/messages need user id).
    context.watch<AuthBloc>();

    return Scaffold(
      drawer: const AppDrawer(),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          RepaintBoundary(child: HomeScreen(key: _homeKey)),
          const RepaintBoundary(child: ConversationsScreen()),
          RepaintBoundary(
            child: ReadingListScreen(key: _libraryKey, loadOnMount: false),
          ),
          RepaintBoundary(child: SettingsScreen(key: _settingsKey)),
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
