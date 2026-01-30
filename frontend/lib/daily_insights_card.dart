import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DailyInsightsCard extends StatefulWidget {
  const DailyInsightsCard({super.key});

  @override
  State<DailyInsightsCard> createState() => _DailyInsightsCardState();
}

class _DailyInsightsCardState extends State<DailyInsightsCard> {
  String insightTitle = "Study Boost";
  String insightText = "Loading...";
  bool isLoading = false;

  Future<void> fetchInsight() async {
    if (isLoading) return;

    setState(() => isLoading = true);

    try {
      final url = Uri.parse("http://127.0.0.1:8000/insights/daily");
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          insightText = data["insight"] ?? "No insight found";
        });
      } else {
        setState(() {
          insightText = "Failed to load insight 😢";
        });
      }
    } catch (e) {
      setState(() {
        insightText = "Error loading insight 😢";
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchInsight();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: fetchInsight,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF379392),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              insightTitle,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 450),
              transitionBuilder: (child, animation) {
                final slideAnim = Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(animation);

                return SlideTransition(position: slideAnim, child: child);
              },
              child: isLoading
                  ? const Text(
                      "Loading...",
                      key: ValueKey("loading"),
                      style: TextStyle(color: Colors.white),
                    )
                  : Text(
                      insightText,
                      key: ValueKey("insight_text"),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
