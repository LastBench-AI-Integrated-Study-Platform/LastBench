import 'package:flutter/material.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});
 
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const _Navbar(),
      body: SingleChildScrollView(
        child: Center(
        child: Column(
          children: const [
            HeroSection(),
            FeaturesSection(),
            FooterSection(),
          ],
        ),)
      ),
    );
  }
}

/* -------------------- BRAND -------------------- */
class Brand {
  static const navy = Color(0xFF033F63);
  static const teal = Color(0xFF379392);
  static const muted = Color(0xFF6B7280);
  static const bgSoft = Color(0xFFF9FAFB);
}

class _Navbar extends StatelessWidget implements PreferredSizeWidget {
  const _Navbar();

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 1,
      toolbarHeight: 80,

      title: Align(
        alignment: Alignment.centerLeft,
        child: Image.asset(
          'lib/assets/Logo.png',
          height: 140,
          fit: BoxFit.contain,
        ),
      ),

      actions: [
        TextButton(
          onPressed: () {
  Navigator.pushNamed(context, '/login');
},

          child: const Text(
            "Login",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w500,
              letterSpacing : 1.05,
              fontSize : 12,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: ElevatedButton(
            onPressed: () {
  Navigator.pushNamed(context, '/signup');
},

            style: ElevatedButton.styleFrom(
              backgroundColor: Brand.teal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
            ),
            child: const Text(
              "Sign Up",
              style: TextStyle(
                fontSize : 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                letterSpacing : 1.05,
              ),
            ),
          ),
        ),
      ],
    );
  }
}


/* -------------------- HERO -------------------- */
class HeroSection extends StatelessWidget {
  const HeroSection({super.key});
  
  @override
  Widget build(BuildContext context) {
     final width = MediaQuery.of(context).size.width;
    return Padding(
      
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1900),
        child: Column(
          children: [
            Image.asset(
              'lib/assets/GroupStudyImage.png',
              height: MediaQuery.of(context).size.width > 1200 ? 420 : 320,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 28),
           RichText(
  textAlign: TextAlign.center,
  text: TextSpan(
    style: TextStyle(
      fontSize: width > 900 ? 42 : 30,
      fontWeight: FontWeight.w800,
      color: Brand.navy,
      height: 1.15,
    ),
    children: const [
      TextSpan(text: "From the "),
      TextSpan(
        text: "Last Bench\n",
        style: TextStyle(color: Brand.teal),
      ),
      TextSpan(text: "to the "),
      TextSpan(
        text: "Top Rank.",
        style: TextStyle(color: Brand.teal),
      ),
    ],
  ),
),

            const SizedBox(height: 20),
            SizedBox(
              width: 720,
              child: Text(
                "Last Bench is a collaborative study platform where students preparing for the same exam come together to solve previous questions, ask doubts from PDFs using AI, chat, join study calls, and prepare for placements — all in one focused space.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: width > 900 ? 16 : 12,
                  color: Brand.muted,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                _PrimaryButton(label: "Get Started Free"),
                _OutlineButton(label: "Login"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------- FEATURES -------------------- */
class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  static final features = [
    _Feature(Icons.description, "Ask from Notes & PYQs",
        "Upload previous year questions, notes, or PDFs and ask doubts directly."),
    _Feature(Icons.chat_bubble_outline, "Group Chat by Exam",
        "Join exam-specific groups to discuss problems and share resources."),
    _Feature(Icons.video_call_outlined, "Study Together, Live",
        "Join live audio study rooms to revise or stay accountable."),
    _Feature(Icons.help_outline, "Ask & Answer Doubts",
        "Post doubts anytime and get help from peers or mentors."),
    _Feature(Icons.emoji_events_outlined, "Placement Preparation",
        "Practice aptitude, technical questions, and interview prep."),
    _Feature(Icons.lightbulb_outline, "Daily Exam Insights",
        "Quick facts, shortcuts, and motivation every day."),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final columns = width > 1100 ? 3 : width > 700 ? 2 : 1;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1500),
        child: Column(
          children: [
            RichText(
  text: const TextSpan(
    style: TextStyle(
      fontSize: 25,
      fontWeight: FontWeight.w900,
      color: Brand.navy,
    ),
    children: [
      TextSpan(text: "Everything You Need to "),
      TextSpan(
        text: "Study Smarter",
        style: TextStyle(
          color: Brand.teal,
          fontWeight: FontWeight.w900, // highest possible
          letterSpacing: 0.6,          // makes it feel bolder
        ),
      ),
    ],
  ),
),

            const SizedBox(height: 12),
            const Text(
              "Collaborative tools built specifically for exam preparation and placement success",
              textAlign: TextAlign.center,
              style: TextStyle(color: Brand.muted),
            ),
            const SizedBox(height: 40),
            Wrap(
  spacing: 24,
  runSpacing: 24,
  children: features.map((feature) {
    double cardWidth;

    if (width > 1100) {
      cardWidth = (width - 58) / 3; // 3 columns
    } else if (width > 700) {
      cardWidth = (width - 24) / 2; // 2 columns
    } else {
      cardWidth = width; // 1 column
    }

    return SizedBox(
      width: cardWidth,
      child: FeatureCard(feature: feature),
    );
  }).toList(),
),

          ],
        ),
      ),
    );
  }
}

/* -------------------- FEATURE CARD -------------------- */
class FeatureCard extends StatelessWidget {
  final _Feature feature;
  const FeatureCard({required this.feature});

 @override
Widget build(BuildContext context) {
  return AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          blurRadius: 12,
          color: Color(0x11000000),
        )
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Brand.teal.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                feature.icon,
                color: Brand.teal,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                feature.title,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: Brand.navy,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          feature.desc,
          style: const TextStyle(
            fontSize: 14,
            color: Brand.muted,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 20),
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
      width: double.infinity, // ✅ full width
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF022C3A), // darker top navy
            Color(0xFF033F63), // brand navy
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          // 🔹 Main footer content
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  // Title
                  Text(
                    "Last Bench",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  SizedBox(height: 8),

                  // Divider line
                  SizedBox(
                    width: 260,
                    child: Divider(
                      color: Color(0xFF6FB1B0), // soft teal line
                      thickness: 1,
                    ),
                  ),

                  SizedBox(height: 16),

                  // Description
                  Text(
                    "From the Last Bench to the Top Rank. "
                    "A collaborative study platform for serious students.",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),

                  SizedBox(height: 12),

                  // Highlight line
                  Text(
                    "Back benchers welcome.",
                    style: TextStyle(
                      color: Brand.teal,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),

          // 🔹 Bottom divider
          Container(
            width: double.infinity,
            height: 1,
            color: Colors.white.withOpacity(0.12),
          ),

          const SizedBox(height: 20),

          // 🔹 Copyright
          const Text(
            "© 2025 Last Bench. All rights reserved.",
            style: TextStyle(
              color: Colors.white60,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------- UI HELPERS -------------------- */
class _PrimaryButton extends StatelessWidget {
  final String label;
  const _PrimaryButton({required this.label});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: Brand.teal,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500,color:Colors.white)),
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
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Brand.navy),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/* -------------------- MODEL -------------------- */
class _Feature {
  final IconData icon;
  final String title;
  final String desc;
  const _Feature(this.icon, this.title, this.desc);
}
