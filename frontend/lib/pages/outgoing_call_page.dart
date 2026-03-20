// frontend/lib/pages/outgoing_call_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import 'real_call_page.dart';

const _navy = Color(0xFF033F63);
const _teal = Color(0xFF379392);

class OutgoingCallPage extends StatefulWidget {
  final UserModel receiver;
  final String channel;
  final String callType;

  const OutgoingCallPage({
    super.key,
    required this.receiver,
    required this.channel,
    required this.callType,
  });

  @override
  State<OutgoingCallPage> createState() => _OutgoingCallPageState();
}

class _OutgoingCallPageState extends State<OutgoingCallPage>
    with SingleTickerProviderStateMixin {
  String _status = 'Calling...';
  String? _logId;
  late AnimationController _pulse;
  Timer? _timeout;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    final s = SocketService();

    s.onCallRinging((data) {
      _logId = data['logId']?.toString();
      if (mounted) setState(() => _status = 'Ringing...');
    });

    s.onCallAccepted((_) => _joinCall());

    s.onCallRejected((data) {
      if (mounted) _showEnded(data['reason'] ?? 'Call declined');
    });

    // Auto cancel after 45 s
    _timeout = Timer(const Duration(seconds: 45), () {
      if (mounted) _cancel('No answer');
    });
  }

  void _joinCall() {
    _timeout?.cancel();
    SocketService().offAll();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => RealCallPage(
          channel: widget.channel,
          callType: widget.callType,
          remoteUser: widget.receiver,
          isCallerSide: true,
          logId: _logId ?? '',
        ),
      ),
    );
  }

  void _cancel(String reason) {
    SocketService().rejectCall(widget.receiver.id, _logId ?? '');
    SocketService().offAll();
    _timeout?.cancel();
    if (mounted) Navigator.pop(context);
  }

  void _showEnded(String msg) {
    _timeout?.cancel();
    SocketService().offAll();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Call ended'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    _timeout?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pulse ring
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => Container(
                width: 130 + 30 * _pulse.value,
                height: 130 + 30 * _pulse.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _teal.withOpacity(0.08 + 0.1 * _pulse.value),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Avatar
            CircleAvatar(
              radius: 56,
              backgroundColor: _teal,
              child: Text(
                widget.receiver.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.receiver.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '@${widget.receiver.username}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.callType == 'video' ? Icons.videocam : Icons.call,
                  color: _teal,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.callType == 'video' ? 'Video call' : 'Audio call',
                  style: const TextStyle(color: _teal, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _status,
              style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 64),
            // Cancel button
            GestureDetector(
              onTap: () => _cancel('Cancelled'),
              child: Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.call_end,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Cancel',
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
