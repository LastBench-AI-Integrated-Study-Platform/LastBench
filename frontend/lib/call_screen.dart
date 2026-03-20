import 'dart:async';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  SETUP STEPS
//  1. pubspec.yaml:
//       agora_rtc_engine: ^6.3.2
//       permission_handler: ^11.3.0
//
//  2. Android → AndroidManifest.xml:
//       <uses-permission android:name="android.permission.RECORD_AUDIO"/>
//       <uses-permission android:name="android.permission.CAMERA"/>
//       <uses-permission android:name="android.permission.INTERNET"/>
//
//  3. iOS → Info.plist:
//       NSMicrophoneUsageDescription → "For study calls"
//       NSCameraUsageDescription     → "For video study calls"
//
//  4. Replace appId below with your Agora App ID from console.agora.io
// ═══════════════════════════════════════════════════════════════════════════════

// ── Imports (uncomment when agora packages are added) ─────────────────────────
// import 'package:agora_rtc_engine/agora_rtc_engine.dart';
// import 'package:permission_handler/permission_handler.dart';

// ── Config ────────────────────────────────────────────────────────────────────
class AgoraConfig {
  static const String appId = 'YOUR_AGORA_APP_ID'; // ← replace
  static const String channelName = 'study_room_1';
  static const String token = ''; // use token server in production
}

// ── Colors ────────────────────────────────────────────────────────────────────
const _primary = Color(0xFF033F63);
const _secondary = Color(0xFF379392);
const _bg = Color(0xFFFFFFFF);
const _surface = Color(0xFFF9F9F9);
const _border = Color(0xFFE5E5E5);
const _muted = Color(0xFF666666);
const _mutedLight = Color(0xFFF0F0F0);
const _error = Color(0xFFEF4444);

// ── Participant model ─────────────────────────────────────────────────────────
class CallParticipant {
  final int uid;
  final String name;
  final String initials;
  final bool isLocal;

  const CallParticipant({
    required this.uid,
    required this.name,
    required this.initials,
    this.isLocal = false,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
//  AGORA SERVICE
//  Uncomment everything below when agora_rtc_engine is in pubspec.yaml
// ═══════════════════════════════════════════════════════════════════════════════
/*
class AgoraService {
  late RtcEngine _engine;
  bool _initialized = false;

  Future<void> init({
    required Function(int uid, int elapsed) onUserJoined,
    required Function(int uid) onUserOffline,
    required Function(ErrorCodeType err, String msg) onError,
  }) async {
    // Request permissions
    await [Permission.microphone, Permission.camera].request();

    // Create and initialize engine
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(
      appId: AgoraConfig.appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    // Register event handlers
    _engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) {
        debugPrint('Joined channel: ${connection.channelId}');
      },
      onUserJoined: (connection, uid, elapsed) => onUserJoined(uid, elapsed),
      onUserOffline: (connection, uid, reason) => onUserOffline(uid),
      onError: (err, msg) => onError(err, msg),
      onConnectionStateChanged: (connection, state, reason) {
        debugPrint('Connection state: $state');
      },
    ));

    // Enable video
    await _engine.enableVideo();
    await _engine.startPreview();

    // Join channel
    await _engine.joinChannel(
      token: AgoraConfig.token,
      channelId: AgoraConfig.channelName,
      uid: 0, // 0 = auto-assign
      options: const ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileCommunication,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
      ),
    );

    _initialized = true;
  }

  // Local video view widget
  Widget localView() => AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine,
          canvas: const VideoCanvas(uid: 0),
        ),
      );

  // Remote video view widget
  Widget remoteView(int uid) => AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: uid),
          connection: const RtcConnection(channelId: AgoraConfig.channelName),
        ),
      );

  Future<void> muteAudio(bool mute) => _engine.muteLocalAudioStream(mute);
  Future<void> muteVideo(bool mute) => _engine.muteLocalVideoStream(mute);
  Future<void> switchCamera() => _engine.switchCamera();

  Future<void> leave() async {
    if (!_initialized) return;
    await _engine.leaveChannel();
    await _engine.release();
    _initialized = false;
  }
}
*/

// ═══════════════════════════════════════════════════════════════════════════════
//  CALL SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with TickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isVideoMode = true;
  bool _isConnecting = true;
  int _callSeconds = 0;

  // ── Agora ──────────────────────────────────────────────────────────────────
  // final AgoraService _agora = AgoraService(); // ← uncomment for real calls

  // Simulated participants — replace with Agora UIDs in real implementation
  final List<CallParticipant> _participants = [
    const CallParticipant(uid: 0, name: 'You', initials: 'Y', isLocal: true),
    const CallParticipant(uid: 1001, name: 'Alex Smith', initials: 'AS'),
    const CallParticipant(uid: 1002, name: 'Sarah Johnson', initials: 'SJ'),
  ];

  // ── Timers & Animation ─────────────────────────────────────────────────────
  Timer? _durationTimer;
  Timer? _connectTimer;
  late AnimationController _pulseAnim;
  late AnimationController _waveAnim;

  @override
  void initState() {
    super.initState();

    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _waveAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    // Simulate connection (replace with _agora.init(...) below)
    _connectTimer = Timer(const Duration(seconds: 2), _onConnected);

    // ── REAL Agora init (uncomment when package is added) ───────────────────
    /*
    _agora.init(
      onUserJoined: (uid, elapsed) {
        setState(() {
          _participants.add(CallParticipant(
            uid: uid,
            name: 'User $uid',
            initials: 'U',
          ));
        });
      },
      onUserOffline: (uid) {
        setState(() => _participants.removeWhere((p) => p.uid == uid));
      },
      onError: (err, msg) => debugPrint('Agora error $err: $msg'),
    ).then((_) => _onConnected());
    */
  }

  void _onConnected() {
    if (!mounted) return;
    setState(() => _isConnecting = false);
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _callSeconds++);
    });
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _connectTimer?.cancel();
    _pulseAnim.dispose();
    _waveAnim.dispose();
    // _agora.leave(); // ← uncomment for real calls
    super.dispose();
  }

  String get _formattedTime {
    final m = (_callSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_callSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              isVideoMode: _isVideoMode,
              isConnecting: _isConnecting,
              participantCount: _participants.length,
              formattedTime: _formattedTime,
              pulseAnim: _pulseAnim,
            ),
            Expanded(
              child: _isConnecting
                  ? _ConnectingView(pulseAnim: _pulseAnim)
                  : Row(
                      children: [
                        Expanded(
                          child: _isVideoMode
                              ? _VideoGrid(
                                  participants: _participants,
                                  isCameraOff: _isCameraOff,
                                  // agoraService: _agora, // ← pass for real video
                                )
                              : _VoiceView(
                                  participants: _participants,
                                  isMuted: _isMuted,
                                  waveAnim: _waveAnim,
                                  pulseAnim: _pulseAnim,
                                ),
                        ),
                        _ParticipantsSidebar(participants: _participants),
                      ],
                    ),
            ),
            _ControlBar(
              isMuted: _isMuted,
              isCameraOff: _isCameraOff,
              isVideoMode: _isVideoMode,
              onToggleMute: () {
                setState(() => _isMuted = !_isMuted);
                // _agora.muteAudio(_isMuted); // ← uncomment
              },
              onToggleCamera: () {
                setState(() => _isCameraOff = !_isCameraOff);
                // _agora.muteVideo(_isCameraOff); // ← uncomment
              },
              onSwitchMode: (isVideo) => setState(() => _isVideoMode = isVideo),
              onEndCall: () {
                // _agora.leave(); // ← uncomment
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  HEADER
// ═══════════════════════════════════════════════════════════════════════════════
class _Header extends StatelessWidget {
  final bool isVideoMode, isConnecting;
  final int participantCount;
  final String formattedTime;
  final AnimationController pulseAnim;

  const _Header({
    required this.isVideoMode,
    required this.isConnecting,
    required this.participantCount,
    required this.formattedTime,
    required this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: pulseAnim,
            builder: (_, __) => Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isConnecting
                    ? Colors.orange.withOpacity(0.5 + 0.5 * pulseAnim.value)
                    : _secondary.withOpacity(0.4 + 0.6 * pulseAnim.value),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            isVideoMode ? 'Video Call' : 'Voice Call',
            style: const TextStyle(
              color: _primary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            isConnecting ? 'Connecting...' : '$participantCount members',
            style: const TextStyle(
              color: _secondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            isConnecting ? '00:00' : formattedTime,
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
}

// ═══════════════════════════════════════════════════════════════════════════════
//  CONNECTING VIEW
// ═══════════════════════════════════════════════════════════════════════════════
class _ConnectingView extends StatelessWidget {
  final AnimationController pulseAnim;
  const _ConnectingView({required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: pulseAnim,
            builder: (_, __) => Container(
              width: 80 + 24 * pulseAnim.value,
              height: 80 + 24 * pulseAnim.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _secondary.withOpacity(0.08 + 0.08 * pulseAnim.value),
              ),
              child: const Icon(Icons.phone, color: _secondary, size: 38),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Joining study call...',
            style: TextStyle(
              color: _primary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Connecting to your study group',
            style: TextStyle(color: _muted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  VIDEO GRID
// ═══════════════════════════════════════════════════════════════════════════════
class _VideoGrid extends StatelessWidget {
  final List<CallParticipant> participants;
  final bool isCameraOff;
  // final AgoraService? agoraService; // ← pass for real video

  const _VideoGrid({required this.participants, required this.isCameraOff});

  @override
  Widget build(BuildContext context) {
    final remotes = participants.where((p) => !p.isLocal).toList();
    return Container(
      color: _surface,
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          // ── Local (main) video ─────────────────────────────────────────
          Expanded(
            flex: 3,
            child: _VideoTile(
              label: 'You',
              isMain: true,
              child: isCameraOff
                  ? _CameraOffPlaceholder(name: 'You')
                  : _LocalVideoPlaceholder(),
              // child: agoraService?.localView() ?? _LocalVideoPlaceholder(),
            ),
          ),
          const SizedBox(height: 10),
          // ── Remote participants ────────────────────────────────────────
          if (remotes.isNotEmpty)
            Expanded(
              flex: 2,
              child: Row(
                children: remotes
                    .map(
                      (p) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: _VideoTile(
                            label: p.name,
                            child: _RemoteVideoPlaceholder(participant: p),
                            // child: agoraService?.remoteView(p.uid) ?? _RemoteVideoPlaceholder(participant: p),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _VideoTile extends StatelessWidget {
  final Widget child;
  final String label;
  final bool isMain;

  const _VideoTile({
    required this.child,
    required this.label,
    this.isMain = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.circular(isMain ? 16 : 12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
          Positioned(
            bottom: 10,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalVideoPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _secondary.withOpacity(0.2),
            ),
            child: const Icon(Icons.videocam, color: _secondary, size: 30),
          ),
          const SizedBox(height: 10),
          const Text(
            'Your Camera',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'LIVE',
              style: TextStyle(
                color: Colors.green,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraOffPlaceholder extends StatelessWidget {
  final String name;
  const _CameraOffPlaceholder({required this.name});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam_off, color: Colors.white38, size: 36),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _RemoteVideoPlaceholder extends StatelessWidget {
  final CallParticipant participant;
  const _RemoteVideoPlaceholder({required this.participant});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: _secondary,
            ),
            child: Center(
              child: Text(
                participant.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            participant.name,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  VOICE VIEW
// ═══════════════════════════════════════════════════════════════════════════════
class _VoiceView extends StatelessWidget {
  final List<CallParticipant> participants;
  final bool isMuted;
  final AnimationController waveAnim;
  final AnimationController pulseAnim;

  const _VoiceView({
    required this.participants,
    required this.isMuted,
    required this.waveAnim,
    required this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Text(
            'Voice Call Active',
            style: TextStyle(
              color: _primary,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${participants.length} members connected',
            style: const TextStyle(color: _secondary, fontSize: 15),
          ),
          const SizedBox(height: 40),
          // ── Animated waveform ────────────────────────────────────────
          SizedBox(
            height: 80,
            child: AnimatedBuilder(
              animation: waveAnim,
              builder: (_, __) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(9, (i) {
                  final t = (waveAnim.value + i * 0.12) % 1.0;
                  final h = isMuted
                      ? 8.0
                      : (16.0 + 52.0 * (0.5 + 0.5 * (t * 2 - 1).abs()));
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 5,
                    height: h.clamp(8.0, 80.0),
                    decoration: BoxDecoration(
                      color: isMuted
                          ? _secondary.withOpacity(0.25)
                          : _secondary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 40),
          // ── Members list ─────────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              itemCount: participants.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final p = participants[i];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _mutedLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: _secondary,
                        ),
                        child: Center(
                          child: Text(
                            p.initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: const TextStyle(
                                color: _primary,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            const Text(
                              'Connected',
                              style: TextStyle(color: _muted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      if (!isMuted && !p.isLocal)
                        AnimatedBuilder(
                          animation: pulseAnim,
                          builder: (_, __) => Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _secondary.withOpacity(
                                0.4 + 0.6 * pulseAnim.value,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  PARTICIPANTS SIDEBAR
// ═══════════════════════════════════════════════════════════════════════════════
class _ParticipantsSidebar extends StatelessWidget {
  final List<CallParticipant> participants;
  const _ParticipantsSidebar({required this.participants});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(left: BorderSide(color: _border)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Participants',
            style: TextStyle(
              color: _primary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: participants.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final p = participants[i];
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: _border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: _secondary,
                        ),
                        child: Center(
                          child: Text(
                            p.initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: const TextStyle(
                                color: _primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text(
                              'Connected',
                              style: TextStyle(color: _secondary, fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: _secondary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  CONTROL BAR
// ═══════════════════════════════════════════════════════════════════════════════
class _ControlBar extends StatelessWidget {
  final bool isMuted, isCameraOff, isVideoMode;
  final VoidCallback onToggleMute, onToggleCamera, onEndCall;
  final ValueChanged<bool> onSwitchMode;

  const _ControlBar({
    required this.isMuted,
    required this.isCameraOff,
    required this.isVideoMode,
    required this.onToggleMute,
    required this.onToggleCamera,
    required this.onSwitchMode,
    required this.onEndCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _IconBtn(
            icon: isMuted ? Icons.mic_off : Icons.mic,
            active: !isMuted,
            tooltip: isMuted ? 'Unmute' : 'Mute',
            onTap: onToggleMute,
          ),
          const SizedBox(width: 14),
          _IconBtn(
            icon: isCameraOff ? Icons.videocam_off : Icons.videocam,
            active: !isCameraOff,
            tooltip: isCameraOff ? 'Camera on' : 'Camera off',
            onTap: onToggleCamera,
          ),
          const SizedBox(width: 18),
          // Mode toggle pill
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _mutedLight,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                _ModeBtn(
                  label: 'Video',
                  selected: isVideoMode,
                  onTap: () => onSwitchMode(true),
                ),
                _ModeBtn(
                  label: 'Voice',
                  selected: !isVideoMode,
                  onTap: () => onSwitchMode(false),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          // End call
          GestureDetector(
            onTap: onEndCall,
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: _error,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _error.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.call_end, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final String tooltip;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.active,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? _secondary : _error;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }
}

class _ModeBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeBtn({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? _primary : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : _primary,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
