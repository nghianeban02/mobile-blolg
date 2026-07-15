import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/services/chat_realtime_service.dart';
import 'package:mobile/data/messaging/chat_models.dart';
import 'package:mobile/data/messaging/messaging_api.dart';
import 'package:mobile/data/repositories/users_repository.dart';
import 'package:mobile/features/messages/screens/chat_screen.dart';
import 'package:mobile/features/messages/widgets/chat_avatar.dart';

/// Danh sách hội thoại — UX như trang `/messages` bản web:
/// tìm kiếm, badge chưa đọc, chấm online, tạo chat 1-1/nhóm, realtime.
class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final _realtime = ChatRealtimeService.instance;
  StreamSubscription<ChatRealtimeEvent>? _subscription;

  bool _loading = true;
  String? _error;
  String _query = '';
  String? _currentUserId;
  List<ChatConversation> _conversations = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_realtime.start());
    _realtime.addListener(_onRealtimeState);
    _subscription = _realtime.events.listen(_onEvent);
    unawaited(_load());
    unawaited(BeBlogUsersRepository().me().then((result) {
      if (mounted && result.success) {
        setState(() => _currentUserId = result.data?.id);
      }
    }));
  }

  @override
  void dispose() {
    _realtime.removeListener(_onRealtimeState);
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  void _onRealtimeState() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    try {
      final items = await MessagingApi.conversations();
      if (!mounted) return;
      setState(() {
        _conversations = items;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _onEvent(ChatRealtimeEvent event) {
    // Danh sách nhẹ nên đồng bộ bằng cách tải lại (đã debounce phía service).
    if (event.type == 'message.created' ||
        event.type == 'message.revoked' ||
        event.type == 'conversation.read' ||
        event.type.startsWith('conversation.')) {
      unawaited(_load());
    }
  }

  Future<void> _openChat(ChatConversation conversation) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChatScreen(
        conversation: conversation,
        currentUserId: _currentUserId,
      ),
    ));
    if (mounted) unawaited(_load());
  }

  Future<void> _openNewChat() async {
    final created = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _NewChatSheet(),
    );
    if (created == null || !mounted) return;
    await _load();
    final conversation =
        _conversations.where((item) => item.id == created).firstOrNull;
    if (conversation != null) await _openChat(conversation);
  }

  List<ChatConversation> get _filtered {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _conversations;
    return _conversations
        .where((item) =>
            item.displayName(_currentUserId).toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Tin nhắn',
            style: GoogleFonts.playfairDisplay(
                fontSize: 22, fontWeight: FontWeight.w600)),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryBrown,
        shape: const CircleBorder(),
        onPressed: _openNewChat,
        child: const Icon(Icons.edit_outlined, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: 'Tìm cuộc trò chuyện',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _ConnectionDot(connected: _realtime.connected),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _ErrorView(message: _error!, onRetry: _load)
                    : _filtered.isEmpty
                        ? _EmptyView(onNewChat: _openNewChat)
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _filtered.length,
                              itemBuilder: (context, index) {
                                final conversation = _filtered[index];
                                return _ConversationTile(
                                  conversation: conversation,
                                  currentUserId: _currentUserId,
                                  online: !conversation.isGroup &&
                                      _realtime.isOnline(conversation
                                              .otherMember(_currentUserId)
                                              ?.userId ??
                                          ''),
                                  onTap: () => _openChat(conversation),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
    );
  }
}

class _ConnectionDot extends StatelessWidget {
  final bool connected;

  const _ConnectionDot({required this.connected});

  @override
  Widget build(BuildContext context) => Tooltip(
        message: connected ? 'Đang hoạt động' : 'Đang kết nối…',
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: connected ? AppColors.success : Colors.grey,
          ),
        ),
      );
}

class _ConversationTile extends StatelessWidget {
  final ChatConversation conversation;
  final String? currentUserId;
  final bool online;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.currentUserId,
    required this.online,
    required this.onTap,
  });

  String get _preview {
    final message = conversation.lastMessage;
    if (message == null) return '';
    if (message.revoked) return 'Tin nhắn đã được thu hồi';
    if (message.encrypted) return '🔒 Tin nhắn được mã hoá';
    switch (message.type) {
      case 'STICKER':
        return '${message.content ?? '🙂'} Sticker';
      case 'IMAGE':
        return '📷 Hình ảnh';
      case 'FILE':
        return '📎 Tệp đính kèm';
      default:
        return message.content ?? '';
    }
  }

  String get _time {
    final at = conversation.lastMessageAt;
    final now = DateTime.now();
    if (at.year == now.year && at.month == now.month && at.day == now.day) {
      return '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
    }
    return '${at.day.toString().padLeft(2, '0')}/${at.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unread = conversation.unreadCount > 0;
    final name = conversation.displayName(currentUserId);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            ChatAvatar(
              name: name,
              avatarUrl: conversation.otherMember(currentUserId)?.avatarUrl,
              size: 50,
              online: online,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _time,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight:
                                unread ? FontWeight.w600 : FontWeight.w400,
                            color: unread
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.55),
                          ),
                        ),
                      ),
                      if (unread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBrown,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            conversation.unreadCount > 99
                                ? '99+'
                                : '${conversation.unreadCount}',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onNewChat;

  const _EmptyView({required this.onNewChat});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 44, color: AppColors.primaryBrown.withValues(alpha: 0.7)),
            const SizedBox(height: 12),
            const Text('Bạn chưa có cuộc trò chuyện nào.'),
            TextButton(
              onPressed: onNewChat,
              child: const Text('Nhắn tin cho một người bạn',
                  style: TextStyle(color: AppColors.primaryBrown)),
            ),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => onRetry(),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
}

/// Bottom sheet tạo chat mới — 1-1 hoặc nhóm, chọn từ danh sách bạn bè.
class _NewChatSheet extends StatefulWidget {
  const _NewChatSheet();

  @override
  State<_NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends State<_NewChatSheet> {
  bool _group = false;
  bool _loading = true;
  bool _submitting = false;
  String _title = '';
  List<ChatFriend> _friends = const [];
  final Set<String> _selected = <String>{};

  @override
  void initState() {
    super.initState();
    unawaited(MessagingApi.friends().then((friends) {
      if (mounted) {
        setState(() {
          _friends = friends;
          _loading = false;
        });
      }
    }).catchError((Object _) {
      if (mounted) setState(() => _loading = false);
    }));
  }

  Future<void> _submit() async {
    if (_selected.isEmpty || (_group && _title.trim().isEmpty)) return;
    setState(() => _submitting = true);
    try {
      final id = _group
          ? await MessagingApi.createGroup(_title.trim(), _selected.toList())
          : await MessagingApi.createDirect(_selected.first);
      if (mounted) Navigator.of(context).pop(id);
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Cuộc trò chuyện mới',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Nhắn tin 1–1')),
              ButtonSegment(value: true, label: Text('Tạo nhóm')),
            ],
            style: const ButtonStyle(
              shape: WidgetStatePropertyAll(StadiumBorder()),
            ),
            selected: {_group},
            onSelectionChanged: (value) => setState(() {
              _group = value.first;
              _selected.clear();
            }),
          ),
          if (_group) ...[
            const SizedBox(height: 12),
            TextField(
              onChanged: (value) => _title = value,
              maxLength: 160,
              decoration: const InputDecoration(
                  labelText: 'Tên nhóm', counterText: ''),
            ),
          ],
          const SizedBox(height: 8),
          Flexible(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _friends.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child:
                            Text('Hãy kết bạn trước khi bắt đầu trò chuyện.'),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _friends.length,
                        itemBuilder: (context, index) {
                          final friend = _friends[index];
                          final checked = _selected.contains(friend.id);
                          return CheckboxListTile(
                            value: checked,
                            activeColor: AppColors.primaryBrown,
                            title: Text(friend.username),
                            secondary: ChatAvatar(
                                name: friend.username,
                                avatarUrl: friend.avatarUrl,
                                size: 36),
                            onChanged: (_) => setState(() {
                              if (!_group) _selected.clear();
                              checked
                                  ? _selected.remove(friend.id)
                                  : _selected.add(friend.id);
                            }),
                          );
                        },
                      ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.primaryBrown),
            onPressed: _submitting || _selected.isEmpty ? null : _submit,
            child: Text(_submitting ? 'Đang tạo…' : 'Tạo cuộc trò chuyện',
                style: TextStyle(color: theme.colorScheme.onPrimary)),
          ),
        ],
      ),
    );
  }
}
