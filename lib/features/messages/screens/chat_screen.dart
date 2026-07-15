import 'dart:async';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_view/photo_view.dart';

import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/services/chat_realtime_service.dart';
import 'package:mobile/data/messaging/chat_models.dart';
import 'package:mobile/data/messaging/messaging_api.dart';
import 'package:mobile/features/messages/chat_stickers.dart';
import 'package:mobile/features/messages/widgets/chat_avatar.dart';

/// Khung chat — UX như bản web: optimistic send, sticker, reply, reaction,
/// sửa/thu hồi tin, typing indicator, ngăn cách ngày, đánh dấu đã đọc.
class ChatScreen extends StatefulWidget {
  final ChatConversation conversation;
  final String? currentUserId;

  const ChatScreen({
    super.key,
    required this.conversation,
    required this.currentUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _realtime = ChatRealtimeService.instance;
  final _input = TextEditingController();
  final _scroll = ScrollController();
  StreamSubscription<ChatRealtimeEvent>? _subscription;
  Timer? _typingStopTimer;
  Timer? _markReadTimer;

  bool _loading = true;
  bool _loadingOlder = false;
  bool _stickersOpen = false;
  int? _cursor;
  int _maxSequence = 0;
  List<ChatMessage> _messages = const [];
  ChatMessage? _replyTo;
  ChatMessage? _editing;
  final Map<String, String> _typingUsers = {};
  final Set<String> _pendingClientIds = <String>{};

  String? get _me => widget.currentUserId;

  @override
  void initState() {
    super.initState();
    _subscription = _realtime.events.listen(_onEvent);
    _realtime.addListener(_onRealtimeState);
    unawaited(_load());
  }

  @override
  void dispose() {
    _realtime.removeListener(_onRealtimeState);
    unawaited(_subscription?.cancel());
    _typingStopTimer?.cancel();
    _markReadTimer?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onRealtimeState() {
    if (mounted) setState(() {});
  }

  // ─── Data ───

  Future<void> _load({bool older = false}) async {
    if (older && (_cursor == null || _loadingOlder)) return;
    if (older) setState(() => _loadingOlder = true);
    try {
      final result = await MessagingApi.messages(
        widget.conversation.id,
        before: older ? _cursor : null,
      );
      if (!mounted) return;
      final ascending = result.items.reversed.toList();
      setState(() {
        if (older) {
          final known = _messages.map((item) => item.id).toSet();
          _messages = [
            ...ascending.where((item) => !known.contains(item.id)),
            ..._messages,
          ];
        } else {
          _messages = ascending;
        }
        _cursor = result.nextCursor;
        _loading = false;
        _loadingOlder = false;
      });
      final newest = ascending.isEmpty ? null : ascending.last;
      if (newest != null) {
        _maxSequence =
            _maxSequence > newest.sequence.toInt() ? _maxSequence : newest.sequence.toInt();
      }
      if (!older) {
        _scheduleMarkRead();
        _jumpToBottom();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingOlder = false;
      });
      _showError(e);
    }
  }

  void _scheduleMarkRead() {
    _markReadTimer?.cancel();
    _markReadTimer = Timer(const Duration(milliseconds: 400), () {
      if (_maxSequence <= 0) return;
      unawaited(MessagingApi.markRead(widget.conversation.id, _maxSequence)
          .then((_) => _realtime.refreshUnread())
          .catchError((Object _) {}));
    });
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  void _upsert(ChatMessage incoming, {String? replaceClientId}) {
    setState(() {
      var next = List<ChatMessage>.of(_messages);
      if (replaceClientId != null) {
        next.removeWhere(
            (item) => item.pending && item.clientId == replaceClientId);
      }
      final index = next.indexWhere((item) => item.id == incoming.id);
      if (index >= 0) {
        next[index] = incoming;
      } else {
        next.add(incoming);
        next.sort((a, b) => a.sequence.compareTo(b.sequence));
      }
      _messages = next;
    });
    if (!incoming.pending && incoming.sequence.toInt() > _maxSequence) {
      _maxSequence = incoming.sequence.toInt();
    }
  }

  void _patch(String messageId, ChatMessage Function(ChatMessage) patch) {
    setState(() {
      _messages = [
        for (final item in _messages)
          if (item.id == messageId) patch(item) else item,
      ];
    });
  }

  // ─── Realtime ───

  void _onEvent(ChatRealtimeEvent event) {
    if (event.conversationId != widget.conversation.id) return;
    final payload = event.payload;
    switch (event.type) {
      case 'typing.start':
        final userId = payload['userId'];
        if (userId is String && userId != _me) {
          setState(() =>
              _typingUsers[userId] = payload['username'] as String? ?? '');
        }
      case 'typing.stop':
        final userId = payload['userId'];
        if (userId is String && _typingUsers.remove(userId) != null) {
          setState(() {});
        }
      case 'message.created':
        final senderId = payload['senderId'] as String? ?? '';
        final mine = senderId == _me;
        // Tin của mình do POST trả về xử lý — bỏ qua echo khi đang gửi.
        if (mine && _pendingClientIds.isNotEmpty) return;
        final type = payload['type'] as String? ?? 'TEXT';
        if (!(type == 'TEXT' || type == 'STICKER') ||
            payload['encrypted'] == true) {
          unawaited(_load());
          return;
        }
        _typingUsers.remove(senderId);
        _upsert(ChatMessage(
          id: payload['messageId'] as String? ?? '',
          sequence: (payload['sequence'] as num?)?.toDouble() ?? 0,
          conversationId: widget.conversation.id,
          senderId: senderId,
          senderUsername: payload['senderUsername'] as String? ?? '',
          type: type,
          content: payload['content'] as String?,
          encrypted: false,
          createdAt: DateTime.tryParse(payload['createdAt'] as String? ?? '')
                  ?.toLocal() ??
              DateTime.now(),
        ));
        _jumpToBottom();
        if (!mine) _scheduleMarkRead();
      case 'message.revoked':
        final messageId = payload['messageId'];
        if (messageId is String) {
          _patch(
              messageId,
              (message) => message.copyWith(
                  clearContent: true, revokedAt: DateTime.now()));
        }
      case 'message.updated':
        final messageId = payload['messageId'];
        final content = payload['content'];
        if (messageId is String && content is String) {
          _patch(
              messageId,
              (message) =>
                  message.copyWith(content: content, editedAt: DateTime.now()));
        }
      case 'message.reaction':
        final messageId = payload['messageId'];
        final userId = payload['userId'];
        final emoji = payload['emoji'];
        if (messageId is String && userId is String && emoji is String) {
          _patch(messageId, (message) {
            final others = message.reactions
                .where((item) =>
                    !(item.userId == userId && item.emoji == emoji))
                .toList();
            if (payload['active'] == true) {
              others.add(MessageReaction(userId: userId, emoji: emoji));
            }
            return message.copyWith(reactions: others);
          });
        }
    }
  }

  // ─── Gửi / sửa / thu hồi ───

  void _notifyTyping() {
    _realtime.send(
        {'type': 'typing.start', 'conversationId': widget.conversation.id});
    _typingStopTimer?.cancel();
    _typingStopTimer = Timer(const Duration(milliseconds: 1800), () {
      _realtime.send(
          {'type': 'typing.stop', 'conversationId': widget.conversation.id});
    });
  }

  Future<void> _deliver({required String type, required String content}) async {
    final clientId = _uuidV4();
    final reply = _replyTo;
    final optimistic = ChatMessage(
      id: clientId,
      sequence: _maxSequence + 0.5,
      conversationId: widget.conversation.id,
      senderId: _me ?? '',
      senderUsername: '',
      type: type,
      content: content,
      encrypted: false,
      replyTo: reply == null
          ? null
          : ChatReplyPreview(
              id: reply.id,
              senderId: reply.senderId,
              content: reply.content,
              type: reply.type,
              revoked: reply.revoked,
            ),
      createdAt: DateTime.now(),
      pending: true,
      clientId: clientId,
    );
    _pendingClientIds.add(clientId);
    _upsert(optimistic);
    setState(() => _replyTo = null);
    _jumpToBottom();
    try {
      final sent = await MessagingApi.sendMessage(
        widget.conversation.id,
        clientId: clientId,
        type: type,
        content: content,
        replyToId: reply?.id,
      );
      _upsert(
        ChatMessage(
          id: sent.id,
          sequence: sent.sequence,
          conversationId: widget.conversation.id,
          senderId: _me ?? '',
          senderUsername: sent.senderUsername,
          type: type,
          content: sent.content ?? content,
          encrypted: false,
          replyTo: optimistic.replyTo,
          createdAt: sent.createdAt,
        ),
        replaceClientId: clientId,
      );
      _jumpToBottom();
    } catch (e) {
      setState(() =>
          _messages = _messages.where((item) => item.id != clientId).toList());
      if (type == 'TEXT' && _input.text.trim().isEmpty) _input.text = content;
      _showError(e);
    } finally {
      _pendingClientIds.remove(clientId);
    }
  }

  /// UUID v4 — messaging-service yêu cầu clientId dạng uuid (idempotency key).
  static String _uuidV4() {
    final rng = Random.secure();
    String hex(int length) => List.generate(
        length, (_) => '0123456789abcdef'[rng.nextInt(16)]).join();
    return '${hex(8)}-${hex(4)}-4${hex(3)}-${'89ab'[rng.nextInt(4)]}${hex(3)}-${hex(12)}';
  }

  Future<void> _send() async {
    final content = _input.text.trim();
    if (content.isEmpty) return;
    if (_editing != null) {
      await _saveEdit(content);
      return;
    }
    _input.clear();
    _realtime.send(
        {'type': 'typing.stop', 'conversationId': widget.conversation.id});
    await _deliver(type: 'TEXT', content: content);
  }

  Future<void> _saveEdit(String content) async {
    final target = _editing;
    if (target == null) return;
    setState(() => _editing = null);
    _input.clear();
    if (content == (target.content ?? '').trim()) return;
    final previous = target.content;
    _patch(target.id,
        (message) => message.copyWith(content: content, editedAt: DateTime.now()));
    try {
      final result = await MessagingApi.editMessage(target.id, content);
      _patch(
          target.id,
          (message) => message.copyWith(
              content: result.content, editedAt: result.editedAt));
    } catch (e) {
      _patch(target.id, (message) => message.copyWith(content: previous));
      _showError(e);
    }
  }

  Future<void> _sendSticker(String sticker) async {
    setState(() => _stickersOpen = false);
    await _deliver(type: 'STICKER', content: sticker);
  }

  Future<void> _revoke(ChatMessage message) async {
    try {
      await MessagingApi.revoke(message.id);
      _patch(message.id,
          (item) => item.copyWith(clearContent: true, revokedAt: DateTime.now()));
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _toggleReaction(ChatMessage message, String emoji) async {
    final active = message.reactions
        .any((item) => item.emoji == emoji && item.userId == _me);
    final me = _me;
    if (me == null) return;
    _patch(message.id, (item) {
      final others = item.reactions
          .where((r) => !(r.userId == me && r.emoji == emoji))
          .toList();
      if (!active) others.add(MessageReaction(userId: me, emoji: emoji));
      return item.copyWith(reactions: others);
    });
    try {
      if (active) {
        await MessagingApi.unreact(message.id, emoji);
      } else {
        await MessagingApi.react(message.id, emoji);
      }
    } catch (e) {
      _showError(e);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error.toString())));
  }

  // ─── Actions sheet ───

  void _openMessageActions(ChatMessage message) {
    if (message.revoked || message.pending) return;
    final mine = message.senderId == _me;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final emoji in kQuickReactions)
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        unawaited(_toggleReaction(message, emoji));
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(emoji, style: const TextStyle(fontSize: 26)),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.reply_outlined),
              title: const Text('Trả lời'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                setState(() {
                  _editing = null;
                  _replyTo = message;
                });
              },
            ),
            if (message.content != null && !message.encrypted)
              ListTile(
                leading: const Icon(Icons.copy_outlined),
                title: const Text('Sao chép'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  unawaited(
                      Clipboard.setData(ClipboardData(text: message.content!)));
                },
              ),
            if (mine && message.type == 'TEXT' && !message.encrypted)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Chỉnh sửa'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  setState(() {
                    _replyTo = null;
                    _editing = message;
                    _input.text = message.content ?? '';
                  });
                },
              ),
            if (mine)
              ListTile(
                leading: const Icon(Icons.undo_outlined, color: AppColors.error),
                title:
                    const Text('Thu hồi', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  unawaited(_revoke(message));
                },
              ),
          ],
        ),
      ),
    );
  }

  // ─── UI ───

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = widget.conversation.displayName(_me);
    final other = widget.conversation.otherMember(_me);
    final online =
        !widget.conversation.isGroup && _realtime.isOnline(other?.userId ?? '');
    final typingLabel =
        _typingUsers.values.where((value) => value.isNotEmpty).join(', ');

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            ChatAvatar(
                name: name, avatarUrl: other?.avatarUrl, size: 38, online: online),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  Text(
                    typingLabel.isNotEmpty
                        ? '$typingLabel đang nhập…'
                        : widget.conversation.isGroup
                            ? '${widget.conversation.members.length} thành viên'
                            : online
                                ? 'Đang hoạt động'
                                : 'Ngoại tuyến',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: typingLabel.isNotEmpty
                          ? AppColors.primaryBrown
                          : theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification.metrics.pixels <= 60 &&
                          notification is ScrollUpdateNotification) {
                        unawaited(_load(older: true));
                      }
                      return false;
                    },
                    child: ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      itemCount: _messages.length + (_loadingOlder ? 1 : 0),
                      itemBuilder: (context, rawIndex) {
                        if (_loadingOlder && rawIndex == 0) {
                          return const Padding(
                            padding: EdgeInsets.all(10),
                            child: Center(
                                child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))),
                          );
                        }
                        final index = _loadingOlder ? rawIndex - 1 : rawIndex;
                        final message = _messages[index];
                        final previous = index > 0 ? _messages[index - 1] : null;
                        final showDate = previous == null ||
                            !_sameDay(previous.createdAt, message.createdAt);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (showDate) _DateChip(date: message.createdAt),
                            _MessageBubble(
                              message: message,
                              mine: message.senderId == _me,
                              me: _me,
                              showSender: widget.conversation.isGroup &&
                                  message.senderId != _me &&
                                  previous?.senderId != message.senderId,
                              onLongPress: () => _openMessageActions(message),
                              onReactionTap: (emoji) =>
                                  unawaited(_toggleReaction(message, emoji)),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
          ),
          _Composer(
            controller: _input,
            replyTo: _replyTo,
            editing: _editing,
            stickersOpen: _stickersOpen,
            onChanged: (_) => _notifyTyping(),
            onSend: () => unawaited(_send()),
            onToggleStickers: () =>
                setState(() => _stickersOpen = !_stickersOpen),
            onCancelReply: () => setState(() => _replyTo = null),
            onCancelEdit: () => setState(() {
              _editing = null;
              _input.clear();
            }),
            onSticker: (sticker) => unawaited(_sendSticker(sticker)),
          ),
        ],
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DateChip extends StatelessWidget {
  final DateTime date;

  const _DateChip({required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final label = _ChatScreenState._sameDay(date, now)
        ? 'Hôm nay'
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(label,
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool mine;
  final String? me;
  final bool showSender;
  final VoidCallback onLongPress;
  final void Function(String emoji) onReactionTap;

  const _MessageBubble({
    required this.message,
    required this.mine,
    required this.me,
    required this.showSender,
    required this.onLongPress,
    required this.onReactionTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time =
        '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}';
    final isSticker = message.type == 'STICKER' && !message.revoked;

    Widget body;
    if (message.revoked) {
      body = Text('Tin nhắn đã được thu hồi',
          style: GoogleFonts.inter(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: (mine ? Colors.white : theme.colorScheme.onSurface)
                  .withValues(alpha: 0.6)));
    } else if (isSticker) {
      body = Text(message.content ?? '🙂', style: const TextStyle(fontSize: 48));
    } else if (message.encrypted && message.content == null) {
      body = Text('🔒 Tin nhắn được mã hoá',
          style: GoogleFonts.inter(fontSize: 13, fontStyle: FontStyle.italic));
    } else if (message.attachment != null) {
      body = _AttachmentBody(message: message, mine: mine);
    } else {
      body = Text(message.content ?? '',
          style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.45,
              color: mine ? Colors.white : theme.colorScheme.onSurface));
    }

    final bubble = isSticker
        ? Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: body)
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              color: mine
                  ? AppColors.primaryBrown
                  : theme.colorScheme.onSurface.withValues(alpha: 0.07),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(mine ? 18 : 5),
                bottomRight: Radius.circular(mine ? 5 : 18),
              ),
            ),
            child: body,
          );

    final emojiCounts = <String, int>{};
    for (final reaction in message.reactions) {
      emojiCounts[reaction.emoji] = (emojiCounts[reaction.emoji] ?? 0) + 1;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment:
            mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showSender)
            Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 2),
              child: Text(message.senderUsername,
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.55))),
            ),
          if (message.replyTo != null)
            Container(
              margin: const EdgeInsets.only(bottom: 3),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              constraints: const BoxConstraints(maxWidth: 260),
              decoration: BoxDecoration(
                color: AppColors.primaryBrown.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: const Border(
                    left: BorderSide(color: AppColors.primaryBrown, width: 2)),
              ),
              child: Text(
                message.replyTo!.revoked
                    ? 'Tin nhắn đã được thu hồi'
                    : message.replyTo!.content ?? 'Tệp đính kèm',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
            ),
          GestureDetector(
            onLongPress: onLongPress,
            child: Opacity(
              opacity: message.pending ? 0.55 : 1,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.76),
                child: bubble,
              ),
            ),
          ),
          if (emojiCounts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Wrap(
                spacing: 4,
                children: [
                  for (final entry in emojiCounts.entries)
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => onReactionTap(entry.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.onSurface.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('${entry.key} ${entry.value}',
                            style: const TextStyle(fontSize: 11)),
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              message.pending
                  ? '…'
                  : message.editedAt != null && !message.revoked
                      ? '$time · đã chỉnh sửa'
                      : time,
              style: GoogleFonts.inter(
                  fontSize: 9,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ảnh/tệp đính kèm — ảnh bấm mở PhotoView toàn màn hình.
class _AttachmentBody extends StatefulWidget {
  final ChatMessage message;
  final bool mine;

  const _AttachmentBody({required this.message, required this.mine});

  @override
  State<_AttachmentBody> createState() => _AttachmentBodyState();
}

class _AttachmentBodyState extends State<_AttachmentBody> {
  String? _url;

  ChatAttachment get _attachment => widget.message.attachment!;

  @override
  void initState() {
    super.initState();
    if (_attachment.isImage) {
      unawaited(
          MessagingApi.attachmentDownloadUrl(_attachment.id).then((url) {
        if (mounted && url.isNotEmpty) setState(() => _url = url);
      }).catchError((Object _) {}));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor =
        widget.mine ? Colors.white : theme.colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_url != null)
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                backgroundColor: Colors.black,
                appBar: AppBar(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    title: Text(_attachment.name,
                        style: const TextStyle(fontSize: 14))),
                body: PhotoView(imageProvider: NetworkImage(_url!)),
              ),
            )),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: _url!,
                width: 220,
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.attach_file, size: 14, color: textColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(_attachment.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 11, color: textColor)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final ChatMessage? replyTo;
  final ChatMessage? editing;
  final bool stickersOpen;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;
  final VoidCallback onToggleStickers;
  final VoidCallback onCancelReply;
  final VoidCallback onCancelEdit;
  final ValueChanged<String> onSticker;

  const _Composer({
    required this.controller,
    required this.replyTo,
    required this.editing,
    required this.stickersOpen,
    required this.onChanged,
    required this.onSend,
    required this.onToggleStickers,
    required this.onCancelReply,
    required this.onCancelEdit,
    required this.onSticker,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (editing != null)
            _Banner(
              color: Colors.amber,
              title: 'Đang chỉnh sửa tin nhắn',
              subtitle: editing!.content ?? '',
              onClose: onCancelEdit,
            )
          else if (replyTo != null)
            _Banner(
              color: AppColors.primaryBrown,
              title: 'Trả lời ${replyTo!.senderUsername}',
              subtitle: replyTo!.content ?? 'Tệp đính kèm',
              onClose: onCancelReply,
            ),
          if (stickersOpen) _StickerPicker(onSticker: onSticker),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: onToggleStickers,
                  icon: Icon(
                    Icons.emoji_emotions_outlined,
                    color: stickersOpen
                        ? AppColors.primaryBrown
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: 'Viết tin nhắn…',
                      isDense: true,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: AppColors.primaryBrown,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onSend,
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.send_rounded,
                          size: 20, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onClose;

  const _Banner({
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: color, width: 2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color)),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6))),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onClose,
            icon: const Icon(Icons.close, size: 16),
          ),
        ],
      ),
    );
  }
}

class _StickerPicker extends StatefulWidget {
  final ValueChanged<String> onSticker;

  const _StickerPicker({required this.onSticker});

  @override
  State<_StickerPicker> createState() => _StickerPickerState();
}

class _StickerPickerState extends State<_StickerPicker> {
  int _groupIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final group = kStickerGroups[_groupIndex];
    return Container(
      height: 210,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (var index = 0; index < kStickerGroups.length; index += 1)
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setState(() => _groupIndex = index),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: index == _groupIndex
                          ? AppColors.primaryBrown.withValues(alpha: 0.18)
                          : null,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(kStickerGroups[index].label,
                        style: const TextStyle(fontSize: 18)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: GridView.count(
              crossAxisCount: 6,
              children: [
                for (final sticker in group.stickers)
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => widget.onSticker(sticker),
                    child: Center(
                        child:
                            Text(sticker, style: const TextStyle(fontSize: 26))),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
