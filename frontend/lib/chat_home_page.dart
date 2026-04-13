import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/chat_service.dart';
import 'services/websocket_service.dart';
import 'services/auth_service.dart';
import 'personal_chat_page.dart';
import 'group_chat_page.dart';

class ChatHomePage extends StatefulWidget {
  const ChatHomePage({super.key});

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

  List<Map<String, dynamic>> groups = [];
  List<Map<String, dynamic>> personalChats = [];
  bool isLoading = true;
  StreamSubscription? _wsSubscription;

  @override
  void initState() {
    super.initState();
    _fetchData();
    WebSocketService().connect();
    _wsSubscription = WebSocketService().messageStream.listen((event) {
      // Whenever we get a web socket event, silently update our unread counts and latest messages
      _fetchDataSilently();
    });
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDataSilently() async {
    try {
      final fetchedGroups = await ChatService.getGroups();
      final fetchedChats = await ChatService.getPersonalChats();
      
      if (mounted) {
        setState(() {
          groups = fetchedGroups;
          personalChats = fetchedChats;
        });
      }
    } catch (e) {
      // Ignore errors during silent background polling
    }
  }

  Future<void> _fetchData() async {
    try {
      final fetchedGroups = await ChatService.getGroups();
      final fetchedChats = await ChatService.getPersonalChats();
      
      if (mounted) {
        setState(() {
          groups = fetchedGroups;
          personalChats = fetchedChats;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading chats: $e')),
        );
      }
    }
  }

  int getTotalActive() {
    return groups.fold(0, (sum, item) => sum + (item["active"] as int));
  }

  String _formatChatListTime(String isoString) {
    if (isoString.isEmpty || isoString == "Now") return "Now";
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final dateToCheck = DateTime(dateTime.year, dateTime.month, dateTime.day);

      if (dateToCheck == today) {
        return DateFormat('hh:mm a').format(dateTime);
      } else if (dateToCheck == yesterday) {
        return "Yesterday";
      } else {
        return DateFormat('dd/MM/yyyy').format(dateTime);
      }
    } catch (e) {
      // Fallback if parsing fails (e.g. if it was just returning HH:MM format)
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: !isGroupsSelected
          ? FloatingActionButton(
              onPressed: _showSearchUserDialog,
              backgroundColor: primaryDark,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
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
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: isGroupsSelected
                            ? _buildGroupsGrid()
                            : _buildPersonalList(),
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

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GroupChatPage(
                  groupId: group["id"],
                  groupName: group["name"],
                ),
              ),
            ).then((_) {
              if (mounted) _fetchData();
            });
          },
          child: _buildGroupCard(
  group["id"],
  group["initials"],
  group["name"],
  group["active"],
  group["unread_count"] ?? 0,
)
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

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PersonalChatPage(
                  partnerName: chat["name"],
                  partnerEmail: chat["email"],
                ),
              ),
            ).then((_) {
              if (mounted) {
                _fetchData();
              }
            });
          },
          child: Container(
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatChatListTime(chat["timestamp"] ?? chat["time"] ?? ""),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (chat["unread_count"] != null && chat["unread_count"] > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: teal,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            chat["unread_count"].toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
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
      onSelected: (value) {
        if (value == 'create') {
          _showCreateGroupDialog();
        } else if (value == 'join') {
          _showJoinGroupDialog();
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'create',
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
          value: 'join',
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

  Widget _buildGroupCard(String groupId, String initials, String name, int active, int unreadCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: unreadCount > 0 
            ? Border.all(color: teal, width: 3.0) 
            : Border.all(color: const Color(0xFFE2E6EA)),
        boxShadow: unreadCount > 0 
            ? [BoxShadow(color: teal.withOpacity(0.2), blurRadius: 8, spreadRadius: 1)]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
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
              if (unreadCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unreadCount > 99 ? "99+" : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
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
          GestureDetector(
            onTap: () {
              _showMembersDialog(groupId);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.group_outlined, size: 16, color: Color(0xFF3F8F8B)),
                const SizedBox(width: 6),
                Text(
                  "$active members",
                  style: const TextStyle(color: Color(0xFF3F8F8B)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "ID: $groupId",
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[400],
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
void _showMembersDialog(String groupName) async {
  try {
    final members = await ChatService.getGroupMembers(groupName);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: teal,
                  child: Text(
                    member["name"][0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(member["name"]),
                subtitle: Text(member["email"]),
              );
            },
          ),
        );
      },
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error loading members: $e")),
    );
  }
}
  void _showSearchUserDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _SearchUserSheet(
          onUserSelected: (user) {
            setState(() {
              final exists = personalChats.any((c) => c['email'] == user['email']);
              if (!exists) {
                personalChats.insert(0, {
                  "name": user["name"],
                  "email": user["email"],
                  "message": "Start a conversation",
                  "time": "Now"
                });
              }
            });
            
            // Navigate to personal chat screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PersonalChatPage(
                  partnerName: user["name"],
                  partnerEmail: user["email"],
                ),
              ),
            ).then((_) {
              if (mounted) {
                _fetchData();
              }
            });
          },
        );
      },
    );
  }

  void _showCreateGroupDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descController = TextEditingController();
    bool isCreating = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Create Group"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Group Name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: "Description (Optional)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isCreating ? null : () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: isCreating
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) return;

                          setDialogState(() => isCreating = true);
                          try {
                            await ChatService.createGroup(
                              name,
                              descController.text.trim(),
                              [AuthService.currentUserEmail ?? ""],
                            );
                            if (mounted) {
                              Navigator.pop(context);
                              _fetchData();
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                            setDialogState(() => isCreating = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: teal),
                  child: isCreating
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Create", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showJoinGroupDialog() {
    final TextEditingController idController = TextEditingController();
    bool isJoining = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Join Group"),
              content: TextField(
                controller: idController,
                decoration: const InputDecoration(
                  labelText: "Paste Group ID",
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isJoining ? null : () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: isJoining
                      ? null
                      : () async {
                          final groupId = idController.text.trim();
                          if (groupId.isEmpty) return;

                          setDialogState(() => isJoining = true);
                          try {
                            await ChatService.joinGroup(groupId);
                            if (mounted) {
                              Navigator.pop(context);
                              _fetchData();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Successfully joined group!')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                            setDialogState(() => isJoining = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: teal),
                  child: isJoining
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Join", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SearchUserSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onUserSelected;
  const _SearchUserSheet({super.key, required this.onUserSelected});

  @override
  State<_SearchUserSheet> createState() => _SearchUserSheetState();
}

class _SearchUserSheetState extends State<_SearchUserSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  void _onSearchChanged(String query) async {
    if (query.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _searchResults = [];
        });
      }
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await ChatService.searchUsers(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
        });
      }
    } catch (e) {
      // ignore
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF1F4),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                autofocus: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search, color: Colors.grey, size: 22),
                  hintText: "Search by username...",
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isSearching)
              const Center(child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ))
            else if (_searchResults.isEmpty && _searchController.text.trim().isNotEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("No users found", style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _searchResults.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final user = _searchResults[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF3F8F8B),
                      child: Text(
                        user["name"][0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(user["name"], style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(user["email"], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onUserSelected(user);
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}