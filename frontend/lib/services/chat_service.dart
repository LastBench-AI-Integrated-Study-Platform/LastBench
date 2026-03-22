import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatService {
  static String get baseUrl => AppConfig.apiBaseUrl;

  /// Get the current user email from SharedPreferences
  static Future<String?> _getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email');
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
}
