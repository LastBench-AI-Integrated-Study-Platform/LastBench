import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'services/chat_service.dart';
import 'services/auth_service.dart';
import 'services/websocket_service.dart';
import 'package:intl/intl.dart';

class GroupChatPage extends StatefulWidget {
  final String groupName;
  final String groupId;

  const GroupChatPage({
    super.key,
    required this.groupName,
    required this.groupId,
  });

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  StreamSubscription? _wsSubscription;

  String? editingMessageId; // To track which message is being edited

  final Color primaryDark = const Color(0xFF0E3B5B);
  final Color teal = const Color(0xFF3F8F8B);
  final Color bgColor = const Color(0xFFF5F6F7);

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _wsSubscription = WebSocketService().messageStream.listen((event) {
      if (mounted) {
        _fetchMessagesSilently();
      }
    });
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessagesSilently() async {
    try {
      final msgs = await ChatService.getGroupMessages(widget.groupId);
      if (mounted) {
        final shouldScroll = msgs.length > _messages.length;
        setState(() {
          _messages = msgs;
        });
        if (shouldScroll) {
          _scrollToBottom();
        }
      }
    } catch (e) {
      // Ignore silent fetch errors to avoid spamming snackbars
    }
  }

  Future<void> _fetchMessages() async {
    try {
      final msgs = await ChatService.getGroupMessages(widget.groupId);
      if (mounted) {
        setState(() {
          _messages = msgs;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading messages: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showGroupInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: teal),
            const SizedBox(width: 8),
            const Text("Group Info"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Group Name:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
            Text(widget.groupName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryDark)),
            const SizedBox(height: 16),
            const Text("Group ID:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.groupId,
                      style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy, size: 20, color: teal),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: widget.groupId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Group ID copied to clipboard!")),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Share this ID with others so they can join this group from the 'Join Group' menu.",
              style: TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close", style: TextStyle(color: primaryDark)),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (editingMessageId != null) {
      // Editing Mode
      final msgId = editingMessageId!;
      final newContent = text;
      
      setState(() {
        _messageController.clear();
        editingMessageId = null;
        // Optimistically update the UI
        final index = _messages.indexWhere((m) => m['id'] == msgId);
        if (index != -1) {
          _messages[index]['content'] = newContent;
          _messages[index]['is_edited'] = true;
        }
      });

      try {
        await ChatService.editMessage(
          msgId,
          newContent,
          AuthService.currentUserEmail ?? "",
        );
        _fetchMessages();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to edit message: $e")),
          );
        }
      }
      return;
    }

    _messageController.clear();
    
    // Optimistic UI update
    final email = AuthService.currentUserEmail ?? "";
    setState(() {
      _messages.add({
        "sender_email": email,
        "content": text,
        "timestamp": DateTime.now().toIso8601String(),
      });
    });
    _scrollToBottom();

    try {
      await ChatService.sendGroupMessage(widget.groupId, text);
    // Optionally fetch messages again to sync with DB id/timestamp
    // _fetchMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  void _showMessageOptions(String msgId, String content) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text("Edit Message"),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    editingMessageId = msgId;
                    _messageController.text = content;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("Delete Message", style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  _deleteMessage(msgId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteMessage(String msgId) async {
    // Optimistic delete
    setState(() {
      _messages.removeWhere((m) => m['id'] == msgId);
    });
    try {
      await ChatService.deleteMessage(msgId, AuthService.currentUserEmail ?? "");
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete message: $e")),
        );
        _fetchMessages(); // Re-fetch to restore message if it couldn't be deleted
      }
    }
  }

  String _formatTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      return DateFormat('hh:mm a').format(dateTime);
    } catch (e) {
      return '';
    }
  }

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(date.year, date.month, date.day);

    String dateText;
    if (msgDate == today) {
      dateText = "Today";
    } else if (msgDate == yesterday) {
      dateText = "Yesterday";
    } else {
      dateText = DateFormat('MMM d, yyyy').format(date);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E6EA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        dateText,
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: teal,
              child: Text(
                widget.groupName.isNotEmpty ? widget.groupName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              widget.groupName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.normal,color: Colors.white),
            ),
          ],
        ),
        backgroundColor: primaryDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showGroupInfoDialog,
            tooltip: "Group Info",
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.waving_hand_rounded,
                              size: 64,
                              color: teal.withAlpha(100),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Say Hello to ${widget.groupName}!",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: primaryDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Start a new conversation now.",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg['sender_email'] == AuthService.currentUserEmail;
                          final isEdited = msg['is_edited'] == true;
                          
                          bool showDateSeparator = false;
                          DateTime? currentDateTime;
                          
                          if (msg['timestamp'] != null && msg['timestamp'].toString().isNotEmpty) {
                            try {
                              currentDateTime = DateTime.parse(msg['timestamp']).toLocal();
                              if (index == 0) {
                                showDateSeparator = true;
                              } else {
                                final prevMsg = _messages[index - 1];
                                if (prevMsg['timestamp'] != null && prevMsg['timestamp'].toString().isNotEmpty) {
                                  final prevDateTime = DateTime.parse(prevMsg['timestamp']).toLocal();
                                  if (currentDateTime.year != prevDateTime.year ||
                                      currentDateTime.month != prevDateTime.month ||
                                      currentDateTime.day != prevDateTime.day) {
                                    showDateSeparator = true;
                                  }
                                }
                              }
                            } catch (e) {
                              // ignore
                            }
                          }

                          Widget messageBubble = GestureDetector(
                            onLongPress: isMe ? () => _showMessageOptions(msg['id'], msg['content']) : null,
                            child: _buildMessageBubble(
                              msg['content'] ?? '',
                              msg['timestamp'] ?? '',
                              isMe,
                              isEdited,
                              msg['sender_name'] ?? msg['sender_email'] ?? 'Unknown'
                            ),
                          );

                          if (showDateSeparator && currentDateTime != null) {
                            return Column(
                              children: [
                                _buildDateSeparator(currentDateTime),
                                messageBubble,
                              ],
                            );
                          }

                          return messageBubble;
                        },
                      ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String content, String timestamp, bool isMe, bool isEdited, String senderName) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? teal : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              offset: const Offset(0, 1),
              blurRadius: 3,
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  senderName,
                  style: TextStyle(
                    color: primaryDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            Text(
              content,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(timestamp),
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.black54,
                    fontSize: 10,
                  ),
                ),
                if (isEdited) ...[
                  const SizedBox(width: 4),
                  Text(
                    "(edited)",
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.black54,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Column(
      children: [
        if (editingMessageId != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade200,
            child: Row(
              children: [
                const Icon(Icons.edit, size: 16, color: Colors.black54),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "Editing Message",
                    style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      editingMessageId = null;
                      _messageController.clear();
                    });
                  },
                  child: const Icon(Icons.close, size: 18, color: Colors.black54),
                )
              ],
            ),
          ),
        Container(
          color: Colors.white,
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 10,
            bottom: MediaQuery.of(context).padding.bottom > 0 
               ? MediaQuery.of(context).padding.bottom 
               : 10,
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF1F4),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _messageController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: null,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendMessage,
                child: CircleAvatar(
                  backgroundColor: primaryDark,
                  radius: 24,
                  child: Icon(editingMessageId != null ? Icons.check : Icons.send, color: Colors.white, size: 20),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}