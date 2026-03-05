// frontend/lib/pages/search_user_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/user_session.dart';
import 'outgoing_call_page.dart';

const _navy = Color(0xFF033F63);
const _teal = Color(0xFF379392);

class SearchUserPage extends StatefulWidget {
  const SearchUserPage({super.key});

  @override
  State<SearchUserPage> createState() => _SearchUserPageState();
}

class _SearchUserPageState extends State<SearchUserPage> {
  final _ctrl = TextEditingController();
  List<UserModel> _results = [];
  bool _loading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(q));
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    final res = await ApiService.searchUsers(q.trim(), UserSession().userId);
    print("Current userId: ${UserSession().userId}");
    if (mounted) setState(() { _results = res; _loading = false; });
  }

  void _call(UserModel user, String callType) {
    // unique channel: sorted IDs + timestamp
    final ids = [UserSession().userId, user.id]..sort();
    final channel = '${ids[0]}_${ids[1]}_${DateTime.now().millisecondsSinceEpoch}';

    SocketService().sendCallInvite(
      callerId:       UserSession().userId,
      callerName:     UserSession().name,
      callerInitials: UserSession().initials,
      receiverId:     user.id,
      channel:        channel,
      callType:       callType,
    );

    Navigator.push(context, MaterialPageRoute(
      builder: (_) => OutgoingCallPage(receiver: user, channel: channel, callType: callType),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _navy,
        title: const Text('Find someone to call', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: _navy,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _ctrl,
              onChanged:  _onChanged,
              autofocus:  true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText:  'Search by username...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled:    true,
                fillColor: Colors.white.withOpacity(0.12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Results
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _teal))
                : _results.isEmpty
                    ? Center(
                        child: Text(
                          _ctrl.text.isEmpty
                              ? 'Search for a classmate\nto start a call 📞'
                              : 'No users found for "${_ctrl.text}"',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey, fontSize: 15),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) => _UserTile(
                          user:        _results[i],
                          onAudioCall: () => _call(_results[i], 'audio'),
                          onVideoCall: () => _call(_results[i], 'video'),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserModel   user;
  final VoidCallback onAudioCall, onVideoCall;
  const _UserTile({required this.user, required this.onAudioCall, required this.onVideoCall});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: _teal,
        child: Text(user.initials,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      title: Text(user.name,
          style: const TextStyle(color: _navy, fontWeight: FontWeight.w600)),
      subtitle: Row(children: [
        Container(
          width: 7, height: 7,
          margin: const EdgeInsets.only(right: 5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: user.isOnline ? Colors.green : Colors.grey,
          ),
        ),
        Text(
          '@${user.username}  •  ${user.isOnline ? "Online" : "Offline"}',
          style: TextStyle(
            fontSize: 12,
            color: user.isOnline ? Colors.green.shade700 : Colors.grey,
          ),
        ),
      ]),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.call, color: _teal),
            tooltip: 'Audio call',
            onPressed: user.isOnline ? onAudioCall : null,
          ),
          IconButton(
            icon: const Icon(Icons.videocam, color: _navy),
            tooltip: 'Video call',
            onPressed: user.isOnline ? onVideoCall : null,
          ),
        ],
      ),
    );
  }
}