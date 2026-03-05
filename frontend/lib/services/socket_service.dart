// frontend/lib/services/socket_service.dart

import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _connected = false;

  bool get isConnected => _connected;

  void connect(String userId, {String? serverUrl}) {
    if (_connected) return;
  
  final url = 'http://192.168.0.150:8000';

    _socket = IO.io(
      url,
      IO.OptionBuilder()
          .setTransports(['websocket','polling']) // IMPORTANT
          .enableAutoConnect()
          .setAuth({'user_id': userId})
          .setTimeout(5000)
          .build(),
    );

    _socket!.onConnect((_) {
      _connected = true;
      print("✅ CONNECTED TO SERVER");
      _socket!.emit('user_register', userId);
    });

    _socket!.onDisconnect((_) {
      _connected = false;
      print("❌ DISCONNECTED");
    });

    _socket!.onConnectError((e) => print("Connect Error: $e"));
    _socket!.onError((e) => print("Socket Error: $e"));
  }

  void disconnect() {
    _socket?.disconnect();
    _connected = false;
  }

  // ───── EMIT EVENTS ─────────────────────────────

  void sendCallInvite({
    required String callerId,
    required String callerName,
    required String callerInitials,
    required String receiverId,
    required String channel,
    required String callType,
  }) {
    print("🔥 CALL INVITE TRIGGERED");
    _socket?.emit('call_invite', {
      'callerId': callerId,
      'callerName': callerName,
      'callerInitials': callerInitials,
      'receiverId': receiverId,
      'channel': channel,
      'callType': callType,
    });
  }

  void acceptCall(String callerId, String logId) {
    _socket?.emit('call_accept', {
      'callerId': callerId,
      'logId': logId,
    });
  }

  void rejectCall(String callerId, String logId) {
    _socket?.emit('call_reject', {
      'callerId': callerId,
      'logId': logId,
    });
  }

  void endCall(String otherUserId, String logId) {
    _socket?.emit('call_end', {
      'otherUserId': otherUserId,
      'logId': logId,
    });
  }

  // ───── LISTEN EVENTS ───────────────────────────

  void onIncomingCall(Function(Map<String, dynamic>) cb) {
    _socket?.on('call_incoming', (data) {
      cb(Map<String, dynamic>.from(data));
    });
  }

  void onCallAccepted(Function(Map<String, dynamic>) cb) {
    _socket?.on('call_accepted', (data) {
      cb(Map<String, dynamic>.from(data));
    });
  }

  void onCallRejected(Function(Map<String, dynamic>) cb) {
    _socket?.on('call_rejected', (data) {
      cb(Map<String, dynamic>.from(data));
    });
  }

  void onCallRinging(Function(Map<String, dynamic>) cb) {
    _socket?.on('call_ringing', (data) {
      cb(Map<String, dynamic>.from(data));
    });
  }

  void onCallEnded(Function() cb) {
    _socket?.on('call_ended', (_) => cb());
  }

  void offAll() {
    _socket?.off('call_incoming');
    _socket?.off('call_accepted');
    _socket?.off('call_rejected');
    _socket?.off('call_ringing');
    _socket?.off('call_ended');
  }
}