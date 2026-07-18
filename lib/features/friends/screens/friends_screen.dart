import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/navigation/open_user_profile.dart';
import 'package:mobile/core/network/be_blog_http.dart';
import 'package:mobile/core/widgets/async_loading_view.dart';
import 'package:mobile/core/widgets/detail_app_bar.dart';
import 'package:mobile/core/widgets/editorial_form_field.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/data/repositories/friends_repository.dart';
import 'package:mobile/data/repositories/users_repository.dart';
import 'package:mobile/features/friends/widgets/friend_user_tile.dart';
import 'package:mobile/features/friends/widgets/incoming_request_tile.dart';
import 'package:mobile/features/posts/widgets/post_section_label.dart';

/// Kết bạn: danh sách bạn, lời mời đến/đi, tìm user (`/api/friends`, `/api/users/search`).
class FriendsScreen extends StatefulWidget {
  /// 0 = bạn, 1 = lời mời đến, 2 = lời mời đi.
  final int initialTab;

  const FriendsScreen({super.key, this.initialTab = 0});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  final _friendsRepo = BeBlogFriendsRepository();
  final _usersRepo = BeBlogUsersRepository();
  final _searchCtrl = TextEditingController();

  late final TabController _tabs;

  bool _loading = true;
  String? _error;
  List<UserPublicDto> _friends = const [];
  List<FriendshipDto> _incoming = const [];
  List<FriendshipDto> _outgoing = const [];

  bool _searching = false;
  List<UserPublicDto> _searchHits = const [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 2),
    );
    _load();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim();
    if (q.length < 2) {
      setState(() {
        _searchHits = const [];
        _searching = false;
      });
      return;
    }
    _runSearch(q);
  }

  Future<void> _runSearch(String q) async {
    setState(() => _searching = true);
    final result = await _usersRepo.searchUsers(q);
    if (!mounted) return;
    setState(() {
      _searching = false;
      _searchHits = result.success ? (result.data ?? const []) : const [];
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final results = await Future.wait([
      _friendsRepo.listFriends(),
      _friendsRepo.incomingRequests(),
      _friendsRepo.outgoingRequests(),
    ]);
    if (!mounted) return;

    final friends = results[0] as BeBlogRepoResult<List<UserPublicDto>>;
    if (!friends.success) {
      setState(() {
        _loading = false;
        _error = friends.message ?? 'Không tải được danh sách bạn.';
      });
      return;
    }

    setState(() {
      _loading = false;
      _friends = friends.data ?? const [];
      _incoming =
          (results[1] as BeBlogRepoResult<List<FriendshipDto>>).data ??
          const [];
      _outgoing =
          (results[2] as BeBlogRepoResult<List<FriendshipDto>>).data ??
          const [];
    });
  }

  void _openProfile(UserPublicDto user) {
    openUserProfile(
      context,
      userId: user.id,
      displayName: user.displayName,
    ).then((_) {
      if (mounted) _load();
    });
  }

  bool get _showTabs => !_loading && _error == null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primaryBrown,
          onRefresh: _load,
          child: NestedScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            headerSliverBuilder: (context, _) => [
              const DetailSliverAppBar(),
              SliverToBoxAdapter(child: _buildHeaderSection()),
              if (_loading || _error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: AsyncLoadingView(
                    isLoading: _loading,
                    errorMessage: _error,
                    onRetry: _load,
                  ),
                )
              else
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _FriendsTabBarDelegate(
                    tabBar: TabBar(
                      controller: _tabs,
                      labelColor: AppColors.primaryBrown,
                      unselectedLabelColor: AppColors.homeTextLight,
                      indicatorColor: AppColors.primaryBrown,
                      labelStyle: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                      tabs: [
                        Tab(text: 'BẠN (${_friends.length})'),
                        Tab(text: 'ĐẾN (${_incoming.length})'),
                        Tab(text: 'ĐI (${_outgoing.length})'),
                      ],
                    ),
                  ),
                ),
            ],
            body: _showTabs
                ? TabBarView(
                    controller: _tabs,
                    children: [
                      _FriendsListTab(friends: _friends, onOpen: _openProfile),
                      _IncomingTab(
                        items: _incoming,
                        onChanged: _load,
                        onOpenProfile: _openProfile,
                      ),
                      _OutgoingTab(
                        items: _outgoing,
                        onOpen: _openProfile,
                        onChanged: _load,
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Editorial\ncircle',
            style: GoogleFonts.playfairDisplay(
              fontSize: 36,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Quản lý bạn bè và lời mời. Chạm vào tên để mở trang độc giả.',
            style: GoogleFonts.inter(
              color: AppColors.homeTextLight,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          EditorialFormField(
            label: 'Find readers',
            hint: 'Tìm độc giả (từ 2 ký tự)…',
            controller: _searchCtrl,
          ),
          if (_searchCtrl.text.trim().length >= 2) ...[
            const SizedBox(height: 16),
            PostSectionLabel(
              text: _searching ? 'Đang tìm…' : '${_searchHits.length} kết quả',
            ),
            const SizedBox(height: 8),
            if (!_searching)
              ..._searchHits.map(
                (u) => FriendUserTile(user: u, onTap: () => _openProfile(u)),
              ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _FriendsTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _FriendsTabBarDelegate({required this.tabBar});

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(color: AppColors.homeBackground, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant _FriendsTabBarDelegate oldDelegate) =>
      tabBar != oldDelegate.tabBar;
}

class _FriendsListTab extends StatelessWidget {
  final List<UserPublicDto> friends;
  final void Function(UserPublicDto) onOpen;

  const _FriendsListTab({required this.friends, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) {
      return ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 48),
          Center(
            child: Text(
              'Chưa có bạn bè. Dùng ô tìm kiếm phía trên để kết bạn.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.homeTextLight,
                fontSize: 13,
              ),
            ),
          ),
        ],
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      itemCount: friends.length,
      itemBuilder: (_, i) => Padding(
        padding: EdgeInsets.only(bottom: i < friends.length - 1 ? 12 : 0),
        child: FriendUserTile(
          user: friends[i],
          onTap: () => onOpen(friends[i]),
        ),
      ),
    );
  }
}

class _IncomingTab extends StatelessWidget {
  final List<FriendshipDto> items;
  final VoidCallback onChanged;
  final void Function(UserPublicDto) onOpenProfile;

  const _IncomingTab({
    required this.items,
    required this.onChanged,
    required this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 48),
          Center(
            child: Text(
              'Không có lời mời đến.',
              style: GoogleFonts.inter(
                color: AppColors.homeTextLight,
                fontSize: 13,
              ),
            ),
          ),
        ],
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      itemCount: items.length,
      itemBuilder: (_, i) => IncomingRequestTile(
        friendship: items[i],
        onChanged: onChanged,
        onOpenProfile: onOpenProfile,
      ),
    );
  }
}

class _OutgoingTab extends StatelessWidget {
  final List<FriendshipDto> items;
  final void Function(UserPublicDto) onOpen;
  final VoidCallback onChanged;

  const _OutgoingTab({
    required this.items,
    required this.onOpen,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 48),
          Center(
            child: Text(
              'Không có lời mời đang gửi.',
              style: GoogleFonts.inter(
                color: AppColors.homeTextLight,
                fontSize: 13,
              ),
            ),
          ),
        ],
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final friendship = items[i];
        final user = friendship.addressee;
        if (user == null) return const SizedBox.shrink();
        return _OutgoingRequestTile(
          friendship: friendship,
          user: user,
          onOpen: () => onOpen(user),
          onChanged: onChanged,
        );
      },
    );
  }
}

class _OutgoingRequestTile extends StatefulWidget {
  final FriendshipDto friendship;
  final UserPublicDto user;
  final VoidCallback onOpen;
  final VoidCallback onChanged;

  const _OutgoingRequestTile({
    required this.friendship,
    required this.user,
    required this.onOpen,
    required this.onChanged,
  });

  @override
  State<_OutgoingRequestTile> createState() => _OutgoingRequestTileState();
}

class _OutgoingRequestTileState extends State<_OutgoingRequestTile> {
  final _repo = BeBlogFriendsRepository();
  bool _busy = false;

  Future<void> _cancel() async {
    if (_busy) return;
    setState(() => _busy = true);
    final result = await _repo.cancelRequest(widget.friendship.id);
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.success) {
      widget.onChanged();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Không thể hủy lời mời.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FriendUserTile(
        user: widget.user,
        onTap: widget.onOpen,
        trailing: _busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryBrown,
                ),
              )
            : TextButton(
                onPressed: _cancel,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'HỦY',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
      ),
    );
  }
}
