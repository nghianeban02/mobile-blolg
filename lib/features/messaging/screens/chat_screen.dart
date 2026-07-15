import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/services/messaging_realtime_service.dart';
import 'package:mobile/core/utils/format_datetime.dart';
import 'package:mobile/data/models/messaging_dtos.dart';
import 'package:mobile/data/repositories/messaging_repository.dart';

/// Quick reactions giống bản web (`QUICK_REACTIONS` trong messenger).
const List<String> kChatQuickReactions = ['❤️', '👍', '😂', '😮', '😢', '🙏'];

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String title;
  final String? currentUserId;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.title,
    this.currentUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _repository = MessagingRepository();
  final _realtime = MessagingRealtimeService.instance;
  final _composer = TextEditingController();
  final _scroll = ScrollController();
  final _picker = ImagePicker();
  StreamSubscription<MessagingRealtimeEvent>? _events;
  Timer? _fallbackPoller;
  Timer? _typingStopTimer;
  Timer? _typingClearTimer;
  List<ChatMessageDto> _messages = const [];
  bool _loading = true;
  bool _sending = false;
  bool _sentTypingStart = false;
  String? _error;
  String? _typingUser;

  @override
  void initState() {
    super.initState();
    _realtime.acquire();
    _events = _realtime.events.listen(_onRealtimeEvent);
    _load();
    // Polling chỉ là dự phòng khi WebSocket mất kết nối.
    _fallbackPoller = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!_realtime.connected.value) _load(silent: true);
    });
  }

  @override
  void dispose() {
    _stopTyping();
    _events?.cancel();
    _realtime.release();
    _fallbackPoller?.cancel();
    _typingStopTimer?.cancel();
    _typingClearTimer?.cancel();
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onRealtimeEvent(MessagingRealtimeEvent event) {
    final conversationId = event.payload['conversationId']?.toString();
    if (conversationId != null && conversationId != widget.conversationId) {
      return;
    }
    switch (event.type) {
      case 'message.created':
      case 'message.revoked':
      case 'message.reaction':
      case 'conversation.read':
        _load(silent: true);
      case 'typing.start':
        final userId = event.payload['userId']?.toString();
        final username = event.payload['username']?.toString();
        if (userId != null && userId != widget.currentUserId) {
          setState(() => _typingUser = username ?? 'Ai đó');
          _typingClearTimer?.cancel();
          _typingClearTimer = Timer(
            const Duration(seconds: 6),
            () => mounted ? setState(() => _typingUser = null) : null,
          );
        }
      case 'typing.stop':
        final userId = event.payload['userId']?.toString();
        if (userId != null && userId != widget.currentUserId) {
          _typingClearTimer?.cancel();
          setState(() => _typingUser = null);
        }
    }
  }

  void _onComposerChanged(String value) {
    if (value.trim().isEmpty) {
      _stopTyping();
      return;
    }
    if (!_sentTypingStart) {
      _sentTypingStart = _realtime.send({
        'type': 'typing.start',
        'conversationId': widget.conversationId,
      });
    }
    _typingStopTimer?.cancel();
    _typingStopTimer = Timer(const Duration(seconds: 4), _stopTyping);
  }

  void _stopTyping() {
    _typingStopTimer?.cancel();
    if (_sentTypingStart) {
      _realtime.send({
        'type': 'typing.stop',
        'conversationId': widget.conversationId,
      });
      _sentTypingStart = false;
    }
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    final result = await _repository.getMessages(widget.conversationId);
    if (!mounted) return;
    if (!result.success) {
      if (!silent) {
        setState(() {
          _loading = false;
          _error = result.message ?? 'Không tải được tin nhắn.';
        });
      }
      return;
    }
    final messages = [...?result.data]
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    final shouldScroll = messages.length != _messages.length;
    setState(() {
      _loading = false;
      _error = null;
      _messages = messages;
    });
    if (messages.isNotEmpty) {
      _repository.markRead(widget.conversationId, messages.last.sequence);
    }
    if (shouldScroll) _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _composer.text.trim();
    if (text.isEmpty || _sending) return;
    _stopTyping();
    setState(() => _sending = true);
    final result = await _repository.sendMessage(widget.conversationId, text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (result.success) {
      _composer.clear();
      _load(silent: true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Không gửi được tin nhắn.')),
      );
    }
  }

  Future<void> _sendImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 2048,
    );
    if (picked == null || !mounted) return;
    setState(() => _sending = true);
    final upload = await _repository.uploadImage(
      widget.conversationId,
      File(picked.path),
    );
    if (!mounted) return;
    if (!upload.success || upload.data == null) {
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(upload.message ?? 'Không tải được ảnh.')),
      );
      return;
    }
    final sent = await _repository.sendMessage(
      widget.conversationId,
      '',
      type: 'IMAGE',
      attachmentId: upload.data,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (sent.success) _load(silent: true);
  }

  bool _hasMyReaction(ChatMessageDto message, String emoji) =>
      message.reactions.any(
        (item) => item.emoji == emoji && item.userId == widget.currentUserId,
      );

  Future<void> _react(ChatMessageDto message, String emoji) async {
    if (_hasMyReaction(message, emoji)) {
      await _repository.unreact(message.id, emoji);
    } else {
      await _repository.react(message.id, emoji);
    }
    _load(silent: true);
  }

  Future<void> _messageActions(ChatMessageDto message) async {
    if (message.revokedAt != null) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: kChatQuickReactions
                    .map(
                      (emoji) => InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => Navigator.pop(context, emoji),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: _hasMyReaction(message, emoji)
                              ? BoxDecoration(
                                  color: AppColors.primaryBrown.withValues(
                                    alpha: 0.15,
                                  ),
                                  shape: BoxShape.circle,
                                )
                              : null,
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 26),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            if (message.senderId == widget.currentUserId)
              ListTile(
                leading: const Icon(Icons.undo),
                title: const Text('Thu hồi tin nhắn'),
                onTap: () => Navigator.pop(context, 'revoke'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    if (action == 'revoke') {
      await _repository.revokeMessage(message.id);
      _load(silent: true);
    } else if (kChatQuickReactions.contains(action)) {
      await _react(message, action);
    }
  }

  Future<void> _openAttachment(ChatAttachmentDto attachment) async {
    final result = await _repository.attachmentDownloadUrl(attachment.id);
    if (!mounted || !result.success || result.data == null) return;
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: Image.network(
                    result.data!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Text(
                      'Không mở được tệp.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _searchMessages() async {
    final controller = TextEditingController();
    final query = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tìm tin nhắn'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Từ khóa'),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Tìm'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (query == null || query.trim().isEmpty || !mounted) return;
    final result = await _repository.searchMessages(
      query,
      conversationId: widget.conversationId,
    );
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Kết quả cho “$query”',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (result.data?.isEmpty ?? true)
              const ListTile(title: Text('Không tìm thấy tin nhắn.'))
            else
              ...result.data!.map(
                (message) => ListTile(
                  title: Text(message.senderUsername),
                  subtitle: Text(message.content ?? 'Tệp đính kèm'),
                  trailing: Text(formatCommentDateTime(message.createdAt)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, overflow: TextOverflow.ellipsis),
            ValueListenableBuilder<bool>(
              valueListenable: _realtime.connected,
              builder: (context, connected, _) => Text(
                _typingUser != null
                    ? '$_typingUser đang nhập…'
                    : connected
                    ? 'Đang hoạt động'
                    : 'Đang kết nối…',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: _typingUser != null
                      ? AppColors.primaryBrown
                      : theme.textTheme.bodySmall?.color?.withValues(
                          alpha: 0.7,
                        ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Tìm tin nhắn',
            onPressed: _searchMessages,
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryBrown,
                      ),
                    )
                  : _error != null
                  ? Center(child: Text(_error!))
                  : _messages.isEmpty
                  ? const Center(child: Text('Hãy gửi lời chào đầu tiên.'))
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(14),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final mine = message.senderId == widget.currentUserId;
                        return _MessageBubble(
                          message: message,
                          mine: mine,
                          onLongPress: () => _messageActions(message),
                          onAttachmentTap: message.attachment == null
                              ? null
                              : () => _openAttachment(message.attachment!),
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              color: theme.brightness == Brightness.dark
                  ? theme.colorScheme.surfaceContainerHigh
                  : Colors.white,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: 'Gửi ảnh',
                    onPressed: _sending ? null : _sendImage,
                    icon: const Icon(Icons.image_outlined),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _composer,
                      onChanged: _onComposerChanged,
                      minLines: 1,
                      maxLines: 5,
                      maxLength: 4000,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn…',
                        counterText: '',
                        isDense: true,
                        filled: true,
                        fillColor: theme.brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.06)
                            : AppColors.homeTextDark.withValues(alpha: 0.04),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(
                            color: AppColors.primaryBrown.withValues(
                              alpha: 0.45,
                            ),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
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

class _MessageBubble extends StatelessWidget {
  final ChatMessageDto message;
  final bool mine;
  final VoidCallback onLongPress;
  final VoidCallback? onAttachmentTap;

  const _MessageBubble({
    required this.message,
    required this.mine,
    required this.onLongPress,
    this.onAttachmentTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final revoked = message.revokedAt != null;
    final otherBubble = theme.brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.08)
        : AppColors.homeTextDark.withValues(alpha: 0.06);
    final otherText = theme.brightness == Brightness.dark
        ? theme.colorScheme.onSurface
        : AppColors.homeTextDark;
    final otherMuted = theme.brightness == Brightness.dark
        ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
        : AppColors.homeTextLight;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.76,
          ),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: mine ? AppColors.primaryBrown : otherBubble,
            borderRadius: BorderRadius.circular(20).copyWith(
              bottomRight: mine ? const Radius.circular(6) : null,
              bottomLeft: mine ? null : const Radius.circular(6),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!mine)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    message.senderUsername,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: AppColors.primaryBrown,
                    ),
                  ),
                ),
              if (revoked)
                Text(
                  'Tin nhắn đã được thu hồi',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: mine ? Colors.white70 : otherMuted,
                  ),
                )
              else ...[
                if (message.attachment != null)
                  InkWell(
                    onTap: onAttachmentTap,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            color: mine ? Colors.white : AppColors.primaryBrown,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              message.attachment!.name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: mine ? Colors.white : otherText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (message.content?.isNotEmpty == true)
                  Text(
                    message.content!,
                    style: TextStyle(
                      color: mine ? Colors.white : otherText,
                      height: 1.35,
                    ),
                  ),
              ],
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatCommentDateTime(message.createdAt),
                    style: TextStyle(
                      fontSize: 8,
                      color: mine ? Colors.white60 : otherMuted,
                    ),
                  ),
                  if (message.reactions.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(_reactionSummary(message.reactions)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Gộp reaction trùng emoji kèm số lượng, giống chip reaction bản web.
  String _reactionSummary(List<ChatReactionDto> reactions) {
    final counts = <String, int>{};
    for (final reaction in reactions) {
      counts[reaction.emoji] = (counts[reaction.emoji] ?? 0) + 1;
    }
    return counts.entries
        .map(
          (entry) => entry.value > 1 ? '${entry.key}${entry.value}' : entry.key,
        )
        .join(' ');
  }
}
