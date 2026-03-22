import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';
import 'chat_service.dart';
import 'auth_service.dart';
class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  
  // Broadcast stream controller to allow multiple pages to listen to events
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  void connect() {
    final email = AuthService.currentUserEmail;
    if (email == null) return;

    // e.g. ChatService.baseUrl = "http://192.168.0.7:8000"
    // So wsUrl = "ws://192.168.0.7:8000/chat/ws/your@email.com"
    final wsUrl = ChatService.baseUrl.replaceFirst('http', 'ws') + '/chat/ws/$email';
    
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    _channel?.stream.listen(
      (data) {
        try {
          final decoded = jsonDecode(data);
          _messageController.add(decoded);
        } catch (e) {
          // ignore parsing error
        }
      },
      onDone: () {
        // Attempt to reconnect if disconnected prematurely
        Future.delayed(const Duration(seconds: 3), () {
            if (AuthService.currentUserEmail != null) {
               connect();
            }
        });
      },
      onError: (error) {
        // ignore errors
      },
    );
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}
