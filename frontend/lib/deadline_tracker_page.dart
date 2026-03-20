import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'deadline_provider.dart';
import 'dashboard_content.dart';

class DeadlineTrackerPage extends StatelessWidget {
  const DeadlineTrackerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DeadlineProvider(),
      child: const DashboardContent(),
    );
  }
}
