import 'package:flutter/material.dart';
import 'package:mobile/core/i18n/locale_controller.dart';
import 'package:mobile/core/navigation/open_user_profile.dart';
import 'package:mobile/core/network/be_blog_http.dart';
import 'package:mobile/core/theme/app_palette.dart';
import 'package:mobile/core/theme/app_spacing.dart';
import 'package:mobile/core/theme/app_typography.dart';
import 'package:mobile/core/widgets/async_loading_view.dart';
import 'package:mobile/core/widgets/detail_app_bar.dart';
import 'package:mobile/core/widgets/editorial_form_field.dart';
import 'package:mobile/core/widgets/editorial_page_header.dart';
import 'package:mobile/core/widgets/editorial_states.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/data/repositories/friends_repository.dart';
import 'package:mobile/data/repositories/users_repository.dart';
import 'package:mobile/features/friends/widgets/friend_user_tile.dart';
import 'package:mobile/features/friends/widgets/incoming_request_tile.dart';

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
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: p.accent,
          onRefresh: _load,
          child: NestedScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            headerSliverBuilder: (context, _) => [
              const DetailSliverAppBar(),
              SliverToBoxAdapter(child: _buildHeaderSection(context)),
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
                      labelColor: p.accent,
                      unselectedLabelColor: p.muted,
                      indicatorColor: p.accent,
                      labelStyle: AppTypography.meta(context).copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: p.accent,
                      ),
                      unselectedLabelStyle: AppTypography.meta(context),
                      tabs: [
                        Tab(
                          text:
                              '${context.t('friends.tabFriends').toUpperCase()} (${_friends.length})',
                        ),
                        Tab(
                          text:
                              '${context.t('friends.tabIncoming').toUpperCase()} (${_incoming.length})',
                        ),
                        Tab(
                          text:
                              '${context.t('friends.tabOutgoing').toUpperCase()} (${_outgoing.length})',
                        ),
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

  Widget _buildHeaderSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageX,
        8,
        AppSpacing.pageX,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EditorialPageHeader(
            title: context.t('friends.title'),
            subtitle: context.t('friends.searchPrompt'),
            padding: EdgeInsets.zero,
          ),
          EditorialFormField(
            label: context.t('friends.findReadersBtn'),
            hint: context.t('friends.searchUsernamePlaceholder'),
            controller: _searchCtrl,
          ),
          if (_searchCtrl.text.trim().length >= 2) ...[
            const SizedBox(height: 16),
            Text(
              _searching
                  ? context.t('friends.searching')
                  : '${_searchHits.length} kết quả',
              style: AppTypography.sectionEyebrow(context),
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
    return Material(color: context.palette.background, child: tabBar);
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
          const SizedBox(height: 24),
          EditorialEmptyState(
            title: context.t('friends.emptyFriendsTitle'),
            message: context.t('friends.emptyFriendsMessage'),
            icon: EditorialEmptyIcon.friends,
          ),
        ],
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.pageX),
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
          const SizedBox(height: 24),
          EditorialEmptyState(
            message: context.t('friends.emptyIncoming'),
            icon: EditorialEmptyIcon.friends,
          ),
        ],
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageX,
        16,
        AppSpacing.pageX,
        24,
      ),
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
          const SizedBox(height: 24),
          EditorialEmptyState(
            message: context.t('friends.emptyOutgoing'),
            icon: EditorialEmptyIcon.friends,
          ),
        ],
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.pageX),
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
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FriendUserTile(
        user: widget.user,
        onTap: widget.onOpen,
        trailing: _busy
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: p.accent,
                ),
              )
            : TextButton(
                onPressed: _cancel,
                style: TextButton.styleFrom(
                  foregroundColor: p.danger,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  context.t('friends.actionCancelInvite').toUpperCase(),
                  style: AppTypography.meta(
                    context,
                    color: p.danger,
                  ).copyWith(fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
      ),
    );
  }
}
