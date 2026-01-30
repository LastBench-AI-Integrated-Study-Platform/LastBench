import 'package:flutter/material.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'last_bench_home.dart';


void main() {
  runApp(const LastBenchApp());
}

class LastBenchApp extends StatelessWidget {
  const LastBenchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Last Bench',
      theme: ThemeData(
        primaryColor: const Color(0xFF033F63),
      ),

      // 👇 First screen
      initialRoute: '/home',

      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/home': (context) => const LastBenchHome(),
      },
    );
  }
}
