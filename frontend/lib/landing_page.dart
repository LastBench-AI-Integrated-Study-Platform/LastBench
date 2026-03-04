import 'package:flutter/material.dart';

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
            FeaturesSection(),
            FooterSection(),
          ],
        ),
      ),
    );
  }
}

/* ---------------- HERO ---------------- */

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

          Wrap(
            spacing: 12,
            children: const [
              _PrimaryButton(label: "Get Started"),
              _OutlineButton(label: "Login"),
            ],
          ),
        ],
      ),
    );
  }
}

/* ---------------- FEATURES ---------------- */

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  static final features = [
    _Feature(Icons.description, "Ask from Notes",
        "Upload PDFs and ask doubts directly."),
    _Feature(Icons.chat, "Group Chat",
        "Discuss exam topics with peers."),
    _Feature(Icons.video_call, "Study Live",
        "Join live study rooms."),
    _Feature(Icons.help_outline, "Ask Doubts",
        "Get help from mentors."),
    _Feature(Icons.emoji_events, "Placement Prep",
        "Practice aptitude & interviews."),
    _Feature(Icons.lightbulb, "Daily Insights",
        "Motivation and shortcuts."),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            "Everything You Need to Study Smarter",
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Brand.navy),
          ),

          const SizedBox(height: 32),

          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: features
                .map((f) => SizedBox(
                      width: width > 900 ? 300 : width,
                      child: FeatureCard(feature: f),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

/* ---------------- FEATURE CARD ---------------- */

class FeatureCard extends StatelessWidget {
  final _Feature feature;
  const FeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(blurRadius: 10, color: Color(0x11000000))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(feature.icon, color: Brand.teal),

          const SizedBox(height: 12),

          Text(feature.title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Brand.navy)),

          const SizedBox(height: 6),

          Text(feature.desc, style: const TextStyle(color: Brand.muted)),
        ],
      ),
    );
  }
}

/* ---------------- FOOTER ---------------- */

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      color: Brand.navy,
      child: const Column(
        children: [
          Text("Last Bench",
              style: TextStyle(color: Colors.white, fontSize: 22)),

          SizedBox(height: 12),

          Text("Back benchers welcome.",
              style: TextStyle(color: Brand.teal)),

          SizedBox(height: 20),

          Text("© 2025 Last Bench",
              style: TextStyle(color: Colors.white60)),
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
