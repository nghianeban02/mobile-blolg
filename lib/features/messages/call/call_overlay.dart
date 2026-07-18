import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/features/messages/call/call_controller.dart';

/// Full-screen call UI — ringing / connecting / active.
class CallOverlay extends StatelessWidget {
  const CallOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final calls = CallController.instance;
    return ListenableBuilder(
      listenable: calls,
      builder: (context, _) {
        final call = calls.activeCall;
        if (call == null) return const SizedBox.shrink();

        final error = calls.lastError;
        if (error != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (calls.lastError == null) return;
            final messenger = ScaffoldMessenger.maybeOf(context);
            messenger?.showSnackBar(SnackBar(content: Text(calls.lastError!)));
            calls.lastError = null;
          });
        }

        return Positioned.fill(
          child: Material(
            color: const Color(0xFF121110),
            child: SafeArea(
              child: Stack(
                children: [
                  if (call.isVideo && call.status == CallUiStatus.active)
                    Positioned.fill(
                      child: RTCVideoView(
                        calls.remoteRenderer,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
                    )
                  else
                    _AudioBackdrop(call: call),
                  if (call.isVideo && call.status == CallUiStatus.active)
                    Positioned(
                      right: 16,
                      top: 16,
                      width: 110,
                      height: 160,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: RTCVideoView(
                          calls.localRenderer,
                          mirror: true,
                          objectFit:
                              RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        ),
                      ),
                    ),
                  Positioned(
                    left: 20,
                    right: 20,
                    top: 24,
                    child: Column(
                      children: [
                        Text(
                          call.name,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _statusLabel(call),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 36,
                    child:
                        call.status == CallUiStatus.ringing &&
                            call.direction == CallDirection.incoming
                        ? _IncomingActions(
                            onReject: calls.rejectCall,
                            onAccept: calls.acceptCall,
                          )
                        : _ActiveActions(
                            call: call,
                            muted: calls.muted,
                            cameraOff: calls.cameraOff,
                            onToggleMute: calls.toggleMute,
                            onToggleCamera: calls.toggleCamera,
                            onFlipCamera: calls.flipCamera,
                            onEnd: calls.endCall,
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static String _statusLabel(ActiveCall call) {
    switch (call.status) {
      case CallUiStatus.ringing:
        return call.direction == CallDirection.incoming
            ? (call.isVideo ? 'Cuộc gọi video đến…' : 'Cuộc gọi thoại đến…')
            : 'Đang đổ chuông…';
      case CallUiStatus.connecting:
        return 'Đang kết nối…';
      case CallUiStatus.active:
        if (call.connectedAt == null) return 'Đang nói chuyện';
        final seconds = DateTime.now().difference(call.connectedAt!).inSeconds;
        final m = (seconds ~/ 60).toString().padLeft(2, '0');
        final s = (seconds % 60).toString().padLeft(2, '0');
        return '$m:$s';
    }
  }
}

class _AudioBackdrop extends StatelessWidget {
  final ActiveCall call;

  const _AudioBackdrop({required this.call});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A211C), Color(0xFF121110)],
          ),
        ),
        child: Center(
          child: CircleAvatar(
            radius: 56,
            backgroundColor: AppColors.primaryBrown.withValues(alpha: 0.35),
            child: Text(
              call.name.isNotEmpty
                  ? call.name.characters.first.toUpperCase()
                  : '?',
              style: GoogleFonts.playfairDisplay(
                fontSize: 42,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IncomingActions extends StatelessWidget {
  final Future<void> Function() onReject;
  final Future<void> Function() onAccept;

  const _IncomingActions({required this.onReject, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _RoundAction(
          color: const Color(0xFFEF4444),
          icon: Icons.call_end_rounded,
          label: 'Từ chối',
          onTap: onReject,
        ),
        _RoundAction(
          color: const Color(0xFF10B981),
          icon: Icons.call_rounded,
          label: 'Nhận',
          onTap: onAccept,
        ),
      ],
    );
  }
}

class _ActiveActions extends StatelessWidget {
  final ActiveCall call;
  final bool muted;
  final bool cameraOff;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleCamera;
  final VoidCallback onFlipCamera;
  final VoidCallback onEnd;

  const _ActiveActions({
    required this.call,
    required this.muted,
    required this.cameraOff,
    required this.onToggleMute,
    required this.onToggleCamera,
    required this.onFlipCamera,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _RoundAction(
          color: muted ? Colors.white24 : Colors.white12,
          icon: muted ? Icons.mic_off_rounded : Icons.mic_rounded,
          label: muted ? 'Bật mic' : 'Tắt mic',
          onTap: onToggleMute,
        ),
        if (call.isVideo) ...[
          _RoundAction(
            color: cameraOff ? Colors.white24 : Colors.white12,
            icon: cameraOff
                ? Icons.videocam_off_rounded
                : Icons.videocam_rounded,
            label: cameraOff ? 'Bật cam' : 'Tắt cam',
            onTap: onToggleCamera,
          ),
          _RoundAction(
            color: Colors.white12,
            icon: Icons.cameraswitch_rounded,
            label: 'Đổi cam',
            onTap: onFlipCamera,
          ),
        ],
        _RoundAction(
          color: const Color(0xFFEF4444),
          icon: Icons.call_end_rounded,
          label: 'Kết thúc',
          onTap: onEnd,
        ),
      ],
    );
  }
}

class _RoundAction extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _RoundAction({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 64,
              height: 64,
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }
}
