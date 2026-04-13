import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'ask_from_pdf_page.dart';
import 'daily_insights_card.dart';
import 'upload_file_page.dart';
import 'deadline_tracker_page.dart';
import 'pages/call_contacts_page.dart';
import 'chat_home_page.dart';
import 'doubt_section.dart';
import 'login_page.dart';
import 'profile_creation_page.dart';
import 'services/streak_service.dart';
import 'services/auth_service.dart';
import 'widgets/streak_calendar_dialog.dart';

class LastBenchHome extends StatefulWidget {
  final String? userName;
  final String? userEmail;
  const LastBenchHome({super.key, this.userName, this.userEmail});

  @override
  State<LastBenchHome> createState() => _LastBenchHomeState();
}

class _LastBenchHomeState extends State<LastBenchHome> {
  // Colors
  static const Color navy = Color(0xFF033F63);
  static const Color teal = Color(0xFF379392);

  // ── Scroll controller + key for Doubts Section ──
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _doubtsSectionKey = GlobalKey();

  // Streak state
  int _currentStreak = 0;
  bool _isStreakLoading = true;

  // Profile state
  String? _profileImageBase64;
  List<String> _studyDates = [];

  String? get currentEmail => widget.userEmail ?? AuthService.currentUserEmail;
  String? get currentUserName => widget.userName ?? AuthService.currentUserName;

  @override
  void initState() {
    super.initState();
    _loadStreak();
    _loadProfileImage();
  }

  Future<void> _loadStreak() async {
    if (currentEmail == null) {
      setState(() => _isStreakLoading = false);
      return;
    }

    try {
      final streakData = await StreakService.getCurrentStreak(
        currentEmail!,
      );
      setState(() {
        _currentStreak = streakData['current_streak'] ?? 0;
        _studyDates = List<String>.from(streakData['study_dates'] ?? []);
        _isStreakLoading = false;
      });
    } catch (e) {
      print('Error loading streak: $e');
      setState(() => _isStreakLoading = false);
    }
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profileImageBase64 = prefs.getString('profile_image_base64');
    });
  }

  Future<void> _updateStreak() async {
    if (currentEmail == null) return;

    try {
      final streakData = await StreakService.updateStreak(currentEmail!);
      setState(() {
        _currentStreak = streakData['current_streak'] ?? 0;
        _studyDates = List<String>.from(streakData['study_dates'] ?? []);
      });
    } catch (e) {
      print('Error updating streak: $e');
    }
  }

  void _scrollToDoubts() {
    final ctx = _doubtsSectionKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await AuthService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  Widget _buildProfileIcon() {
    if (_profileImageBase64 != null && _profileImageBase64!.isNotEmpty) {
      try {
        // Handle data URI prefixes if accidentally stored
        String base64Str = _profileImageBase64!;
        if (base64Str.contains(',')) {
          base64Str = base64Str.split(',').last;
        }
        final bytes = base64Decode(base64Str);
        return CircleAvatar(
          radius: 20,
          backgroundImage: MemoryImage(Uint8List.fromList(bytes)),
        );
      } catch (e) {
        return const Icon(Icons.account_circle, color: Colors.white, size: 32);
      }
    } else {
      return const Icon(Icons.account_circle, color: Colors.white, size: 32);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
      "subtitle": "Discuss topics and share ideas",
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
        onPressed: _scrollToDoubts,
        child: const Icon(Icons.help_outline),
      ),

      body: SingleChildScrollView(
        controller: _scrollController, // ← attached
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Greeting ─────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              color: navy,
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hey ${currentUserName ?? 'Student'}! 👋",
                        style: const TextStyle(
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
                      GestureDetector(
                        onTap: () {
                          if (!_isStreakLoading) {
                            showDialog(
                              context: context,
                              builder: (context) => StreakCalendarDialog(
                                studyDates: _studyDates,
                                currentStreak: _currentStreak,
                              ),
                            );
                          }
                        },
                        child: Container(
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
                            children: [
                              const Icon(
                                Icons.local_fire_department,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 6),
                              _isStreakLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      _currentStreak == 0
                                          ? "Start your streak!"
                                          : "${_currentStreak}-day study streak",
                                      style: const TextStyle(color: Colors.white),
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PopupMenuButton<String>(
                          onSelected: (String value) {
                            if (value == 'create_profile') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProfileCreationPage(
                                    userEmail: currentEmail,
                                  ),
                                ),
                              ).then((_) => _loadProfileImage());
                            } else if (value == 'view_edit_profile') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProfileCreationPage(
                                    userEmail: currentEmail,
                                    isEditing: true,
                                  ),
                                ),
                              ).then((_) => _loadProfileImage());
                            } else if (value == 'logout') {
                              // Clear user data and navigate to login
                              _logout();
                            }
                          },
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<String>>[
                                const PopupMenuItem<String>(
                                  value: 'create_profile',
                                  child: Text('Create Profile'),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'view_edit_profile',
                                  child: Text('View and Edit Profile'),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'logout',
                                  child: Text('Logout'),
                                ),
                              ],
                          icon: _buildProfileIcon(),
                        ),
                        IconButton(
                          icon: const Icon(Icons.power_settings_new, color: Colors.white, size: 26),
                          onPressed: _logout,
                          tooltip: 'Logout',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Quick Actions ─────────────────────────────────────────────
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
                          ).then((_) => _updateStreak());
                        } else if (action["title"] ==
                            "Quiz cards + Flashcards") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UploadFileScreen(),
                            ),
                          ).then((_) => _updateStreak());
                        } else if (action["title"] == "Deadline Tracker") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DeadlineTrackerPage(),
                            ),
                          );
                        } else if (action["title"] == "Chat with Group") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ChatHomePage(),
                            ),
                          );
                        } else if (action["title"] == "Ask a Doubt") {
                          // ← scroll to doubts section
                          _scrollToDoubts();
                        } else if (action["title"] == "Join Study Call") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CallContactsPage(),
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

            // ── Study Rooms List ──────────────────────────────────────────
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
                              child: const Text(
                                "Join",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // ── Doubts Section ────────────────────────────────────────────
            Padding(
              key: _doubtsSectionKey, // ← GlobalKey attached here
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: const DoubtsSection(),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
