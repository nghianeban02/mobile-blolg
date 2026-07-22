import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Âm thanh tin nhắn / cuộc gọi — parity `web-blog/lib/messaging/chat-sounds.ts`.
class ChatSoundPreferences extends ChangeNotifier {
  ChatSoundPreferences._();

  static final ChatSoundPreferences instance = ChatSoundPreferences._();

  static const _prefKey = 'nook_chat_sounds';

  bool messages = true;
  bool calls = true;
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        messages = map['messages'] != false;
        calls = map['calls'] != false;
      } catch (_) {
        messages = true;
        calls = true;
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<ChatSoundPreferences> set({bool? messages, bool? calls}) async {
    await load();
    if (messages != null) this.messages = messages;
    if (calls != null) this.calls = calls;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefKey,
      jsonEncode({'messages': this.messages, 'calls': this.calls}),
    );
    notifyListeners();
    return this;
  }
}

class ChatSounds {
  ChatSounds._();

  static int _lastMessageSoundAt = 0;

  static Future<void> playMessageSound() async {
    final prefs = ChatSoundPreferences.instance;
    await prefs.load();
    if (!prefs.messages) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastMessageSoundAt < 450) return;
    _lastMessageSoundAt = now;
    await SystemSound.play(SystemSoundType.click);
    await HapticFeedback.lightImpact();
  }
}

/// Ringtone cuộc gọi đến — lặp đến khi [stop].
class CallRingtone {
  Timer? _timer;
  String _mode = 'AUDIO';

  Future<void> start({String mode = 'AUDIO'}) async {
    final prefs = ChatSoundPreferences.instance;
    await prefs.load();
    if (!prefs.calls) return;
    _mode = mode;
    if (_timer != null) return;
    await _ringOnce();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _ringOnce());
  }

  Future<void> _ringOnce() async {
    await SystemSound.play(SystemSoundType.alert);
    await HapticFeedback.mediumImpact();
    if (_mode == 'VIDEO') {
      await Future<void>.delayed(const Duration(milliseconds: 180));
      await SystemSound.play(SystemSoundType.alert);
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Ringback khi đang gọi đi.
class OutgoingRingback {
  Timer? _timer;

  Future<void> start() async {
    final prefs = ChatSoundPreferences.instance;
    await prefs.load();
    if (!prefs.calls) return;
    if (_timer != null) return;
    await _beep();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _beep());
  }

  Future<void> _beep() async {
    await SystemSound.play(SystemSoundType.click);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    await SystemSound.play(SystemSoundType.click);
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
