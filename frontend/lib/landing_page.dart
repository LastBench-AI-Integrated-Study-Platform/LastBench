import 'package:flutter/material.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  int currentFactIndex = 0;

  // Brand colors
  static const Color navy = Color(0xFF033F63);
  static const Color teal = Color(0xFF379392);

  final List<Map<String, String>> facts = [
    {
      "type": "Did You Know?",
      "content": "70% of toppers revise PYQs more than new questions."
    },
    {
      "type": "Exam Shortcut",
      "content": "OS Deadlock prevention = break at least 1 Coffman condition."
    },
    {
      "type": "Placement Tip",
      "content": "HR rounds check consistency, not perfection."
    },
    {
      "type": "Motivation",
      "content": "Sitting at the last bench doesn't decide rank. Effort does."
    },
    {
      "type": "Quick Fact",
      "content": "Most asked topic in CN: Flow control & congestion."
    },
  ];

  final List<Map<String, dynamic>> features = [
    {
      "icon": Icons.description,
      "title": "Ask from Notes & PYQs",
      "desc":
          "Upload previous year questions, notes, or PDFs and ask doubts directly.",
    },
    {
      "icon": Icons.chat,
      "title": "Group Chat by Exam",
      "desc":
          "Join exam-specific groups to discuss problems and share resources.",
    },
    {
      "icon": Icons.video_call,
      "title": "Study Together, Live",
      "desc": "Join live study rooms and revise together.",
    },
    {
      "icon": Icons.help_outline,
      "title": "Ask & Answer Doubts",
      "desc": "Post doubts and get help from peers or mentors.",
    },
    {
      "icon": Icons.emoji_events,
      "title": "Placement Preparation",
      "desc":
          "Practice aptitude, technical questions, and interview prep.",
    },
    {
      "icon": Icons.lightbulb,
      "title": "Daily Exam Insights",
      "desc":
          "Get daily exam facts, shortcuts, and motivation.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ---------------- APP BAR ----------------
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          "Last Bench",
          style: TextStyle(
              color: navy, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text(
              "Login",
              style: TextStyle(color: navy),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: teal,
            ),
            onPressed: () {},
            child: const Text("Sign Up"),
          ),
          const SizedBox(width: 12),
        ],
      ),

      // ---------------- BODY ----------------
      body: SingleChildScrollView(
        child: Column(
          children: [

            // ---------------- HERO ----------------
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    "From the Last Bench\nto the Top Rank.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: navy,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "A collaborative study platform where students prepare together for exams and placements.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.black54, fontSize: 16),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: teal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 14),
                        ),
                        onPressed: () {},
                        child: const Text("Get Started Free"),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton(
                        onPressed: () {},
                        child: const Text("Login"),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ---------------- FACT CARD ----------------
            GestureDetector(
              onTap: () {
                setState(() {
                  currentFactIndex =
                      (currentFactIndex + 1) % facts.length;
                });
              },
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: teal,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      facts[currentFactIndex]["type"]!,
                      style:
                          const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      facts[currentFactIndex]["content"]!,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

            // ---------------- FEATURES ----------------
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    "Everything You Need to Study Smarter",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: navy),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Collaborative tools built for exam success",
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 24),

                  GridView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
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
                            borderRadius:
                                BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Icon(f["icon"],
                                  size: 32, color: teal),
                              const SizedBox(height: 12),
                              Text(
                                f["title"],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: navy),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                f["desc"],
                                style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // ---------------- FOOTER ----------------
            Container(
              width: double.infinity,
              color: navy,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: const [
                  Text(
                    "Last Bench",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "From the Last Bench to the Top Rank.",
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "© 2025 Last Bench. All rights reserved.",
                    style: TextStyle(
                        color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
