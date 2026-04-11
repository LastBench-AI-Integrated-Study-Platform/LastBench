import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class ProfileService {
  static String get baseUrl => AppConfig.apiBaseUrl;

  static Future<Map<String, dynamic>> getProfile(String email) async {
    final uri = Uri.parse('$baseUrl/auth/profile?email=$email');
    final res = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (res.statusCode != 200) {
      throw jsonDecode(res.body)["detail"] ?? 'Could not load profile';
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<String> updateProfile({
    required String email,
    String? name,
    String? bio,
    String? education,
    String? internship,
    String? job,
    String? skills,
    String? profileImageBase64,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/profile');
    final body = {
      'email': email,
      'name': name,
      'bio': bio,
      'education': education,
      'internship': internship,
      'job': job,
      'skills': skills,
      'profile_image_base64': profileImageBase64,
    };

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode != 200) {
      throw data["detail"] ?? 'Could not update profile';
    }

    return data["message"] as String? ?? 'Profile updated';
  }
}
