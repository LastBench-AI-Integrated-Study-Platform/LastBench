import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
static const String baseUrl = "http://127.0.0.1:8000";

  static Future<String> signup({
    required String name,
    required String email,
    required String password,
    required String exam,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/auth/signup"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password,
        "exam": exam,
      }),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode != 200) {
      throw data["detail"];
    }
    return data["message"];
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode != 200) {
      throw data["detail"];
    }
    return data;
  }
}
