import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:mobile/data/messaging/chat_models.dart';
import 'package:mobile/data/messaging/messaging_api.dart';

/// Kết nối realtime tới messaging-service — mirror hành vi của
/// `web-blog/lib/messaging/messaging-context.tsx`:
/// ws-ticket → WebSocket, heartbeat ping 25s, reconnect exponential backoff,
/// presence + unread badge, broadcast sự kiện cho các màn hình đang mở.
class ChatRealtimeService extends ChangeNotifier {
  ChatRealtimeService._();

  static final ChatRealtimeService instance = ChatRealtimeService._();

  final StreamController<ChatRealtimeEvent> _events =
      StreamController<ChatRealtimeEvent>.broadcast();

  WebSocket? _socket;
  Timer? _heartbeat;
  Timer? _reconnect;
  int _attempt = 0;
  bool _running = false;
  bool _connected = false;
  int _unreadCount = 0;
  final Set<String> _onlineUsers = <String>{};
  final Set<String> _seenEventIds = <String>{};

  Stream<ChatRealtimeEvent> get events => _events.stream;
  bool get connected => _connected;
  int get unreadCount => _unreadCount;
  bool isOnline(String userId) => _onlineUsers.contains(userId);

  /// Bắt đầu (idempotent) — gọi sau đăng nhập hoặc khi mở màn hình chat.
  Future<void> start() async {
    if (_running) return;
    _running = true;
    await _connect();
    unawaited(refreshUnread());
  }

  /// Ngắt kết nối — gọi khi logout.
  Future<void> stop() async {
    _running = false;
    _reconnect?.cancel();
    _heartbeat?.cancel();
    _connected = false;
    _onlineUsers.clear();
    _unreadCount = 0;
    await _socket?.close(1000, 'client stop');
    _socket = null;
    notifyListeners();
  }

  Future<void> refreshUnread() async {
    try {
      final count = await MessagingApi.unreadCount();
      if (count != _unreadCount) {
        _unreadCount = count;
        notifyListeners();
      }
    } catch (_) {
      // Badge là tính năng phụ — không làm phiền người dùng khi service bận.
    }
  }

  /// Gửi frame realtime (typing…) — trả false khi socket chưa sẵn sàng.
  bool send(Map<String, dynamic> message) {
    final socket = _socket;
    if (socket == null || socket.readyState != WebSocket.open) return false;
    try {
      socket.add(jsonEncode(message));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _connect() async {
    if (!_running) return;
    try {
      final ticket = await MessagingApi.wsTicket();
      if (!_running || ticket.isEmpty) {
        if (_running) _scheduleReconnect();
        return;
      }
      // Đóng qua _socket trong stop()/_handleClosed — lint không nhìn thấy.
      // ignore: close_sinks
      final socket = await WebSocket.connect(
        '${MessagingApi.wsBaseUrl}/ws?ticket=$ticket',
      ).timeout(const Duration(seconds: 12));
      _socket = socket;
      socket.listen(
        (dynamic raw) => _handleFrame(raw is String ? raw : ''),
        onDone: _handleClosed,
        onError: (Object _) => _handleClosed(),
        cancelOnError: true,
      );
      _heartbeat?.cancel();
      _heartbeat = Timer.periodic(const Duration(seconds: 25), (_) {
        send({'type': 'ping'});
      });
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _handleFrame(String raw) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return;
    }
    if (decoded is! Map<String, dynamic>) return;
    final event = ChatRealtimeEvent.fromJson(decoded);

    if (event.type == 'connection.ready') {
      _attempt = 0;
      _connected = true;
      notifyListeners();
      unawaited(refreshUnread());
      return;
    }

    // Dedupe theo id outbox (sự kiện có thể lặp khi service retry).
    final id = decoded['id'];
    if (id != null) {
      final key = '$id';
      if (_seenEventIds.contains(key)) return;
      _seenEventIds.add(key);
      if (_seenEventIds.length > 1000) {
        _seenEventIds.remove(_seenEventIds.first);
      }
    }

    if (event.type == 'presence.changed') {
      final userId = event.payload['userId'];
      if (userId is String) {
        final changed = event.payload['online'] == true
            ? _onlineUsers.add(userId)
            : _onlineUsers.remove(userId);
        if (changed) notifyListeners();
      }
    }

    _events.add(event);

    if (event.type.startsWith('message.') ||
        event.type.startsWith('conversation.')) {
      unawaited(refreshUnread());
    }
  }

  void _handleClosed() {
    _heartbeat?.cancel();
    _socket = null;
    if (_connected) {
      _connected = false;
      notifyListeners();
    }
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (!_running) return;
    _reconnect?.cancel();
    final delayMs = min(30000, 750 * pow(2, _attempt).toInt()) +
        Random().nextInt(500);
    _attempt += 1;
    _reconnect = Timer(Duration(milliseconds: delayMs), _connect);
  }
}
