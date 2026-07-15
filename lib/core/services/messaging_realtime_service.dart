import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:mobile/core/constants/messaging_constants.dart';
import 'package:mobile/data/repositories/messaging_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Sự kiện realtime từ messaging-service (mirror `RealtimeEvent` của web).
class MessagingRealtimeEvent {
  final String type;
  final Map<String, dynamic> payload;
  final String? id;

  const MessagingRealtimeEvent({
    required this.type,
    this.payload = const {},
    this.id,
  });

  factory MessagingRealtimeEvent.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'];
    return MessagingRealtimeEvent(
      type: json['type']?.toString() ?? '',
      payload: payload is Map
          ? Map<String, dynamic>.from(payload)
          : const <String, dynamic>{},
      id: json['id']?.toString(),
    );
  }
}

/// Kết nối WebSocket tới messaging-service, giống `MessagingProvider` bản web:
/// - Lấy ticket qua `POST /api/chat/ws-ticket`, nối `/ws?ticket=…&deviceId=…`.
/// - Heartbeat `ping` mỗi 25s; reconnect backoff lũy tiến (tối đa 30s).
/// - Phát sự kiện qua [events]; theo dõi presence qua [onlineUsers].
///
/// Singleton: nhiều màn hình (Messages, Chat) dùng chung một kết nối.
class MessagingRealtimeService {
  MessagingRealtimeService._();

  static final MessagingRealtimeService instance = MessagingRealtimeService._();

  static const _deviceIdPrefsKey = 'nook_chat_device_id';
  static const _heartbeatInterval = Duration(seconds: 25);

  final MessagingRepository _repository = MessagingRepository();
  final ValueNotifier<bool> connected = ValueNotifier(false);
  final ValueNotifier<Set<String>> onlineUsers = ValueNotifier(const {});

  final _eventsController =
      StreamController<MessagingRealtimeEvent>.broadcast();
  final _seenEventIds = <String>{};

  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _attempt = 0;
  int _listeners = 0;
  bool _connecting = false;
  String? _deviceId;

  Stream<MessagingRealtimeEvent> get events => _eventsController.stream;

  String? get deviceId => _deviceId;

  /// Mỗi màn hình gọi [acquire] khi mở và [release] khi đóng.
  /// Kết nối chỉ đóng khi không còn màn hình nào dùng.
  void acquire() {
    _listeners += 1;
    if (_listeners == 1) _connect();
  }

  void release() {
    _listeners = max(0, _listeners - 1);
    if (_listeners == 0) _disconnect();
  }

  /// Gửi frame realtime (typing.start/stop…). Trả về false nếu chưa kết nối.
  bool send(Map<String, dynamic> message) {
    final channel = _channel;
    if (channel == null || !connected.value) return false;
    channel.sink.add(jsonEncode(message));
    return true;
  }

  Future<String> _ensureDeviceId() async {
    if (_deviceId != null) return _deviceId!;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_deviceIdPrefsKey);
    if (id == null || id.isEmpty) {
      id = _randomId();
      await prefs.setString(_deviceIdPrefsKey, id);
    }
    _deviceId = id;
    return id;
  }

  String _randomId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  String get _wsBaseUrl {
    final base = MessagingConstants.baseUrl;
    if (base.startsWith('https://')) {
      return base.replaceFirst('https://', 'wss://');
    }
    return base.replaceFirst('http://', 'ws://');
  }

  Future<void> _connect() async {
    if (_connecting || !MessagingConstants.enabled) return;
    _connecting = true;
    try {
      final ticket = await _repository.wsTicket();
      if (_listeners == 0) return;
      if (!ticket.success || ticket.data == null) {
        _scheduleReconnect();
        return;
      }
      final deviceId = await _ensureDeviceId();
      final uri = Uri.parse('$_wsBaseUrl/ws').replace(
        queryParameters: {'ticket': ticket.data!, 'deviceId': deviceId},
      );
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      _startHeartbeat(channel);
      channel.stream.listen(
        (frame) => _onFrame(frame.toString()),
        onDone: () => _onClosed(channel),
        onError: (_) => _onClosed(channel),
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect();
    } finally {
      _connecting = false;
    }
  }

  void _startHeartbeat(WebSocketChannel channel) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      if (_channel == channel && connected.value) {
        channel.sink.add(jsonEncode({'type': 'ping'}));
      }
    });
  }

  void _onFrame(String frame) {
    MessagingRealtimeEvent event;
    try {
      event = MessagingRealtimeEvent.fromJson(
        Map<String, dynamic>.from(jsonDecode(frame) as Map),
      );
    } catch (_) {
      return; // Frame hỏng: chờ frame hợp lệ tiếp theo.
    }
    if (event.type == 'connection.ready') {
      _attempt = 0;
      connected.value = true;
    }
    final id = event.id;
    if (id != null) {
      if (_seenEventIds.contains(id)) return;
      _seenEventIds.add(id);
      if (_seenEventIds.length > 1000) {
        _seenEventIds.remove(_seenEventIds.first);
      }
    }
    if (event.type == 'presence.changed') {
      final userId = event.payload['userId']?.toString();
      if (userId != null) {
        final next = Set<String>.from(onlineUsers.value);
        if (event.payload['online'] == true) {
          next.add(userId);
        } else {
          next.remove(userId);
        }
        onlineUsers.value = next;
      }
    }
    _eventsController.add(event);
  }

  void _onClosed(WebSocketChannel channel) {
    if (_channel != channel) return;
    _channel = null;
    _heartbeatTimer?.cancel();
    connected.value = false;
    if (_listeners > 0) _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_listeners == 0) return;
    _reconnectTimer?.cancel();
    final delayMs =
        min(30000, 750 * pow(2, _attempt).toInt()) + Random().nextInt(500);
    _attempt += 1;
    _reconnectTimer = Timer(Duration(milliseconds: delayMs), _connect);
  }

  void _disconnect() {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _channel?.sink.close(1000, 'No listeners');
    _channel = null;
    _attempt = 0;
    connected.value = false;
    onlineUsers.value = const {};
  }
}
