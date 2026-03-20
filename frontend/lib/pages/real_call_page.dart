// frontend/lib/pages/real_call_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/user_session.dart';

const _navy = Color(0xFF033F63);
const _teal = Color(0xFF379392);
const _bg = Color(0xFFFFFFFF);
const _border = Color(0xFFE5E5E5);
const _error = Color(0xFFEF4444);
const _muted = Color(0xFF666666);

class RealCallPage extends StatefulWidget {
  final String channel;
  final String callType; // 'video' | 'audio'
  final UserModel remoteUser;
  final bool isCallerSide;
  final String logId;

  const RealCallPage({
    super.key,
    required this.channel,
    required this.callType,
    required this.remoteUser,
    required this.isCallerSide,
    required this.logId,
  });

  @override
  State<RealCallPage> createState() => _RealCallPageState();
}

class _RealCallPageState extends State<RealCallPage>
    with SingleTickerProviderStateMixin {
  // ── Agora ──────────────────────────────────────────────────────────────────
  late RtcEngine _engine;
  bool _engineReady = false;
  int? _remoteUid;

  // ── Controls ───────────────────────────────────────────────────────────────
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isSpeakerOn = true;
  bool _isVideoMode = false; // set from widget.callType

  // ── Timer ──────────────────────────────────────────────────────────────────
  int _seconds = 0;
  Timer? _timer;

  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _isVideoMode = widget.callType == 'video';
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _initAgora();

    // Remote side hung up
    SocketService().onCallEnded(() {
      if (mounted) _endCall(navigateBack: true);
    });
  }

  // ── Agora init ─────────────────────────────────────────────────────────────
  Future<void> _initAgora() async {
    // 1. Web Fallback Check
    if (kIsWeb) {
      // Agora RTC Flutter plugin requires native setup. For web testing,
      // we bypass the native engine crash and simulate a connected state.
      setState(() {
        _engineReady = true;
        _remoteUid = 999; // Mock remote user
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _seconds++);
      });
      return;
    }

    // 1. Permissions (Mobile only)
    final perms = [Permission.microphone];
    if (_isVideoMode) perms.add(Permission.camera);
    await perms.request();

    // 2. Get token from your FastAPI backend
    final uid = UserSession().userId.hashCode.abs() % 100000;
    final tokenRes = await ApiService.getAgoraToken(widget.channel, uid);

    if (tokenRes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not get call token. Is the server running?'),
          ),
        );
        Navigator.pop(context);
      }
      return;
    }

    // 3. Create engine
    _engine = createAgoraRtcEngine();
    await _engine.initialize(
      RtcEngineContext(
        appId: tokenRes.appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    // 4. Events
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (_, __) {
          if (mounted) {
            setState(() => _engineReady = true);
            _timer = Timer.periodic(const Duration(seconds: 1), (_) {
              if (mounted) setState(() => _seconds++);
            });
          }
        },
        onUserJoined: (_, uid, __) {
          if (mounted) setState(() => _remoteUid = uid);
        },
        onUserOffline: (_, uid, __) {
          if (mounted) {
            setState(() => _remoteUid = null);
            _endCall(navigateBack: true);
          }
        },
        onError: (err, msg) => debugPrint('Agora error $err: $msg'),
      ),
    );

    // 5. Video / audio setup
    if (_isVideoMode) {
      await _engine.enableVideo();
      await _engine.startPreview();
    } else {
      await _engine.disableVideo();
      await _engine.setEnableSpeakerphone(true);
    }

    // 6. Join channel
    await _engine.joinChannel(
      token: tokenRes.token,
      channelId: widget.channel,
      uid: uid,
      options: ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileCommunication,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishCameraTrack: _isVideoMode,
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
        autoSubscribeVideo: _isVideoMode,
      ),
    );
  }

  // ── Controls ───────────────────────────────────────────────────────────────
  Future<void> _toggleMute() async {
    _isMuted = !_isMuted;
    await _engine.muteLocalAudioStream(_isMuted);
    setState(() {});
  }

  Future<void> _toggleCamera() async {
    _isCameraOff = !_isCameraOff;
    await _engine.muteLocalVideoStream(_isCameraOff);
    setState(() {});
  }

  Future<void> _switchCamera() => _engine.switchCamera();

  Future<void> _toggleSpeaker() async {
    _isSpeakerOn = !_isSpeakerOn;
    await _engine.setEnableSpeakerphone(_isSpeakerOn);
    setState(() {});
  }

  void _hangUp() {
    SocketService().endCall(widget.remoteUser.id, widget.logId);
    _endCall(navigateBack: true);
  }

  Future<void> _endCall({required bool navigateBack}) async {
    _timer?.cancel();
    SocketService().offAll();
    if (!kIsWeb) {
      try {
        await _engine.leaveChannel();
        await _engine.release();
      } catch (_) {}
    }
    if (navigateBack && mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  String get _duration {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: !_engineReady
                  ? _buildConnecting()
                  : _isVideoMode
                  ? _buildVideoLayout()
                  : _buildAudioLayout(),
            ),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _engineReady
                    ? _teal.withOpacity(0.4 + 0.6 * _pulseCtrl.value)
                    : Colors.orange.withOpacity(0.4 + 0.6 * _pulseCtrl.value),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _isVideoMode ? 'Video Call' : 'Audio Call',
            style: const TextStyle(
              color: _navy,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _engineReady ? 'with ${widget.remoteUser.name}' : 'Connecting...',
              style: const TextStyle(color: _teal, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _engineReady ? _duration : '00:00',
            style: const TextStyle(
              color: _muted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Connecting ─────────────────────────────────────────────────────────────
  Widget _buildConnecting() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Container(
              width: 80 + 24 * _pulseCtrl.value,
              height: 80 + 24 * _pulseCtrl.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _teal.withOpacity(0.08 + 0.08 * _pulseCtrl.value),
              ),
              child: const Icon(Icons.phone, color: _teal, size: 38),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Connecting...',
            style: TextStyle(
              color: _navy,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Setting up ${widget.callType} call',
            style: const TextStyle(color: _muted, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ── Video layout ───────────────────────────────────────────────────────────
  Widget _buildVideoLayout() {
    return Stack(
      children: [
        // Remote full-screen
        (!kIsWeb && _remoteUid != null)
            ? AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: _engine,
                  canvas: VideoCanvas(uid: _remoteUid!),
                  connection: RtcConnection(channelId: widget.channel),
                ),
              )
            : Container(
                color: _navy,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: _teal,
                        child: Text(
                          widget.remoteUser.initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.remoteUser.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Waiting for video...',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),

        // Local PiP — bottom right
        Positioned(
          bottom: 16,
          right: 16,
          width: 110,
          height: 160,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _isCameraOff
                ? Container(
                    color: _navy,
                    child: const Center(
                      child: Icon(
                        Icons.videocam_off,
                        color: Colors.white54,
                        size: 28,
                      ),
                    ),
                  )
                : (kIsWeb
                      ? Container(
                          color: Colors.black87,
                          child: const Center(
                            child: Icon(
                              Icons.videocam,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        )
                      : AgoraVideoView(
                          controller: VideoViewController(
                            rtcEngine: _engine,
                            canvas: const VideoCanvas(uid: 0),
                          ),
                        )),
          ),
        ),

        // Name tag
        Positioned(
          bottom: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.remoteUser.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Audio layout ───────────────────────────────────────────────────────────
  Widget _buildAudioLayout() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 66,
            backgroundColor: _teal,
            child: Text(
              widget.remoteUser.initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.remoteUser.name,
            style: const TextStyle(
              color: _navy,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _remoteUid != null ? 'Connected  •  $_duration' : 'Waiting...',
            style: TextStyle(
              color: _remoteUid != null ? _teal : Colors.orange,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 40),
          // Waveform
          if (_remoteUid != null)
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(9, (i) {
                  final h = _isMuted
                      ? 6.0
                      : (12.0 + 42.0 * ((_pulseCtrl.value + i * 0.13) % 1.0));
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 5,
                    height: h.clamp(6.0, 60.0),
                    decoration: BoxDecoration(
                      color: _isMuted ? _teal.withOpacity(0.2) : _teal,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  // ── Controls bar ───────────────────────────────────────────────────────────
  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _CtrlBtn(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            active: !_isMuted,
            label: _isMuted ? 'Unmute' : 'Mute',
            onTap: _toggleMute,
          ),
          if (_isVideoMode) ...[
            _CtrlBtn(
              icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
              active: !_isCameraOff,
              label: _isCameraOff ? 'Cam on' : 'Cam off',
              onTap: _toggleCamera,
            ),
            _CtrlBtn(
              icon: Icons.flip_camera_ios,
              active: true,
              label: 'Flip',
              onTap: _switchCamera,
            ),
          ],
          _CtrlBtn(
            icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
            active: _isSpeakerOn,
            label: _isSpeakerOn ? 'Speaker' : 'Earpiece',
            onTap: _toggleSpeaker,
          ),
          // End call
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _hangUp,
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: _error,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.call_end,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text('End', style: TextStyle(fontSize: 11, color: _error)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Reusable control button ───────────────────────────────────────────────────
class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final String label;
  final VoidCallback onTap;

  const _CtrlBtn({
    required this.icon,
    required this.active,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? _teal : _error;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }
}
