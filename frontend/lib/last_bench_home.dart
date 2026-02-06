import 'package:flutter/material.dart';
import 'ask_from_pdf_page.dart';
import 'daily_insights_card.dart';
import 'upload_file_page.dart';
import 'deadline_tracker_page.dart';


class LastBenchHome extends StatefulWidget {
  const LastBenchHome({super.key});

  @override
  State<LastBenchHome> createState() => _LastBenchHomeState();
}

class _LastBenchHomeState extends State<LastBenchHome> {
 
  // Colors
  static const Color navy = Color(0xFF033F63);
  static const Color teal = Color(0xFF379392);

  // Facts
  
  // Quick actions
  final List<Map<String, dynamic>> quickActions = [
    {
      "icon": Icons.menu_book,
      "title": "Ask from PDF",
      "subtitle": "Previous year Qs, notes",
      "color": teal,
    },
    {
      "icon": Icons.chat,
      "title": "Chat with Group",
      "badge": "4",
      "color": navy,
    },
    {
      "icon": Icons.phone,
      "title": "Join Study Call",
      "status": "3 friends studying now",
      "color": teal,
    },
    {
      "icon": Icons.help_outline,
      "title": "Ask a Doubt",
      "subtitle": "Get help from mentors",
      "color": navy,
    },
    {
      "icon": Icons.code,
      "title": "Quiz cards + Flashcards",
      "badge": "New",
      "color": teal,
    },
    {
  "icon": Icons.schedule,
  "title": "Deadline Tracker",
  "subtitle": "Track tasks & exams",
  "color": teal,
},

  ];

  // Study rooms
  final List<Map<String, dynamic>> studyRooms = [
    {
      "name": "Last Bench - OS Revision",
      "exam": "GATE 2025",
      "active": 6,
      "status": "Live",
    },
    {
      "name": "Java Placement Prep",
      "exam": "TCS Ninja",
      "active": 12,
      "status": "Live",
    },
    {
      "name": "CAT Quant Marathon",
      "exam": "CAT 2025",
      "active": 8,
      "status": "Starting in 10 mins",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      floatingActionButton: FloatingActionButton(
        backgroundColor: teal,
        onPressed: () {},
        child: const Icon(Icons.help_outline),
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
              color: navy,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Hey Dude! 👋",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Back bencher today, topper tomorrow 😌",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.local_fire_department, color: Colors.orange),
                        SizedBox(width: 6),
                        Text(
                          "4-day study streak",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Quick Actions
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                "Quick Actions",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: navy,
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: quickActions.map((action) {
                  return Container(
                    width: 150,
                    margin: const EdgeInsets.only(right: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
  if (action["title"] == "Ask from PDF") {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UploadScreen(),
      ),
    );
  } 
  else if (action["title"] == "Quiz cards + Flashcards") {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UploadFileScreen(),
      ),
    );
  } 
  else if (action["title"] == "Deadline Tracker") {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DeadlineTrackerPage(),
      ),
    );
  }
},


                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Icon(
                                action["icon"],
                                color: action["color"],
                                size: 30,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                action["title"],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (action["subtitle"] != null)
                                Text(
                                  action["subtitle"],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              if (action["status"] != null)
                                Text(
                                  action["status"],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: teal,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Daily Insights (Dynamic)
const Padding(
  padding: EdgeInsets.symmetric(horizontal: 16),
  child: DailyInsightsCard(),
),


            // Study Rooms Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "Study Rooms",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: navy,
                    ),
                  ),
                  Text(
                    "View all",
                    style: TextStyle(
                      fontSize: 14,
                      color: teal,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Study Rooms List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: studyRooms.map((room) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          room["name"],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (room["status"] == "Live")
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(
                                              0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Text(
                                            "Live",
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    room["exam"],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.people,
                                        size: 14,
                                        color: Colors.black45,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${room["active"]} studying",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black45,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: teal,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              onPressed: () {},
                              child: const Text("Join"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
