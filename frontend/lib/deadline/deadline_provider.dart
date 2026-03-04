import 'package:flutter/material.dart';

class DeadlineProvider extends ChangeNotifier {
  final List<String> deadlines = [];

  void addDeadline(String d) {
    deadlines.add(d);
    notifyListeners();
  }
}