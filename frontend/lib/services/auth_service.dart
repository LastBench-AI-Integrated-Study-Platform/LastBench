import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class AuthService {
  static String get baseUrl => AppConfig.apiBaseUrl;

  static String? _cachedEmail;
  static String? _cachedName;

  // ── Save/Get email from SharedPreferences ──────────────────────────────────
  static Future<void> saveUserEmail(String email, [String? name]) async {
    _cachedEmail = email;
    if (name != null) {
      _cachedName = name;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lb_user_email', email);
    if (name != null) {
      await prefs.setString('lb_user_name', name);
    }
  }

  static Future<String?> getUserEmail() async {
    if (_cachedEmail != null) return _cachedEmail;
    final prefs = await SharedPreferences.getInstance();
    _cachedEmail = prefs.getString('lb_user_email');
    return _cachedEmail;
  }

  // Synchronous access - works better after first getUserEmail() call or login
  static String? get currentUserEmail => _cachedEmail;

  static Future<String?> getUserName() async {
    if (_cachedName != null) return _cachedName;
    final prefs = await SharedPreferences.getInstance();
    _cachedName = prefs.getString('lb_user_name');
    return _cachedName;
  }
  
  static String? get currentUserName => _cachedName;

  // ── Signup ────────────────────────────────────────────────────────────────
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
    if (res.statusCode != 200) throw data["detail"];
    await saveUserEmail(email, name); // ✅ save email and name
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
  print("LOGIN RESPONSE: $data"); // 🔍 DEBUG

  if (res.statusCode != 200) {
    throw data["detail"] ?? "Login failed";
  }

  // ✅ SAFE access
  final user = data["user"] ?? {};
  _cachedEmail = email;
  _cachedName = user["name"];

  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('lb_user_email', email);
  await prefs.setString('lb_user_name', user["name"] ?? '');
  await prefs.setString('lb_user_id', user["_id"] ?? '');
  await prefs.setString('lb_user_username', user["username"] ?? '');

  return data;
}

  /// Logout user by clearing storage
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('lb_user_email');
    await prefs.remove('lb_user_name');
    await prefs.remove('lb_user_id');
    await prefs.remove('lb_user_username');
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
