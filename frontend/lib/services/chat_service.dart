import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatService {
  static String get baseUrl => AppConfig.apiBaseUrl;

  /// Get the current user email from SharedPreferences
  static Future<String?> _getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('lb_user_email');
  }

  /// Get groups for the current user
  static Future<List<Map<String, dynamic>>> getGroups() async {
    final email = await _getUserEmail();
    if (email == null) return [];

    try {
      final response = await http.get(Uri.parse('$baseUrl/chat/groups?user_email=$email'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['groups']);
      } else {
        throw Exception('Failed to load groups: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting groups: $e');
      return [];
    }
  }

  /// Get personal chats for the current user
  static Future<List<Map<String, dynamic>>> getPersonalChats() async {
    final email = await _getUserEmail();
    if (email == null) return [];

    try {
      final response = await http.get(Uri.parse('$baseUrl/chat/personal?user_email=$email'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['chats']);
      } else {
        throw Exception('Failed to load personal chats: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting personal chats: $e');
      return [];
    }
  }

  /// Create a new group
  static Future<bool> createGroup(String name, String description, List<String> extraMembers) async {
    final email = await _getUserEmail();
    if (email == null) return false;

    // The creator is a member by default
    final members = [email, ...extraMembers];
    
    // Remove duplicates
    final uniqueMembers = members.toSet().toList();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/groups'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'description': description,
          'members': uniqueMembers,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error creating group: $e');
      return false;
    }
  }

  /// Send a message
  static Future<bool> sendMessage(String content, {String? groupId, String? recipientEmail}) async {
    final email = await _getUserEmail();
    if (email == null) return false;

    if (groupId == null && recipientEmail == null) {
      print("Must provide either groupId or recipientEmail");
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/messages'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'sender_email': email,
          'content': content,
          'group_id': groupId,
          'recipient_email': recipientEmail,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/chat/search_users?query=$query'));
      if (res.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(res.body)['users']);
      }
    } catch (e) { print(e); }
    return [];
  }

  static Future<void> joinGroup(String groupId) async {
    final email = await _getUserEmail();
    await http.post(
      Uri.parse('$baseUrl/chat/groups/join'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'group_id': groupId, 'user_email': email}),
    );
  }

  static Future<List<Map<String, dynamic>>> getGroupMembers(String groupName) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/chat/groups/$groupName/members'));
      if (res.statusCode == 200) return List<Map<String,dynamic>>.from(json.decode(res.body)['members']);
    } catch (e) { print(e); }
    return [];
  }

  static Future<List<Map<String, dynamic>>> getPersonalMessages(String partnerEmail) async {
    final email = await _getUserEmail();
    try {
      final res = await http.get(Uri.parse('$baseUrl/chat/messages/personal_history?user_email=$email&partner_email=$partnerEmail'));
      if (res.statusCode == 200) return List<Map<String,dynamic>>.from(json.decode(res.body)['messages']);
    } catch (e) { print(e); }
    return [];
  }

  static Future<List<Map<String, dynamic>>> getGroupMessages(String groupId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/chat/messages/group_history?group_id=$groupId'));
      if (res.statusCode == 200) return List<Map<String,dynamic>>.from(json.decode(res.body)['messages']);
    } catch (e) { print(e); }
    return [];
  }

  static Future<void> editMessage(String msgId, String content, String userEmail) async {
    await http.put(
      Uri.parse('$baseUrl/chat/messages/$msgId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'content': content, 'user_email': userEmail}),
    );
  }

  static Future<void> deleteMessage(String msgId, String userEmail) async {
    await http.delete(
      Uri.parse('$baseUrl/chat/messages/$msgId?user_email=$userEmail'),
    );
  }

  static Future<bool> sendPersonalMessage(String partnerEmail, String text) async {
    return sendMessage(text, recipientEmail: partnerEmail);
  }

  static Future<bool> sendGroupMessage(String groupId, String text) async {
    return sendMessage(text, groupId: groupId);
  }
}
