import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'last_bench_home.dart';
import 'deadline_tracker_page.dart';
import 'deadline_provider.dart';
import 'widgets/call_manager.dart';
import 'landing_page.dart';

import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Warm up the AuthService cache
  await AuthService.getUserEmail();
  runApp(const LastBenchApp());
}

class LastBenchApp extends StatelessWidget {
  const LastBenchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Last Bench',
      theme: ThemeData(primaryColor: const Color(0xFF033F63)),

      // 👇 First screen
      initialRoute: '/login',

      routes: {
        '/home': (context) => const LastBenchHome(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/landing': (context) => const LandingPage(),
      },
    );
  }
}
