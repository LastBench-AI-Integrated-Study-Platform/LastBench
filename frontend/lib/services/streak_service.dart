import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class StreakService {
  static Future<Map<String, dynamic>> getCurrentStreak(String email) async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/auth/streak/current?email=$email'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load streak');
    }
  }

  static Future<Map<String, dynamic>> updateStreak(String email) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/auth/streak/update'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update streak');
    }
  }
}
