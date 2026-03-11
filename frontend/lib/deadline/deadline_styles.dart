import 'package:flutter/material.dart';

class DeadlineStyles {
  /// Colors
  static const background = Color(0xFFFFFFFF);
  static const foreground = Color(0xFF033F63);
  static const primary = Color(0xFF033F63);
  static const secondary = Color(0xFF379392);
  static const card = Color(0xFFFFFFFF);
  static const muted = Color(0xFFE8F1F3);

  /// Dark
  static const darkBackground = Color(0xFF0A1F2E);
  static const darkCard = Color(0xFF1A3A47);

  /// Radius
  static const radius = 10.0;

  /// ✅ Use getter instead of static field
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black12,
          )
        ],
      );
}