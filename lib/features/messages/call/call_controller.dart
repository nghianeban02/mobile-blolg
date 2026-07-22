import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mobile/core/messaging/chat_sounds.dart';
import 'package:mobile/core/services/chat_realtime_service.dart';
import 'package:mobile/data/messaging/chat_models.dart';
import 'package:mobile/data/messaging/messaging_api.dart';

enum CallDirection { incoming, outgoing }

enum CallUiStatus { ringing, connecting, active }

class ActiveCall {
  final String id;
  final String conversationId;
  final String name;
  final String mode; // AUDIO | VIDEO
  final CallDirection direction;
  final CallUiStatus status;
  final Map<String, dynamic>? offer;
  final DateTime? connectedAt;

  const ActiveCall({
    required this.id,
    required this.conversationId,
    required this.name,
    required this.mode,
    required this.direction,
    required this.status,
    this.offer,
    this.connectedAt,
  });

  bool get isVideo => mode == 'VIDEO';

  ActiveCall copyWith({
    CallUiStatus? status,
    Map<String, dynamic>? offer,
    DateTime? connectedAt,
    String? name,
    String? mode,
  }) => ActiveCall(
    id: id,
    conversationId: conversationId,
    name: name ?? this.name,
    mode: mode ?? this.mode,
    direction: direction,
    status: status ?? this.status,
    offer: offer ?? this.offer,
    connectedAt: connectedAt ?? this.connectedAt,
  );
}

/// WebRTC call controller — mirror `web-blog/lib/messaging/chat-call-context.tsx`.
class CallController extends ChangeNotifier {
  CallController._();

  static final CallController instance = CallController._();

  static const _ringTimeout = Duration(seconds: 45);

  final _realtime = ChatRealtimeService.instance;
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  final Map<String, List<RTCIceCandidate>> _pendingIce = {};
  final Set<String> _localDescriptionReady = {};

  StreamSubscription<ChatRealtimeEvent>? _subscription;
  RTCPeerConnection? _peer;
  MediaStream? _localStream;
  List<Map<String, dynamic>> _iceServers = const [];
  bool _turnAvailable = false;
  bool _renderersReady = false;
  String? _currentUserId;
  ActiveCall? activeCall;
  bool muted = false;
  bool cameraOff = false;
  String? lastError;
  String? _endingCallId;
  String? _signalingFailedCallId;
  Timer? _ringTimer;
  Timer? _offerRequestTimer;
  Timer? _disconnectedTimer;
  Timer? _signalPollTimer;
  String _signalCursor = '0';
  final _ringtone = CallRingtone();
  final _ringback = OutgoingRingback();
  bool _autoAnswerPending = false;

  RTCVideoRenderer get localRenderer => _localRenderer;
  RTCVideoRenderer get remoteRenderer => _remoteRenderer;
  bool get hasActiveCall => activeCall != null;

  Future<void> bind(String? userId) async {
    if (_currentUserId == userId && _subscription != null) return;
    _currentUserId = userId;
    await _ensureRenderers();
    await _subscription?.cancel();
    _subscription = null;
    _signalPollTimer?.cancel();
    if (userId == null || userId.isEmpty) {
      await endCall(notifyPeer: false);
      return;
    }
    await _realtime.start();
    _subscription = _realtime.events.listen(_onEvent);
    unawaited(_loadIceServers());
    _signalPollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      unawaited(_pollCallSignals());
    });
  }

  Future<void> _ensureRenderers() async {
    if (_renderersReady) return;
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    _renderersReady = true;
  }

  Future<void> _loadIceServers() async {
    try {
      final config = await MessagingApi.config();
      _iceServers = config.iceServers.map((s) => s.toWebRtcMap()).toList();
      _turnAvailable =
          config.turnAvailable ||
          config.iceServers.any(
            (s) => s.urls.any((u) => u.toLowerCase().startsWith('turn')),
          );
      if (_iceServers.isEmpty) {
        lastError = 'Không tải được cấu hình cuộc gọi.';
        notifyListeners();
      }
    } catch (e) {
      _iceServers = const [];
      _turnAvailable = false;
      debugPrint('[call] load ICE failed: $e');
    }
  }

  Future<void> startCall({
    required ChatConversation conversation,
    required String name,
    required String mode,
  }) async {
    if (activeCall != null) return;
    await _ensureRenderers();
    if (_iceServers.isEmpty) await _loadIceServers();
    if (_iceServers.isEmpty) {
      lastError = 'Cấu hình cuộc gọi chưa sẵn sàng.';
      notifyListeners();
      return;
    }
    if (!_turnAvailable) {
      lastError = 'TURN chưa sẵn sàng — cuộc gọi có thể thất bại ngoài LAN.';
      notifyListeners();
    }

    String? createdId;
    try {
      final created = await MessagingApi.createCall(conversation.id, mode);
      createdId = created.id;
      final call = ActiveCall(
        id: created.id,
        conversationId: conversation.id,
        name: name,
        mode: mode,
        direction: CallDirection.outgoing,
        status: CallUiStatus.connecting,
      );
      _endingCallId = null;
      _signalingFailedCallId = null;
      activeCall = call;
      notifyListeners();

      final peer = await _createPeer(call);
      final offer = await peer.createOffer();
      await peer.setLocalDescription(offer);
      if (activeCall?.id != created.id || _peer != peer) return;
      _localDescriptionReady.add(created.id);

      final sdp = (await peer.getLocalDescription())?.toMap() ?? offer.toMap();
      final sent = await _sendSignal({
        'type': 'call.offer',
        'conversationId': conversation.id,
        'callId': created.id,
        'mode': mode,
        'sdp': sdp,
      });
      if (!sent) throw Exception('Realtime chưa sẵn sàng cho cuộc gọi.');

      activeCall = call.copyWith(status: CallUiStatus.ringing);
      notifyListeners();
      unawaited(_ringback.start());
      _armOutgoingTimeout(created.id);

      // Re-send enriched SDP after ICE gathering settles.
      unawaited(
        _waitIceGathering(peer).then((_) async {
          if (activeCall?.id != created.id || _peer != peer) return;
          final local = await peer.getLocalDescription();
          if (local == null) return;
          await _sendSignal({
            'type': 'call.offer',
            'conversationId': conversation.id,
            'callId': created.id,
            'mode': mode,
            'sdp': local.toMap(),
          });
        }),
      );
    } catch (e) {
      if (createdId != null && activeCall?.id == createdId) {
        await endCall();
      } else {
        await _clearMedia();
      }
      lastError = e is MessagingApiException
          ? e.message
          : 'Không thể bắt đầu cuộc gọi. Kiểm tra micro/camera.';
      notifyListeners();
    }
  }

  Future<void> acceptCall() async {
    final call = activeCall;
    if (call == null || call.offer == null) return;
    try {
      _ringtone.stop();
      _ringback.stop();
      _ringTimer?.cancel();
      activeCall = call.copyWith(status: CallUiStatus.connecting);
      notifyListeners();

      final peer = await _createPeer(call);
      await peer.setRemoteDescription(
        RTCSessionDescription(
          call.offer!['sdp'] as String?,
          call.offer!['type'] as String?,
        ),
      );
      await _flushPendingIce(call.id);
      final answer = await peer.createAnswer();
      await peer.setLocalDescription(answer);
      if (activeCall?.id != call.id || _peer != peer) return;
      _localDescriptionReady.add(call.id);

      await MessagingApi.answerCall(call.id);
      final sdp = (await peer.getLocalDescription())?.toMap() ?? answer.toMap();
      final sent = await _sendSignal({
        'type': 'call.answer',
        'conversationId': call.conversationId,
        'callId': call.id,
        'mode': call.mode,
        'sdp': sdp,
      });
      if (!sent) throw Exception('Realtime chưa sẵn sàng.');

      unawaited(
        _waitIceGathering(peer).then((_) async {
          if (activeCall?.id != call.id || _peer != peer) return;
          final local = await peer.getLocalDescription();
          if (local == null) return;
          await _sendSignal({
            'type': 'call.answer',
            'conversationId': call.conversationId,
            'callId': call.id,
            'mode': call.mode,
            'sdp': local.toMap(),
          });
        }),
      );
    } catch (e) {
      await endCall();
      lastError = e is MessagingApiException
          ? e.message
          : 'Không thể nhận cuộc gọi.';
      notifyListeners();
    }
  }

  Future<void> rejectCall() async {
    final call = activeCall;
    if (call == null) return;
    _ringtone.stop();
    _ringback.stop();
    _autoAnswerPending = false;
    await _sendSignal({
      'type': 'call.reject',
      'conversationId': call.conversationId,
      'callId': call.id,
    });
    unawaited(MessagingApi.rejectCall(call.id).then((_) {}, onError: (_) {}));
    await _clearMedia();
  }

  /// Deep link `?answer=1` — tự nhận khi đã có offer SDP.
  void requestAutoAnswer() {
    _autoAnswerPending = true;
    _tryAutoAnswer();
  }

  void _tryAutoAnswer() {
    if (!_autoAnswerPending) return;
    final call = activeCall;
    if (call == null ||
        call.direction != CallDirection.incoming ||
        call.offer == null ||
        call.status != CallUiStatus.ringing) {
      return;
    }
    _autoAnswerPending = false;
    unawaited(acceptCall());
  }

  Future<void> endCall({bool notifyPeer = true}) async {
    final call = activeCall;
    if (call == null) return;
    if (_endingCallId == call.id) return;
    _endingCallId = call.id;
    if (notifyPeer) {
      await _sendSignal({
        'type': 'call.end',
        'conversationId': call.conversationId,
        'callId': call.id,
      });
      unawaited(MessagingApi.endCall(call.id).then((_) {}, onError: (_) {}));
    }
    await _clearMedia();
  }

  void toggleMute() {
    muted = !muted;
    final tracks = _localStream?.getAudioTracks() ?? <MediaStreamTrack>[];
    for (final MediaStreamTrack track in tracks) {
      track.enabled = !muted;
    }
    notifyListeners();
  }

  void toggleCamera() {
    if (activeCall?.isVideo != true) return;
    cameraOff = !cameraOff;
    final tracks = _localStream?.getVideoTracks() ?? <MediaStreamTrack>[];
    for (final MediaStreamTrack track in tracks) {
      track.enabled = !cameraOff;
    }
    notifyListeners();
  }

  Future<void> flipCamera() async {
    if (activeCall?.isVideo != true) return;
    try {
      final videoTracks = _localStream?.getVideoTracks() ?? const [];
      if (videoTracks.isEmpty) return;
      await Helper.switchCamera(videoTracks.first);
      notifyListeners();
    } catch (e) {
      debugPrint('[call] flip camera failed: $e');
    }
  }

  Future<RTCPeerConnection> _createPeer(ActiveCall call) async {
    await _ensureRenderers();
    final stream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': call.isVideo
          ? {'facingMode': 'user', 'width': 1280, 'height': 720}
          : false,
    });
    _localStream = stream;
    _localRenderer.srcObject = stream;

    final peer = await createPeerConnection({
      'iceServers': _iceServers,
      'iceCandidatePoolSize': _turnAvailable ? 2 : 0,
      'bundlePolicy': 'max-bundle',
      'rtcpMuxPolicy': 'require',
    });

    for (final track in stream.getTracks()) {
      await peer.addTrack(track, stream);
    }

    peer.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteRenderer.srcObject = event.streams.first;
        notifyListeners();
      }
    };

    peer.onIceCandidate = (candidate) {
      if (candidate.candidate == null || candidate.candidate!.isEmpty) return;
      unawaited(
        _sendSignal({
          'type': 'call.ice',
          'conversationId': call.conversationId,
          'callId': call.id,
          'candidate': {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        }).then((sent) {
          if (!sent) _failSignaling(call);
        }),
      );
    };

    peer.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _ringTimer?.cancel();
        _disconnectedTimer?.cancel();
        if (activeCall?.id == call.id) {
          activeCall = activeCall!.copyWith(
            status: CallUiStatus.active,
            connectedAt: activeCall!.connectedAt ?? DateTime.now(),
          );
          notifyListeners();
        }
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        unawaited(_failConnection(call));
      } else if (state ==
          RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        _disconnectedTimer?.cancel();
        _disconnectedTimer = Timer(const Duration(seconds: 8), () {
          if (_peer?.connectionState ==
                  RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
              _peer?.connectionState ==
                  RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
            unawaited(_failConnection(call));
          }
        });
      }
    };

    peer.onIceConnectionState = (state) {
      if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        unawaited(_failConnection(call));
      }
    };

    _peer = peer;
    return peer;
  }

  Future<void> _failConnection(ActiveCall call) async {
    if (_endingCallId == call.id) return;
    lastError = _turnAvailable
        ? 'Không kết nối được qua TURN. Thử lại sau.'
        : 'Cuộc gọi bị ngắt kết nối.';
    await endCall();
    notifyListeners();
  }

  void _failSignaling(ActiveCall call) {
    if (_signalingFailedCallId == call.id) return;
    _signalingFailedCallId = call.id;
    lastError = 'Kênh realtime cuộc gọi không khả dụng.';
    unawaited(endCall());
    notifyListeners();
  }

  Future<bool> _sendSignal(Map<String, dynamic> message) async {
    final sent = _realtime.send(message);
    if (sent) return true;
    try {
      await MessagingApi.persistCallSignal(message);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _pollCallSignals() async {
    if (_currentUserId == null) return;
    try {
      final page = await MessagingApi.callSignals(after: _signalCursor);
      for (final event in page.items) {
        _onEvent(event);
      }
      if (page.nextCursor.isNotEmpty) {
        _signalCursor = page.nextCursor;
      }
    } catch (_) {
      // Polling is a fallback; ignore transient errors.
    }
  }

  void _onEvent(ChatRealtimeEvent event) {
    final payload = event.payload;
    final callId = payload['callId'] as String? ?? '';
    final conversationId =
        payload['conversationId'] as String? ?? event.aggregateId ?? '';
    if (callId.isEmpty || conversationId.isEmpty) return;

    if (event.type == 'call.ringing') {
      final initiatorId = payload['initiatorId'] as String? ?? '';
      if (initiatorId == _currentUserId) {
        final current = activeCall;
        if (current?.id == callId &&
            current?.direction == CallDirection.outgoing &&
            _localDescriptionReady.contains(callId) &&
            _peer != null) {
          unawaited(_resendLocalOffer(current!));
        }
        return;
      }
      if (activeCall != null && activeCall!.id != callId) {
        unawaited(
          _sendSignal({
            'type': 'call.reject',
            'conversationId': conversationId,
            'callId': callId,
          }),
        );
        unawaited(
          MessagingApi.rejectCall(callId).then((_) {}, onError: (_) {}),
        );
        return;
      }
      if (activeCall?.id == callId &&
          activeCall?.status != CallUiStatus.ringing) {
        return;
      }
      final mode = payload['mode'] == 'VIDEO' ? 'VIDEO' : 'AUDIO';
      final incoming = activeCall?.id == callId
          ? activeCall!
          : ActiveCall(
              id: callId,
              conversationId: conversationId,
              name: payload['initiatorUsername'] as String? ?? 'Nook',
              mode: mode,
              direction: CallDirection.incoming,
              status: CallUiStatus.ringing,
            );
      _endingCallId = null;
      _signalingFailedCallId = null;
      activeCall = incoming;
      notifyListeners();
      unawaited(_ringtone.start(mode: incoming.mode));
      _armIncomingTimeout(incoming);
      if (incoming.offer == null) _requestOffer(incoming);
      _tryAutoAnswer();
      return;
    }

    if (event.type == 'call.offer' && payload['sdp'] is Map) {
      final current = activeCall;
      if (current != null && current.id != callId) {
        unawaited(
          _sendSignal({
            'type': 'call.reject',
            'conversationId': conversationId,
            'callId': callId,
          }),
        );
        return;
      }
      if (current?.id == callId &&
          current?.direction == CallDirection.incoming &&
          current?.status != CallUiStatus.ringing) {
        if (_localDescriptionReady.contains(callId)) {
          unawaited(_resendLocalAnswer(current!));
        }
        return;
      }
      final mode = payload['mode'] == 'VIDEO' ? 'VIDEO' : 'AUDIO';
      final sdp = Map<String, dynamic>.from(payload['sdp'] as Map);
      activeCall = ActiveCall(
        id: callId,
        conversationId: conversationId,
        name: payload['username'] as String? ?? current?.name ?? 'Nook',
        mode: mode,
        direction: CallDirection.incoming,
        status: CallUiStatus.ringing,
        offer: sdp,
      );
      _endingCallId = null;
      _signalingFailedCallId = null;
      _offerRequestTimer?.cancel();
      notifyListeners();
      unawaited(_ringtone.start(mode: mode));
      _armIncomingTimeout(activeCall!);
      _tryAutoAnswer();
      return;
    }

    final current = activeCall;
    if (event.type == 'call.offer.request' &&
        current?.id == callId &&
        current?.direction == CallDirection.outgoing &&
        _localDescriptionReady.contains(callId)) {
      unawaited(_resendLocalOffer(current!));
      return;
    }
    if (event.type == 'call.answer.request' &&
        current?.id == callId &&
        current?.direction == CallDirection.incoming &&
        _localDescriptionReady.contains(callId)) {
      unawaited(_resendLocalAnswer(current!));
      return;
    }
    if (event.type == 'call.answered' || event.type == 'call.active') {
      if (current?.id == callId &&
          current?.direction == CallDirection.outgoing) {
        unawaited(() async {
          final remote = await _peer?.getRemoteDescription();
          if (remote != null) return;
          await _sendSignal({
            'type': 'call.answer.request',
            'conversationId': conversationId,
            'callId': callId,
          });
        }());
      }
      return;
    }
    if (event.type == 'call.ice' &&
        payload['candidate'] is Map &&
        callId.isNotEmpty) {
      if (current != null && current.id != callId) return;
      final map = Map<String, dynamic>.from(payload['candidate'] as Map);
      final candidate = RTCIceCandidate(
        map['candidate'] as String?,
        map['sdpMid'] as String?,
        map['sdpMLineIndex'] as int?,
      );
      unawaited(_handleRemoteIce(callId, candidate));
      return;
    }
    if (current == null || current.id != callId) return;
    if (event.type == 'call.answer' && payload['sdp'] is Map && _peer != null) {
      unawaited(() async {
        final remote = await _peer!.getRemoteDescription();
        if (remote != null) return;
        try {
          final sdp = Map<String, dynamic>.from(payload['sdp'] as Map);
          await _peer!.setRemoteDescription(
            RTCSessionDescription(
              sdp['sdp'] as String?,
              sdp['type'] as String?,
            ),
          );
          await _flushPendingIce(callId);
        } catch (e) {
          debugPrint('[call] apply answer failed: $e');
          lastError = 'Không thiết lập được cuộc gọi.';
          await endCall();
          notifyListeners();
        }
      }());
    } else if (const {
      'call.reject',
      'call.rejected',
      'call.end',
      'call.ended',
    }.contains(event.type)) {
      unawaited(_clearMedia());
    }
  }

  Future<void> _handleRemoteIce(
    String callId,
    RTCIceCandidate candidate,
  ) async {
    final peer = _peer;
    final remote = peer == null ? null : await peer.getRemoteDescription();
    if (peer != null && remote != null) {
      try {
        await peer.addCandidate(candidate);
      } catch (e) {
        debugPrint('[call] add ICE failed: $e');
      }
    } else {
      final list = _pendingIce.putIfAbsent(callId, () => []);
      if (list.length < 128) list.add(candidate);
    }
  }

  Future<void> _flushPendingIce(String callId) async {
    final peer = _peer;
    if (peer == null) return;
    final list = _pendingIce.remove(callId) ?? const [];
    for (final candidate in list) {
      try {
        await peer.addCandidate(candidate);
      } catch (_) {}
    }
  }

  void _requestOffer(ActiveCall call) {
    _offerRequestTimer?.cancel();
    void request() {
      final current = activeCall;
      if (current == null || current.id != call.id || current.offer != null) {
        _offerRequestTimer?.cancel();
        return;
      }
      unawaited(
        _sendSignal({
          'type': 'call.offer.request',
          'conversationId': call.conversationId,
          'callId': call.id,
        }),
      );
    }

    request();
    _offerRequestTimer = Timer.periodic(
      const Duration(milliseconds: 1500),
      (_) => request(),
    );
  }

  Future<void> _resendLocalOffer(ActiveCall call) async {
    final local = await _peer?.getLocalDescription();
    if (local == null) return;
    await _sendSignal({
      'type': 'call.offer',
      'conversationId': call.conversationId,
      'callId': call.id,
      'mode': call.mode,
      'sdp': local.toMap(),
    });
  }

  Future<void> _resendLocalAnswer(ActiveCall call) async {
    final local = await _peer?.getLocalDescription();
    if (local == null) return;
    await _sendSignal({
      'type': 'call.answer',
      'conversationId': call.conversationId,
      'callId': call.id,
      'mode': call.mode,
      'sdp': local.toMap(),
    });
  }

  void _armIncomingTimeout(ActiveCall call) {
    _ringTimer?.cancel();
    _ringTimer = Timer(_ringTimeout, () {
      if (activeCall?.id == call.id &&
          activeCall?.status == CallUiStatus.ringing) {
        unawaited(endCall());
        lastError = 'Không bắt máy.';
        notifyListeners();
      }
    });
  }

  void _armOutgoingTimeout(String callId) {
    _ringTimer?.cancel();
    _ringTimer = Timer(_ringTimeout, () {
      if (activeCall?.id == callId &&
          activeCall?.status != CallUiStatus.active) {
        unawaited(endCall());
        lastError = 'Không có người trả lời.';
        notifyListeners();
      }
    });
  }

  Future<void> _waitIceGathering(RTCPeerConnection peer) async {
    if (peer.iceGatheringState ==
        RTCIceGatheringState.RTCIceGatheringStateComplete) {
      return;
    }
    final completer = Completer<void>();
    late void Function(RTCIceGatheringState) handler;
    Timer? timer;
    handler = (state) {
      if (state == RTCIceGatheringState.RTCIceGatheringStateComplete &&
          !completer.isCompleted) {
        timer?.cancel();
        completer.complete();
      }
    };
    peer.onIceGatheringState = handler;
    timer = Timer(const Duration(seconds: 10), () {
      if (!completer.isCompleted) completer.complete();
    });
    await completer.future;
  }

  Future<void> _clearMedia() async {
    final callId = activeCall?.id;
    _ringtone.stop();
    _ringback.stop();
    _autoAnswerPending = false;
    _ringTimer?.cancel();
    _offerRequestTimer?.cancel();
    _disconnectedTimer?.cancel();
    final peer = _peer;
    _peer = null;
    if (peer != null) {
      try {
        await peer.close();
      } catch (_) {}
    }
    final allTracks = _localStream?.getTracks() ?? <MediaStreamTrack>[];
    for (final MediaStreamTrack track in allTracks) {
      await track.stop();
    }
    _localStream = null;
    _localRenderer.srcObject = null;
    _remoteRenderer.srcObject = null;
    if (callId != null) {
      _pendingIce.remove(callId);
      _localDescriptionReady.remove(callId);
    }
    activeCall = null;
    muted = false;
    cameraOff = false;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _signalPollTimer?.cancel();
    unawaited(_clearMedia());
    unawaited(_localRenderer.dispose());
    unawaited(_remoteRenderer.dispose());
    super.dispose();
  }
}
