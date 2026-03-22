// frontend/lib/pages/call_contacts_page.dart
// Search for users and initiate an audio or video call.

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/user_session.dart';
import 'outgoing_call_page.dart';

const _navy = Color(0xFF033F63);
const _teal = Color(0xFF379392);

class CallContactsPage extends StatefulWidget {
  const CallContactsPage({super.key});

  @override
  State<CallContactsPage> createState() => _CallContactsPageState();
}

class _CallContactsPageState extends State<CallContactsPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<UserModel> _results = [];
  bool _loading = false;
  String? _error;

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() {
        _results = [];
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await ApiService.searchUsers(q, UserSession().userId);
      if (mounted)
        setState(() {
          _results = users;
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = 'Search failed. Is the server running?';
          _loading = false;
        });
    }
  }

  void _startCall(UserModel user, String callType) {
    final session = UserSession();
    final channel = 'call_${session.userId}_${user.id}';

    // Emit the invite via socket
    SocketService().sendCallInvite(
      callerId: session.userId,
      callerName: session.name,
      callerInitials: session.initials,
      receiverId: user.id,
      channel: channel,
      callType: callType,
    );

    // Navigate to outgoing call page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OutgoingCallPage(
          receiver: user,
          channel: channel,
          callType: callType,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Start a Call',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // ── Search bar ─────────────────────────────────────────────
          Container(
            color: _navy,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => _search(v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by name or username…',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withOpacity(0.12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 20,
                ),
              ),
            ),
          ),

          // ── Results ───────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _teal))
                : _error != null
                ? Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : _results.isEmpty && _searchCtrl.text.isNotEmpty
                ? const Center(
                    child: Text(
                      'No users found',
                      style: TextStyle(color: Colors.black45, fontSize: 16),
                    ),
                  )
                : _results.isEmpty
                ? _emptyState()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: _results.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 76),
                    itemBuilder: (_, i) => _UserTile(
                      user: _results[i],
                      onAudio: () => _startCall(_results[i], 'audio'),
                      onVideo: () => _startCall(_results[i], 'video'),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search, size: 72, color: _teal.withOpacity(0.35)),
          const SizedBox(height: 16),
          const Text(
            'Find a study buddy',
            style: TextStyle(
              color: _navy,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Search by name or username to call them',
            style: TextStyle(color: Colors.black45, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onAudio;
  final VoidCallback onVideo;

  const _UserTile({
    required this.user,
    required this.onAudio,
    required this.onVideo,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: _teal,
            child: Text(
              user.initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Name + username
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '@${user.username}',
                  style: const TextStyle(color: Colors.black45, fontSize: 12),
                ),
              ],
            ),
          ),

          // Online indicator
          if (user.isOnline)
            Container(
              margin: const EdgeInsets.only(right: 10),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF22C55E),
              ),
            ),

          // Audio call button
          _CallIconBtn(
            icon: Icons.call,
            color: _teal,
            tooltip: 'Audio call',
            onTap: onAudio,
          ),
          const SizedBox(width: 8),

          // Video call button
          _CallIconBtn(
            icon: Icons.videocam,
            color: _navy,
            tooltip: 'Video call',
            onTap: onVideo,
          ),
        ],
      ),
    );
  }
}

class _CallIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _CallIconBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}
