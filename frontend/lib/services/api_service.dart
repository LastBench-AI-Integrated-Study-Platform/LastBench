import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // FastAPI runs on 8000, Socket server on 5001
  static const String baseUrl = 'http://192.168.0.116:8000';
  static Future<List<UserModel>> searchUsers(
    String query,
    String currentUserId,
  ) async {
    if (query.trim().isEmpty) return [];
    try {
      final uri = Uri.parse(
        '$baseUrl/call/users/search?q=${Uri.encodeComponent(query)}&current_user_id=$currentUserId',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        return (jsonDecode(res.body) as List)
            .map((e) => UserModel.fromJson(e))
            .toList();
      }
    } catch (e) {
      print('searchUsers error: $e');
    }
    return [];
  }

  static Future<AgoraTokenResponse?> getAgoraToken(
    String channel,
    int uid,
  ) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/call/token'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'channel': channel, 'uid': uid}),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        return AgoraTokenResponse.fromJson(jsonDecode(res.body));
      }
    } catch (e) {
      print('getAgoraToken error: $e');
    }
    return null;
  }
}

class UserModel {
  final String id, username, name, avatar;
  final bool isOnline;

  const UserModel({
    required this.id,
    required this.username,
    required this.name,
    required this.avatar,
    required this.isOnline,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id: j['_id'] ?? '',
    username: j['username'] ?? '',
    name: j['name'] ?? '',
    avatar: j['avatar'] ?? '',
    isOnline: j['isOnline'] ?? false,
  );

  String get initials {
    final p = name.trim().split(' ');
    return p.length >= 2
        ? '${p[0][0]}${p[1][0]}'.toUpperCase()
        : name.isNotEmpty
        ? name[0].toUpperCase()
        : '?';
  }
}

class AgoraTokenResponse {
  final String token, appId, channel;
  const AgoraTokenResponse({
    required this.token,
    required this.appId,
    required this.channel,
  });

  factory AgoraTokenResponse.fromJson(Map<String, dynamic> j) =>
      AgoraTokenResponse(
        token: j['token'] ?? '',
        appId: j['app_id'] ?? '',
        channel: j['channel'] ?? '',
      );
}
