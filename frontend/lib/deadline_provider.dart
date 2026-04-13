import 'dart:convert';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Deadline {
  final String id;
  final String title;
  final String date;
  String status;

  Deadline({
    required this.id,
    required this.title,
    required this.date,
    this.status = 'pending',
  });
}

class DeadlineProvider extends ChangeNotifier {
  List<Deadline> _deadlines = [];
  final Set<String> _notifiedDeadlines = {};
  bool _isLoading = true;

  List<Deadline> get deadlines => _deadlines;
  Set<String> get notifiedDeadlines => _notifiedDeadlines;
  bool get isLoading => _isLoading;

  static const String _base = 'http://127.0.0.1:8000/deadlines';

  DeadlineProvider() {
    loadFromServer(); // called on app start
  }

  // ── Read email saved by AuthService ──────────────────────────────────────
  String get _userEmail => html.window.localStorage['lb_user_email'] ?? '';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'x-user-email': _userEmail,
  };

  // ── PUBLIC: call this after login to reload deadlines ─────────────────────
  Future<void> loadFromServer() async {
    _isLoading = true;
    notifyListeners();

    if (_userEmail.isEmpty) {
      debugPrint('=== No email in localStorage — not logged in');
      _isLoading = false;
      notifyListeners();
      return;
    }

    debugPrint('=== Fetching deadlines for: $_userEmail');

    try {
      final res = await http.get(Uri.parse('$_base/'), headers: _headers);
      debugPrint('=== GET /deadlines status: ${res.statusCode}');
      debugPrint('=== Response: ${res.body}');

      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        _deadlines = list
            .map(
              (e) => Deadline(
                id: e['id'],
                title: e['title'],
                date: e['date'],
                status: e['status'] ?? 'pending',
              ),
            )
            .toList();
        debugPrint('=== Loaded ${_deadlines.length} deadlines ✅');
      }
    } catch (e) {
      debugPrint('=== LOAD ERROR: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── ADD ───────────────────────────────────────────────────────────────────
  Future<void> addDeadline(String title, String date) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/'),
        headers: _headers,
        body: jsonEncode({'title': title, 'date': date}),
      );
      if (res.statusCode == 201) {
        final e = jsonDecode(res.body);
        _deadlines.add(
          Deadline(
            id: e['id'],
            title: e['title'],
            date: e['date'],
            status: e['status'] ?? 'pending',
          ),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('=== ADD ERROR: $e');
    }
  }

  // ── UPDATE STATUS ─────────────────────────────────────────────────────────
  Future<void> updateDeadlineStatus(String id, String status) async {
    final index = _deadlines.indexWhere((d) => d.id == id);
    if (index == -1) return;
    _deadlines[index].status = status;
    notifyListeners();
    try {
      await http.patch(
        Uri.parse('$_base/$id/status'),
        headers: _headers,
        body: jsonEncode({'status': status}),
      );
    } catch (e) {
      debugPrint('=== UPDATE ERROR: $e');
    }
  }

  // ── DELETE ────────────────────────────────────────────────────────────────
  Future<void> deleteDeadline(String id) async {
    _deadlines.removeWhere((d) => d.id == id);
    notifyListeners();
    try {
      await http.delete(Uri.parse('$_base/$id'), headers: _headers);
    } catch (e) {
      debugPrint('=== DELETE ERROR: $e');
    }
  }

  // ── MARK NOTIFIED ─────────────────────────────────────────────────────────
  void markAsNotified(String id) => _notifiedDeadlines.add(id);
}
