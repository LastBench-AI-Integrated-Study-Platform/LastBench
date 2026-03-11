import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'services/auth_service.dart';

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
    _load();
  }

  // ── user email saved by AuthService after login ───────────────────────────
  String get _userEmail => AuthService.getUserEmail() ?? '';

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-User-Email': _userEmail, // send email as identifier
      };

  // ── LOAD from MongoDB ─────────────────────────────────────────────────────
  Future<void> _load() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await http.get(Uri.parse('$_base/'), headers: _headers);
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        _deadlines = list.map((e) => Deadline(
          id:     e['id'],
          title:  e['title'],
          date:   e['date'],
          status: e['status'] ?? 'pending',
        )).toList();
      }
    } catch (e) {
      debugPrint('Load error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── ADD ───────────────────────────────────────────────────────────────────
  Future<void> addDeadline(String title, String date) async {
    final res = await http.post(
      Uri.parse('$_base/'),
      headers: _headers,
      body: jsonEncode({'title': title, 'date': date}),
    );
    if (res.statusCode == 201) {
      final e = jsonDecode(res.body);
      _deadlines.add(Deadline(id: e['id'], title: e['title'], date: e['date']));
      notifyListeners();
    }
  }

  // ── UPDATE STATUS ─────────────────────────────────────────────────────────
  Future<void> updateDeadlineStatus(String id, String status) async {
    final index = _deadlines.indexWhere((d) => d.id == id);
    if (index == -1) return;
    _deadlines[index].status = status; // optimistic
    notifyListeners();
    await http.patch(
      Uri.parse('$_base/$id/status'),
      headers: _headers,
      body: jsonEncode({'status': status}),
    );
  }

  // ── DELETE ────────────────────────────────────────────────────────────────
  Future<void> deleteDeadline(String id) async {
    _deadlines.removeWhere((d) => d.id == id); // optimistic
    notifyListeners();
    await http.delete(Uri.parse('$_base/$id'), headers: _headers);
  }

  void markAsNotified(String id) => _notifiedDeadlines.add(id);
}