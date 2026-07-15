import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/cache/session_cache.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/constants/messaging_constants.dart';
import 'package:mobile/core/services/messaging_realtime_service.dart';
import 'package:mobile/data/models/messaging_dtos.dart';
import 'package:mobile/data/repositories/messaging_repository.dart';
import 'package:mobile/data/repositories/users_repository.dart';
import 'package:mobile/features/messaging/screens/chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _repository = MessagingRepository();
  final _realtime = MessagingRealtimeService.instance;
  final _users = BeBlogUsersRepository();
  final _search = TextEditingController();
  StreamSubscription<MessagingRealtimeEvent>? _events;
  Timer? _fallbackPoller;
  List<ChatConversationDto> _conversations = const [];
  bool _loading = true;
  String? _error;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = SessionCache.profile?.id;
    _realtime.acquire();
    _events = _realtime.events.listen((event) {
      if (event.type.startsWith('message.') ||
          event.type.startsWith('conversation.')) {
        _load(silent: true);
      }
    });
    _load();
    // Polling chỉ là dự phòng khi WebSocket mất kết nối.
    _fallbackPoller = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_realtime.connected.value) _load(silent: true);
    });
  }

  @override
  void dispose() {
    _events?.cancel();
    _realtime.release();
    _fallbackPoller?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!MessagingConstants.enabled) {
      setState(() {
        _loading = false;
        _error = 'Nhắn tin đã bị tắt qua MESSAGING_ENABLED=false.';
      });
      return;
    }
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    if (_userId == null) {
      final me = await _users.me();
      _userId = me.data?.id;
    }
    final result = await _repository.getConversations();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.success) {
        _conversations = result.data ?? const [];
        _error = null;
      } else if (!silent) {
        _error = result.message ?? 'Không tải được cuộc trò chuyện.';
      }
    });
  }

  Future<void> _newConversation() async {
    final friends = await _repository.getFriends();
    if (!mounted) return;
    if (!friends.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friends.message ?? 'Không tải được bạn bè.')),
      );
      return;
    }
    final choice = await showModalBottomSheet<_ConversationChoice>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _NewConversationSheet(friends: friends.data ?? const []),
    );
    if (choice == null || !mounted) return;
    final created = choice.group
        ? await _repository.createGroup(choice.title, choice.userIds)
        : await _repository.createDirect(choice.userIds.first);
    if (!mounted) return;
    if (!created.success || created.data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(created.message ?? 'Không tạo được cuộc trò chuyện.'),
        ),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: created.data!,
          title: choice.title,
          currentUserId: _userId,
        ),
      ),
    );
    _load();
  }

  Future<void> _open(ChatConversationDto conversation) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: conversation.id,
          title: conversation.displayTitle(_userId),
          currentUserId: _userId,
        ),
      ),
    );
    _load();
  }

  List<ChatConversationDto> get _filtered {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return _conversations;
    return _conversations
        .where(
          (item) => item.displayTitle(_userId).toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Tin nhắn'),
      actions: [
        IconButton(
          tooltip: 'Cuộc trò chuyện mới',
          onPressed: _newConversation,
          icon: const Icon(Icons.edit_square),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _newConversation,
      backgroundColor: AppColors.primaryBrown,
      foregroundColor: Colors.white,
      child: const Icon(Icons.add_comment_outlined),
    ),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 90),
        children: [
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Tìm cuộc trò chuyện…',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.surfaceContainerHigh
                  : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primaryBrown),
              ),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Column(
                children: [
                  const Icon(Icons.forum_outlined, size: 48),
                  const SizedBox(height: 12),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _load,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            )
          else if (_filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 56),
              child: Column(
                children: [
                  Icon(Icons.chat_bubble_outline, size: 50),
                  SizedBox(height: 12),
                  Text('Chưa có cuộc trò chuyện.'),
                ],
              ),
            )
          else
            ValueListenableBuilder<Set<String>>(
              valueListenable: _realtime.onlineUsers,
              builder: (context, online, _) => Column(
                children: _filtered
                    .map(
                      (conversation) => _ConversationTile(
                        conversation: conversation,
                        title: conversation.displayTitle(_userId),
                        online:
                            conversation.type == 'DIRECT' &&
                            conversation.members.any(
                              (member) =>
                                  member.userId != _userId &&
                                  online.contains(member.userId),
                            ),
                        onTap: () => _open(conversation),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    ),
  );
}

class _ConversationTile extends StatelessWidget {
  final ChatConversationDto conversation;
  final String title;
  final bool online;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.title,
    required this.online,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final last = conversation.lastMessage;
    final preview = last?.revokedAt != null
        ? 'Tin nhắn đã được thu hồi'
        : last?.type == 'IMAGE'
        ? '📷 Hình ảnh'
        : (last?.content ?? 'Bắt đầu trò chuyện');
    return Card(
      elevation: 0,
      color: Theme.of(context).brightness == Brightness.dark
          ? null
          : Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.coverSand,
              child: Text(
                title.isEmpty ? '?' : title[0].toUpperCase(),
                style: const TextStyle(color: AppColors.homeTextDark),
              ),
            ),
            if (online)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: conversation.unreadCount > 0
            ? Badge(label: Text('${conversation.unreadCount}'))
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _ConversationChoice {
  final bool group;
  final String title;
  final List<String> userIds;

  const _ConversationChoice({
    required this.group,
    required this.title,
    required this.userIds,
  });
}

class _NewConversationSheet extends StatefulWidget {
  final List<ChatFriendDto> friends;

  const _NewConversationSheet({required this.friends});

  @override
  State<_NewConversationSheet> createState() => _NewConversationSheetState();
}

class _NewConversationSheetState extends State<_NewConversationSheet> {
  bool _group = false;
  final _title = TextEditingController();
  final Set<String> _selected = {};

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selected.isEmpty) return;
    final selectedFriends = widget.friends
        .where((friend) => _selected.contains(friend.id))
        .toList();
    final title = _group ? _title.text.trim() : selectedFriends.first.username;
    if (_group && title.isEmpty) return;
    Navigator.pop(
      context,
      _ConversationChoice(
        group: _group,
        title: title,
        userIds: _selected.toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.68,
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Trò chuyện mới',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                FilterChip(
                  label: const Text('Nhóm'),
                  selected: _group,
                  onSelected: (value) => setState(() {
                    _group = value;
                    if (!value && _selected.length > 1) {
                      final first = _selected.first;
                      _selected
                        ..clear()
                        ..add(first);
                    }
                  }),
                ),
              ],
            ),
            if (_group)
              TextField(
                controller: _title,
                maxLength: 120,
                decoration: const InputDecoration(labelText: 'Tên nhóm *'),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: widget.friends.isEmpty
                  ? const Center(child: Text('Bạn chưa có bạn bè để nhắn tin.'))
                  : ListView(
                      children: widget.friends
                          .map(
                            (friend) => CheckboxListTile(
                              value: _selected.contains(friend.id),
                              title: Text(friend.username),
                              secondary: CircleAvatar(
                                child: Text(
                                  friend.username.isEmpty
                                      ? '?'
                                      : friend.username[0].toUpperCase(),
                                ),
                              ),
                              onChanged: (selected) => setState(() {
                                if (!_group) _selected.clear();
                                if (selected == true) {
                                  _selected.add(friend.id);
                                } else {
                                  _selected.remove(friend.id);
                                }
                              }),
                            ),
                          )
                          .toList(),
                    ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selected.isEmpty ? null : _submit,
                child: Text(_group ? 'Tạo nhóm' : 'Bắt đầu trò chuyện'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
