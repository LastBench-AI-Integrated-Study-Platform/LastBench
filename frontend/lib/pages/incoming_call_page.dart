// frontend/lib/pages/incoming_call_page.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import 'real_call_page.dart';

const _navy = Color(0xFF033F63);
const _teal = Color(0xFF379392);

class IncomingCallPage extends StatefulWidget {
  final String callerId;
  final String callerName;
  final String callerInitials;
  final String channel;
  final String callType;
  final String logId;

  const IncomingCallPage({
    super.key,
    required this.callerId,
    required this.callerName,
    required this.callerInitials,
    required this.channel,
    required this.callType,
    required this.logId,
  });

  @override
  State<IncomingCallPage> createState() => _IncomingCallPageState();
}

class _IncomingCallPageState extends State<IncomingCallPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // Caller cancelled while we're on this screen
    SocketService().onCallEnded(() {
      if (mounted) Navigator.pop(context);
    });
  }

  void _accept() {
    SocketService().acceptCall(widget.callerId, widget.logId);
    SocketService().offAll();

    final caller = UserModel(
      id: widget.callerId,
      username: widget.callerName,
      name: widget.callerName,
      avatar: '',
      isOnline: true,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => RealCallPage(
          channel: widget.channel,
          callType: widget.callType,
          remoteUser: caller,
          isCallerSide: false,
          logId: widget.logId,
        ),
      ),
    );
  }

  void _reject() {
    SocketService().rejectCall(widget.callerId, widget.logId);
    SocketService().offAll();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _pulse.dispose();
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
            Text(
              widget.callType == 'video'
                  ? 'Incoming Video Call'
                  : 'Incoming Audio Call',
              style: TextStyle(
                color: Colors.white.withOpacity(0.65),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            // Pulse + avatar
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, child) => Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 140 + 28 * _pulse.value,
                    height: 140 + 28 * _pulse.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _teal.withOpacity(0.07 + 0.08 * _pulse.value),
                    ),
                  ),
                  child!,
                ],
              ),
              child: CircleAvatar(
                radius: 62,
                backgroundColor: _teal,
                child: Text(
                  widget.callerInitials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              widget.callerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 80),
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CallBtn(
                  icon: Icons.call_end,
                  color: const Color(0xFFEF4444),
                  label: 'Decline',
                  onTap: _reject,
                ),
                _CallBtn(
                  icon: widget.callType == 'video'
                      ? Icons.videocam
                      : Icons.call,
                  color: const Color(0xFF22C55E),
                  label: 'Accept',
                  onTap: _accept,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CallBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _CallBtn({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }
}
