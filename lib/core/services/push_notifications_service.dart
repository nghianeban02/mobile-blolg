import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/core/auth/token_store.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/be_blog_http.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Channel thông báo chung — khớp be-blog.
const String kNookPushChannelId = 'nook_default';
const String kNookPushChannelName = 'Nook';
const String kNookPushChannelDescription =
    'Tin nhắn và hoạt động — hiện khi app tắt hoặc màn hình khóa';

/// Channel cuộc gọi — Importance.max + full-screen khi máy khóa / app tắt.
const String kNookCallChannelId = 'nook_calls';
const String kNookCallChannelName = 'Cuộc gọi';
const String kNookCallChannelDescription =
    'Cuộc gọi thoại và video đến khi app đóng hoặc màn hình khóa';

const String _actionAnswer = 'answer';
const String _actionDecline = 'decline';

/// Entry-point isolate khi app đang tắt / nền.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await PushNotificationsService.instance.ensureLocalReady();
  final kind = message.data['kind'];
  // Cuộc gọi: BE gửi data-only trên Android → luôn hiện full-screen local.
  // Các loại khác: chỉ hiện khi không có notification payload hệ thống.
  if (kind == 'chat.call' || message.notification == null) {
    await PushNotificationsService.instance.showRemoteMessage(message);
  }
}

/// Xử lý nút Nhận / Từ chối khi app đang tắt (background isolate).
@pragma('vm:entry-point')
void onNotificationActionBackground(NotificationResponse response) {
  unawaited(PushNotificationsService.handleNotificationResponse(response));
}

/// Đăng ký FCM + hiện thông báo cuộc gọi/tin nhắn khi app tắt / khóa máy.
class PushNotificationsService {
  PushNotificationsService._();

  static final PushNotificationsService instance = PushNotificationsService._();

  static const String _lastTokenPrefsKey = 'push_device_token';

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _localReady = false;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;

  /// Deep link chờ mở sau khi user bấm "Nhận" (app có thể chưa mount router).
  static String? pendingLaunchLink;

  bool get isAvailable => _initialized;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await ensureLocalReady();
      _initialized = true;
    } catch (e) {
      debugPrint('Push notifications disabled (Firebase not configured): $e');
      return;
    }

    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription =
        FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      unawaited(_registerToken(token));
    });

    await _foregroundSubscription?.cancel();
    _foregroundSubscription =
        FirebaseMessaging.onMessage.listen((message) {
      unawaited(showRemoteMessage(message));
    });

    // User mở app từ notification (hệ thống / local).
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      _storeLaunchLink(Map<String, String>.from(initial.data));
    }
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _storeLaunchLink(Map<String, String>.from(message.data));
    });

    await syncRegistration();
  }

  Future<void> ensureLocalReady() async {
    if (_localReady || kIsWeb) return;
    await _setupLocalNotifications();
    _localReady = true;
  }

  Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        unawaited(handleNotificationResponse(response));
      },
      onDidReceiveBackgroundNotificationResponse: onNotificationActionBackground,
    );

    if (Platform.isAndroid) {
      final android = _local.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          kNookPushChannelId,
          kNookPushChannelName,
          description: kNookPushChannelDescription,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        ),
      );
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          kNookCallChannelId,
          kNookCallChannelName,
          description: kNookCallChannelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        ),
      );
    }
  }

  Future<void> syncRegistration() async {
    if (!_initialized) return;
    try {
      final auth = await TokenStore.instance.read();
      if (auth == null || auth.isEmpty) return;

      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: false,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;
      await _registerToken(token);
    } catch (e) {
      debugPrint('Push registration failed: $e');
    }
  }

  Future<void> unregister() async {
    if (!_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_lastTokenPrefsKey) ??
          await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        final encoded = Uri.encodeQueryComponent(token);
        await BeBlogHttp.delete(
          '${ApiConstants.notificationDevices}?token=$encoded',
        );
      }
      await prefs.remove(_lastTokenPrefsKey);
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('Push token unregister failed: $e');
    }
  }

  /// Hiện notification — cuộc gọi dùng full-screen + nút Nhận/Từ chối.
  Future<void> showRemoteMessage(RemoteMessage message) async {
    await ensureLocalReady();
    final notification = message.notification;
    final data = Map<String, String>.from(message.data);
    final title = notification?.title ?? data['title'] ?? 'Nook';
    final body = notification?.body ?? data['body'] ?? data['message'] ?? '';
    if (body.trim().isEmpty && notification == null && data['kind'] != 'chat.call') {
      return;
    }

    final kind = data['kind'];
    final isIncomingCall = kind == 'chat.call';
    final isVideo = data['mode'] == 'VIDEO';
    final notificationId = _notificationIdFor(data, message.messageId);

    if (isIncomingCall) {
      await _showIncomingCall(
        id: notificationId,
        title: title.isNotEmpty
            ? title
            : (isVideo ? '📹 Cuộc gọi video' : '📞 Cuộc gọi thoại'),
        body: body.isNotEmpty ? body : 'Đang gọi cho bạn',
        data: data,
        isVideo: isVideo,
      );
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      kNookPushChannelId,
      kNookPushChannelName,
      channelDescription: kNookPushChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      visibility: NotificationVisibility.public,
      category: _androidCategory(kind),
      playSound: true,
      enableVibration: true,
      tag: kind?.startsWith('chat.call') == true
          ? 'call-${data['callId'] ?? data['conversationId'] ?? 'x'}'
          : null,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _local.show(
      notificationId,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: _encodePayload(data),
    );
  }

  Future<void> _showIncomingCall({
    required int id,
    required String title,
    required String body,
    required Map<String, String> data,
    required bool isVideo,
  }) async {
    final callTag = 'call-${data['callId'] ?? data['conversationId'] ?? id}';
    final androidDetails = AndroidNotificationDetails(
      kNookCallChannelId,
      kNookCallChannelName,
      channelDescription: kNookCallChannelDescription,
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.call,
      visibility: NotificationVisibility.public,
      fullScreenIntent: true,
      ongoing: true,
      autoCancel: false,
      timeoutAfter: 60 * 1000,
      playSound: true,
      enableVibration: true,
      tag: callTag,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          _actionAnswer,
          isVideo ? 'Nhận video' : 'Nhận',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          _actionDecline,
          'Từ chối',
          cancelNotification: true,
          showsUserInterface: false,
        ),
      ],
    );
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
      categoryIdentifier: 'incoming_call',
    );

    await _local.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: _encodePayload(data),
    );
  }

  static Future<void> handleNotificationResponse(
    NotificationResponse response,
  ) async {
    final data = _decodePayload(response.payload);
    final action = response.actionId;

    if (action == _actionDecline || response.actionId == _actionDecline) {
      final rejectUrl = data['rejectUrl'];
      if (rejectUrl != null && rejectUrl.isNotEmpty) {
        try {
          await http.post(Uri.parse(rejectUrl)).timeout(const Duration(seconds: 5));
        } catch (e) {
          debugPrint('Call decline from notification failed: $e');
        }
      }
      // Đóng notification cuộc gọi nếu còn treo.
      final callId = data['callId'];
      if (callId != null) {
        await instance._local.cancel(callId.hashCode & 0x7fffffff);
      }
      return;
    }

    // Nhận / tap body → mở deep link (answerLink nếu bấm Nhận).
    if (action == _actionAnswer) {
      final answer = data['answerLink'] ?? data['link'];
      if (answer != null && answer.isNotEmpty) {
        pendingLaunchLink = answer.contains('answer=')
            ? answer
            : '$answer${answer.contains('?') ? '&' : '?'}answer=1';
      }
      return;
    }

    final link = data['link'] ?? data['answerLink'];
    if (link != null && link.isNotEmpty) {
      pendingLaunchLink = link;
    }
  }

  void _storeLaunchLink(Map<String, String> data) {
    final kind = data['kind'];
    if (kind == 'chat.call') {
      pendingLaunchLink = data['answerLink'] ?? data['link'];
    } else {
      pendingLaunchLink = data['link'];
    }
  }

  static String _encodePayload(Map<String, String> data) {
    // Compact query-style payload for notification actions across isolates.
    return Uri(queryParameters: data).query;
  }

  static Map<String, String> _decodePayload(String? payload) {
    if (payload == null || payload.isEmpty) return {};
    try {
      return Map<String, String>.from(Uri.splitQueryString(payload));
    } catch (_) {
      return {};
    }
  }

  static int _notificationIdFor(Map<String, String> data, String? messageId) {
    final callId = data['callId'];
    if (callId != null && callId.isNotEmpty) {
      return callId.hashCode & 0x7fffffff;
    }
    return messageId?.hashCode ??
        DateTime.now().millisecondsSinceEpoch.remainder(100000);
  }

  AndroidNotificationCategory? _androidCategory(String? kind) {
    if (kind == null) return null;
    if (kind.startsWith('chat.call')) {
      return AndroidNotificationCategory.call;
    }
    if (kind == 'chat.message') {
      return AndroidNotificationCategory.message;
    }
    return AndroidNotificationCategory.social;
  }

  Future<void> _registerToken(String token) async {
    try {
      final auth = await TokenStore.instance.read();
      if (auth == null || auth.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final platform = Platform.isIOS ? 'IOS' : 'ANDROID';
      final response = await BeBlogHttp.postJson(
        ApiConstants.notificationDevices,
        body: {'token': token, 'platform': platform},
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await prefs.setString(_lastTokenPrefsKey, token);
      }
    } catch (e) {
      debugPrint('Push token register failed: $e');
    }
  }
}
