import 'package:flutter/material.dart';
import 'package:last_bench/signup_page.dart';
import 'last_bench_home.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'landing_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LastBenchHome(),
    );
  }
}
