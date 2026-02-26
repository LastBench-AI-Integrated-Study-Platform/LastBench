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
      body: jsonEncode({"email": email, "password": password}),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode != 200) {
      throw data["detail"];
    }
    return data;
  }

  /// Request an OTP to be sent to the user's email.
  /// Returns the backend response which may include 'sent' and 'otp' (dev only).
  static Future<Map<String, dynamic>> requestOtp({
    required String email,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/auth/reset_password/request"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode != 200) {
      throw data["detail"] ?? "Failed to request OTP";
    }
    return data;
  }

  /// Verify a previously sent OTP.
  static Future<void> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/auth/reset_password/verify"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "otp": otp}),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode != 200) {
      throw data["detail"] ?? "OTP verification failed";
    }
  }

  /// Reset password using OTP and email.
  static Future<String> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/auth/reset_password"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "otp": otp,
        "new_password": newPassword,
      }),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode != 200) {
      throw data["detail"] ?? "Password reset failed";
    }
    return data["message"] as String;
  }
}
