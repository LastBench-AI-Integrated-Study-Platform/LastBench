import 'package:flutter/material.dart';

class ChatHomePage extends StatefulWidget {
  const ChatHomePage({Key? key}) : super(key: key);

  @override
  State<ChatHomePage> createState() => _ChatHomePageState();
}

class _ChatHomePageState extends State<ChatHomePage> {
  bool isGroupsSelected = true;

  final TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  final Color primaryDark = const Color(0xFF0E3B5B);
  final Color teal = const Color(0xFF3F8F8B);
  final Color bgColor = const Color(0xFFF5F6F7);

  final List<Map<String, dynamic>> groups = [
    {"initials": "DT", "name": "Design Team", "active": 8},
    {"initials": "PN", "name": "Project Nexus", "active": 5},
    {"initials": "MS", "name": "Marketing Sync", "active": 12},
  ];

  final List<Map<String, dynamic>> personalChats = [
    {
      "name": "Arjun",
      "message": "Did you complete the task?",
      "time": "9:30 AM"
    },
    {
      "name": "Meera",
      "message": "Let's meet after class",
      "time": "Yesterday"
    },
    {
      "name": "Kavin",
      "message": "Send the notes pls",
      "time": "Mon"
    },
  ];

  int getTotalActive() {
    return groups.fold(0, (sum, item) => sum + (item["active"] as int));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 10),

              /// Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "LastBench",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: primaryDark,
                    ),
                  ),
                  Row(
                    children: [
                      _buildToggle(),
                      const SizedBox(width: 8),
                      if (isGroupsSelected) _buildPopupMenu(),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 25),

              /// Search Bar
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF1F4),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toLowerCase();
                    });
                  },
                  decoration: const InputDecoration(
                    prefixIcon:
                        Icon(Icons.search, color: Colors.grey, size: 22),
                    hintText: "Search chats...",
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child:
                      isGroupsSelected ? _buildGroupsGrid() : _buildPersonalList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupsGrid() {
    final filteredGroups = groups.where((group) {
      return group["name"]
          .toString()
          .toLowerCase()
          .contains(searchQuery);
    }).toList();

    if (filteredGroups.isEmpty) {
      return const Center(
        child: Text(
          "No groups found",
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return GridView.builder(
      itemCount: filteredGroups.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final group = filteredGroups[index];

        return _buildGroupCard(
          group["initials"],
          group["name"],
          group["active"],
        );
      },
    );
  }

  Widget _buildPersonalList() {
    final filteredChats = personalChats.where((chat) {
      return chat["name"]
              .toString()
              .toLowerCase()
              .contains(searchQuery) ||
          chat["message"]
              .toString()
              .toLowerCase()
              .contains(searchQuery);
    }).toList();

    if (filteredChats.isEmpty) {
      return const Center(
        child: Text(
          "No chats found",
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.separated(
      itemCount: filteredChats.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final chat = filteredChats[index];

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E6EA)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: teal,
                child: Text(
                  chat["name"][0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat["name"],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chat["message"],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Text(
                chat["time"],
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToggle() {
    return Container(
      height: 42,
      width: 180,
      decoration: BoxDecoration(
        color: const Color(0xFFE9ECEF),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutCubic,
            alignment:
                isGroupsSelected ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              width: 90,
              height: 42,
              decoration: BoxDecoration(
                color: primaryDark,
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      isGroupsSelected = true;
                      searchController.clear();
                      searchQuery = "";
                    });
                  },
                  child: Center(
                    child: Text(
                      "Groups",
                      style: TextStyle(
                        color:
                            isGroupsSelected ? Colors.white : Colors.grey[700],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      isGroupsSelected = false;
                      searchController.clear();
                      searchQuery = "";
                    });
                  },
                  child: Center(
                    child: Text(
                      "Personal",
                      style: TextStyle(
                        color:
                            !isGroupsSelected ? Colors.white : Colors.grey[700],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPopupMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) => const [
        PopupMenuItem(
          child: Row(
            children: [
              Icon(Icons.add),
              SizedBox(width: 10),
              Text("Create Group"),
            ],
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          child: Row(
            children: [
              Icon(Icons.group_add),
              SizedBox(width: 10),
              Text("Join Group"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGroupCard(String initials, String name, int active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E6EA)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: teal,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0E3B5B),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.group_outlined,
                  size: 16, color: Color(0xFF3F8F8B)),
              const SizedBox(width: 6),
              Text(
                "$active active",
                style: const TextStyle(color: Color(0xFF3F8F8B)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}