// frontend/lib/widgets/call_manager.dart
// Wrap this around your home widget. It catches incoming call socket events
// globally and shows IncomingCallPage on top of whatever screen is open.

import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;
import '../services/socket_service.dart';
import '../services/user_session.dart';
import '../pages/incoming_call_page.dart';

class CallManager extends StatefulWidget {
  final Widget child;
  const CallManager({super.key, required this.child});

  @override
  State<CallManager> createState() => _CallManagerState();
}

class _CallManagerState extends State<CallManager> {
  @override
  void initState() {
    super.initState();

    final userId = html.window.localStorage['lb_user_id'];
    final username = html.window.localStorage['lb_user_username'] ?? '';
    final name = html.window.localStorage['lb_user_name'] ?? '';

    if (userId != null && userId.isNotEmpty) {
      if (!UserSession().isLoggedIn) {
        UserSession().set(userId: userId, username: username, name: name);
      }
      SocketService().connect(UserSession().userId);
    }

    SocketService().onIncomingCall((data) {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => IncomingCallPage(
            callerId: data['callerId'] ?? '',
            callerName: data['callerName'] ?? 'Unknown',
            callerInitials: data['callerInitials'] ?? '?',
            channel: data['channel'] ?? '',
            callType: data['callType'] ?? 'video',
            logId: data['logId']?.toString() ?? '',
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
