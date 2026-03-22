import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ChatService {
  static const String baseUrl = "http://192.168.0.6:8000";

  static Future<List<Map<String, dynamic>>> getGroups() async {
    final email = AuthService.currentUserEmail;
    if (email == null) return [];

    final response = await http.get(Uri.parse('$baseUrl/chat/groups?user_email=$email'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['groups']);
    } else {
      throw Exception('Failed to load groups');
    }
  }
static Future<List<Map<String, dynamic>>> getGroupMembers(String groupId) async {
  final response = await http.get(
    Uri.parse("$baseUrl/chat/groups/$groupId/members"),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data["members"]);
  } else {
    throw Exception("Failed to load members");
  }
}
  static Future<void> createGroup(String name, String description, List<String> members) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat/groups'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'description': description,
        'members': members,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create group');
    }
  }

  static Future<void> joinGroup(String groupId) async {
    final email = AuthService.currentUserEmail;
    if (email == null) return;

    final response = await http.post(
      Uri.parse('$baseUrl/chat/groups/$groupId/join?user_email=$email'),
    );

    if (response.statusCode != 200 && response.statusCode != 400 && response.statusCode != 404) {
      // Allow specific error codes to be parsed and thrown appropriately if needed,
      // but treat generic failure as exception
      throw Exception('Failed to join group: ${response.body}');
    } else if (response.statusCode == 400 || response.statusCode == 404) {
        final error = jsonDecode(response.body)['detail'];
        throw Exception(error ?? 'Failed to join group');
    }
  }

  static Future<List<Map<String, dynamic>>> getPersonalChats() async {
    final email = AuthService.currentUserEmail;
    if (email == null) return [];

    final response = await http.get(Uri.parse('$baseUrl/chat/personal?user_email=$email'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['chats']);
    } else {
      throw Exception('Failed to load personal chats');
    }
  }
  static Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final email = AuthService.currentUserEmail;
    if (email == null) return [];

    final response = await http.get(Uri.parse('$baseUrl/chat/users/search?query=$query&user_email=$email'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['users']);
    } else {
      throw Exception('Failed to search users');
    }
  }
  static Future<List<Map<String, dynamic>>> getPersonalMessages(String partnerEmail) async {
    final email = AuthService.currentUserEmail;
    if (email == null) return [];

    final response = await http.get(Uri.parse('$baseUrl/chat/personal/messages?user_email=$email&partner_email=$partnerEmail'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['messages']);
    } else {
      throw Exception('Failed to load personal messages');
    }
  }

  static Future<void> sendPersonalMessage(String partnerEmail, String content) async {
    final email = AuthService.currentUserEmail;
    if (email == null) return;

    final response = await http.post(
      Uri.parse('$baseUrl/chat/messages'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'sender_email': email,
        'recipient_email': partnerEmail,
        'content': content,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send message');
    }
  }

  static Future<List<Map<String, dynamic>>> getGroupMessages(String groupId) async {
    final email = AuthService.currentUserEmail;
    if (email == null) return [];

    final response = await http.get(Uri.parse('$baseUrl/chat/groups/$groupId/messages?user_email=$email'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['messages']);
    } else {
      throw Exception('Failed to load group messages');
    }
  }

  static Future<void> sendGroupMessage(String groupId, String content) async {
    final email = AuthService.currentUserEmail;
    if (email == null) return;

    final response = await http.post(
      Uri.parse('$baseUrl/chat/messages'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'sender_email': email,
        'group_id': groupId,
        'content': content,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send group message');
    }
  }

  static Future<void> editMessage(String messageId, String newContent, String userEmail) async {
    final res = await http.put(
      Uri.parse("$baseUrl/chat/messages/$messageId?email=$userEmail"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"content": newContent}),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to edit message');
    }
  }

  static Future<void> deleteMessage(String messageId, String userEmail) async {
    final res = await http.delete(
      Uri.parse("$baseUrl/chat/messages/$messageId?email=$userEmail"),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to delete message');
    }
  }
}
