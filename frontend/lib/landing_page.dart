import 'package:flutter/material.dart';
import 'daily_insights_card.dart';
import 'deadline_tracker_page.dart';

class Brand {
  static const Color navy = Color(0xFF033F63);
  static const Color teal = Color(0xFF379392);
  static const Color muted = Color(0xFF6B7280);
}

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ---------------- APP BAR ----------------
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        toolbarHeight: 80,

        title: Image.asset(
          'lib/assets/Logo.png',
          height: 120,
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            child: const Text(
              "Login",
              style: TextStyle(fontSize: 12, color: Colors.black),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/signup'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Brand.teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Sign Up",
                  style: TextStyle(fontSize: 12, color: Colors.white)),
            ),
          ),
        ],
      ),

      // ---------------- BODY ----------------
      body: SingleChildScrollView(
        child: Column(
          children: const [
            HeroSection(),
            DailyInsightsSection(),
            FeaturesSection(),
            FooterSection(),
          ],
        ),
      ),
    );
  }
}

/* ---------------- SECTIONS ---------------- */

class DailyInsightsSection extends StatelessWidget {
  const DailyInsightsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return DailyInsightsCard();
  }
}

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Image.asset(
            'lib/assets/GroupStudyImage.png',
            height: width > 900 ? 420 : 300,
          ),

          const SizedBox(height: 24),

          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: width > 900 ? 40 : 28,
                fontWeight: FontWeight.w800,
                color: Brand.navy,
              ),
              children: const [
                TextSpan(text: "From the "),
                TextSpan(
                    text: "Last Bench\n",
                    style: TextStyle(color: Brand.teal)),
                TextSpan(text: "to the "),
                TextSpan(
                    text: "Top Rank.",
                    style: TextStyle(color: Brand.teal)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: 720,
            child: Text(
              "Last Bench is a collaborative study platform where students prepare together using notes, PYQs, live rooms and placements.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Brand.muted),
            ),
          ),

          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Brand.teal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DeadlineTrackerPage(),
                    ),
                  );
                },
                child: const Text("Get Started Free", style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: () {},
                child: const Text("Login", style: TextStyle(color: Brand.navy)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    // We define features here since it was missing
    final List<Map<String, dynamic>> features = [
      {
        "icon": Icons.menu_book,
        "title": "Study Material",
        "desc": "Access high-quality notes and PYQs"
      },
      {
        "icon": Icons.groups,
        "title": "Live Study Rooms",
        "desc": "Join study rooms with peers"
      },
      {
        "icon": Icons.help,
        "title": "Doubt Solving",
        "desc": "Get your doubts resolved quickly"
      },
      {
        "icon": Icons.trending_up,
        "title": "Progress Tracking",
        "desc": "Track your study streaks and deadlines"
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            "Everything You Need to Study Smarter",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Brand.navy,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Collaborative tools built for exam success",
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 24),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: features.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.35,
                ),
            itemBuilder: (context, index) {
              final f = features[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(f["icon"], size: 32, color: Brand.teal),
                      const SizedBox(height: 12),
                      Text(
                        f["title"],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Brand.navy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        f["desc"],
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Brand.navy,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: const [
          Text(
            "Last Bench",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "From the Last Bench to the Top Rank.",
            style: TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 16),
          Text(
            "© 2025 Last Bench. All rights reserved.",
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/* ---------------- BUTTONS ---------------- */

class _PrimaryButton extends StatelessWidget {
  final String label;
  const _PrimaryButton({required this.label});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {},
      style:
          ElevatedButton.styleFrom(backgroundColor: Brand.teal),
      child: Text(label,
          style: const TextStyle(color: Colors.white)),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  const _OutlineButton({required this.label});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {},
      child: Text(label,
          style: const TextStyle(color: Colors.black)),
    );
  }
}

/* ---------------- MODEL ---------------- */

class _Feature {
  final IconData icon;
  final String title;
  final String desc;

  const _Feature(this.icon, this.title, this.desc);
}
