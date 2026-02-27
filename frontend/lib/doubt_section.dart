// doubts_section.dart
// Full backend integration with MongoDB
// Displays doubts from database and stores all operations

// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/doubt_api_service.dart';

// ─── Colour Palette ───────────────────────────────────────────────────────────
const Color kBackground = Color(0xFFF5FAFA);
const Color kForeground = Color(0xFF2A3535);
const Color kPrimary = Color(0xFF3A9B9B);
const Color kPrimaryForeground = Color(0xFFFFFFFF);
const Color kCard = Color(0xFFFFFFFF);
const Color kMuted = Color(0xFFF0F5F5);
const Color kMutedForeground = Color(0xFF6B8080);
const Color kSecondary = Color(0xFFF0F5F5);
const Color kSecondaryForeground = Color(0xFF3D5252);
const Color kBorder = Color(0xFFDCE8E8);
const Color kAccent = Color(0xFF2E8888);
const double kRadius = 10.0;

// ─── Web image picker (dart:html, no package) ─────────────────────────────────
Future<Uint8List?> pickImageFromWeb() async {
  final completer = Completer<Uint8List?>();

  final input = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..click();

  input.onChange.listen((event) {
    final file = input.files?.first;
    if (file == null) {
      completer.complete(null);
      return;
    }
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    reader.onLoadEnd.listen((_) {
      final result = reader.result;
      if (result is ByteBuffer) {
        completer.complete(result.asUint8List());
      } else if (result is Uint8List) {
        completer.complete(result);
      } else {
        completer.complete(null);
      }
    });
  });

  input.onAbort.listen((_) => completer.complete(null));

  return completer.future;
}

// ─── User helpers ───────────────────────────────────────────────────────────
Future<String> _loadUserName() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name') ?? 'You';
  } catch (_) {
    return 'You';
  }
}

String _avatarFromName(String name) {
  if (name.trim().isEmpty) return '??';
  final parts = name.trim().split(RegExp(r"\s+"));
  if (parts.length == 1) {
    return parts[0].substring(0, parts[0].length.clamp(0, 2)).toUpperCase();
  }
  final first = parts[0].isNotEmpty ? parts[0][0] : '';
  final second = parts[1].isNotEmpty ? parts[1][0] : '';
  return (first + second).toUpperCase();
}

// ─── Timestamp formatting helper ─────────────────────────────────────────────
String formatTimestamp(String? iso) {
  if (iso == null || iso.isEmpty) return 'Now';
  try {
    String normalized = iso;
    final hasOffset =
        iso.endsWith('Z') || iso.contains(RegExp(r'[+-]\d{2}:\d{2}'));
    if (!hasOffset) normalized = iso + 'Z';

    final dt = DateTime.parse(normalized).toLocal();
    final dateStr = '${dt.day}/${dt.month}/${dt.year}';
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'pm' : 'am';
    final minute = dt.minute.toString().padLeft(2, '0');
    return 'date: $dateStr time: $hour12:$minute $ampm';
  } catch (_) {
    return iso;
  }
}

// ─── Data Models ─────────────────────────────────────────────────────────────

class Reply {
  final String id;
  final String author;
  final String authorAvatar;
  final String content;
  final String createdAt;
  Reply({
    required this.id,
    required this.author,
    required this.authorAvatar,
    required this.content,
    required this.createdAt,
  });
}

class Comment {
  final String id;
  final String author;
  final String authorAvatar;
  final String content;
  final String createdAt;
  final List<Uint8List> imageBytes;
  final List<Reply> replies;
  Comment({
    required this.id,
    required this.author,
    required this.authorAvatar,
    required this.content,
    required this.createdAt,
    List<Uint8List>? imageBytes,
    List<Reply>? replies,
  }) : imageBytes = imageBytes ?? [],
       replies = replies ?? [];

  bool get hasImage => imageBytes.isNotEmpty;
}

class Doubt {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final List<Uint8List> imageBytes;
  final String author;
  final String authorAvatar;
  final String subject;
  final String createdAt;
  final List<Comment> comments;

  Doubt({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    List<Uint8List>? imageBytes,
    required this.author,
    required this.authorAvatar,
    required this.subject,
    required this.createdAt,
    List<Comment>? comments,
  }) : imageBytes = imageBytes ?? [],
       comments = comments ?? [];

  bool get hasImage => imageBytes.isNotEmpty || imageUrl != null;
}

// ─── Sample Data ──────────────────────────────────────────────────────────────

List<Doubt> initialDoubts = [
  Doubt(
    id: '1',
    title: 'How to solve this integration problem?',
    content:
        "I'm stuck on integrating sin(x)/x from 0 to infinity. Can someone explain the approach using contour integration?",
    author: 'Rahul Sharma',
    authorAvatar: 'RS',
    subject: 'Mathematics',
    createdAt: '2 hours ago',
    comments: [
      Comment(
        id: 'c1',
        author: 'Priya Menon',
        authorAvatar: 'PM',
        content:
            'Use u = x². Then du = 2x dx, integral becomes ∫e^u du = e^(x²) + C.',
        createdAt: '1 hour ago',
        replies: [
          Reply(
            id: 'r1',
            author: 'Rahul Sharma',
            authorAvatar: 'RS',
            content: 'Thank you! That makes perfect sense now.',
            createdAt: '45 min ago',
          ),
        ],
      ),
    ],
  ),
  Doubt(
    id: '2',
    title: 'Difference between Process and Thread in OS?',
    content:
        'For GATE preparation I need a clear conceptual difference between a process and a thread, especially in the context of memory sharing.',
    author: 'Anika Patel',
    authorAvatar: 'AP',
    subject: 'OS',
    createdAt: '4 hours ago',
    comments: [],
  ),
  Doubt(
    id: '3',
    title: 'Java: ArrayList vs LinkedList – when to use which?',
    content:
        'In placement prep they ask about time complexities. When should I prefer LinkedList over ArrayList in Java?',
    author: 'Dev Kumar',
    authorAvatar: 'DK',
    subject: 'DSA',
    createdAt: '1 day ago',
    comments: [
      Comment(
        id: 'c2',
        author: 'Sneha Rao',
        authorAvatar: 'SR',
        content:
            'Use ArrayList for random access O(1). Use LinkedList for frequent insertions/deletions O(1).',
        createdAt: '20 hours ago',
        replies: [],
      ),
    ],
  ),
];

int _idCounter = 100;
String generateId() => (++_idCounter).toString();

// ─── Helper: render image ─────────────────────────────────────────────────────

Widget _buildDoubtImage(DoubtApiModel doubt, {double? height}) {
  final br = BorderRadius.circular(kRadius);
  if (doubt.imageUrls != null && doubt.imageUrls!.isNotEmpty) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: doubt.imageUrls!.length,
      itemBuilder: (ctx, idx) => ClipRRect(
        borderRadius: br,
        child: Image.network(
          'http://localhost:8000/${doubt.imageUrls![idx]}',
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (ctx, error, stackTrace) => Container(
            color: kMuted,
            child: const Icon(Icons.broken_image, color: kMutedForeground),
          ),
        ),
      ),
    );
  }
  return const SizedBox.shrink();
}

// ─── Tab enum ────────────────────────────────────────────────────────────────

enum _DoubtTab { personal, others }

// ─── Main Widget ──────────────────────────────────────────────────────────────

class DoubtsSection extends StatefulWidget {
  const DoubtsSection({super.key});
  @override
  State<DoubtsSection> createState() => _DoubtsSectionState();
}

class _DoubtsSectionState extends State<DoubtsSection> {
  List<DoubtApiModel> _doubts = [];
  bool _isLoading = true;
  bool _isCreating = false;

  String _currentUserName = 'You';
  String _currentUserAvatar = 'YO';

  // ── Toggle & Search state ──
  _DoubtTab _activeTab = _DoubtTab.personal;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDoubts();
    _initializeUser();
    _searchCtrl.addListener(() {
      if (mounted) {
        setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _initializeUser() async {
    final name = await _loadUserName();
    if (mounted) {
      setState(() {
        _currentUserName = name;
        _currentUserAvatar = _avatarFromName(name);
      });
    }
  }

  Future<void> _loadDoubts() async {
    setState(() => _isLoading = true);
    final doubts = await DoubtApiService.getAllDoubts();
    if (mounted) {
      setState(() {
        _doubts = doubts ?? [];
        _isLoading = false;
      });
    }
  }

  /// Returns doubts filtered by active tab and search query.
  List<DoubtApiModel> get _filteredDoubts {
    if (_doubts.isEmpty) return [];

    final currentNameLower = (_currentUserName.isNotEmpty)
        ? _currentUserName.toLowerCase()
        : 'you';

    List<DoubtApiModel> tabFiltered;

    if (_activeTab == _DoubtTab.personal) {
      tabFiltered = _doubts.where((d) {
        final author = (d.author ?? '').toLowerCase().trim();
        return author == currentNameLower || author == 'you';
      }).toList();
    } else {
      tabFiltered = _doubts.where((d) {
        final author = (d.author ?? '').toLowerCase().trim();
        return author != currentNameLower && author != 'you';
      }).toList();
    }

    final query = _searchQuery.trim();
    if (query.isEmpty) return tabFiltered;

    return tabFiltered.where((d) {
      final title = (d.title ?? '').toLowerCase();
      final content = (d.content ?? '').toLowerCase();
      final subject = (d.subject ?? '').toLowerCase();
      final author = (d.author ?? '').toLowerCase();
      return title.contains(query) ||
          content.contains(query) ||
          subject.contains(query) ||
          author.contains(query);
    }).toList();
  }

  void _openNewDoubtDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (ctx) => _NewDoubtDialog(
        onSubmit: (doubt) async {
          setState(() => _isCreating = true);
          await _loadDoubts();
          setState(() => _isCreating = false);
        },
      ),
    );
  }

  void _openDoubtDetail(DoubtApiModel doubt) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _DoubtDetailPage(
          doubt: doubt,
          onUpdated: (updated) {
            _loadDoubts();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredDoubts;

    return Container(
      color: kBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ask Doubts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: kPrimary,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _openNewDoubtDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New Doubt'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: kPrimaryForeground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kRadius),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),

          // ── Toggle tabs ──
          _ToggleTabs(
            activeTab: _activeTab,
            onTabChanged: (tab) => setState(() => _activeTab = tab),
          ),
          const SizedBox(height: 12),

          // ── Search bar ──
          _SearchBar(controller: _searchCtrl),
          const SizedBox(height: 16),

          // ── Content ──
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator(color: kPrimary)),
            )
          else ...[
            ...List.generate(filtered.length, (i) {
              final doubt = filtered[i];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: i < filtered.length - 1 ? 16 : 0,
                ),
                child: _DoubtCard(
                  doubt: doubt,
                  onTap: () => _openDoubtDetail(doubt),
                  currentUserName: _currentUserName,
                  currentUserAvatar: _currentUserAvatar,
                ),
              );
            }),
            if (filtered.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Icon(
                        _searchQuery.isNotEmpty
                            ? Icons.search_off
                            : _activeTab == _DoubtTab.personal
                            ? Icons.person_outline
                            : Icons.group_outlined,
                        size: 40,
                        color: kMutedForeground,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'No doubts match "$_searchQuery"'
                            : _activeTab == _DoubtTab.personal
                            ? 'You haven\'t posted any doubts yet.'
                            : 'No doubts from others yet.',
                        style: const TextStyle(
                          color: kMutedForeground,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ─── Toggle Tabs Widget ───────────────────────────────────────────────────────

class _ToggleTabs extends StatelessWidget {
  final _DoubtTab activeTab;
  final void Function(_DoubtTab) onTabChanged;

  const _ToggleTabs({required this.activeTab, required this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFECF0F0),
        borderRadius: BorderRadius.circular(50),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TabItem(
            label: 'My Doubts',
            icon: Icons.person_outline,
            isActive: activeTab == _DoubtTab.personal,
            onTap: () => onTabChanged(_DoubtTab.personal),
          ),
          _TabItem(
            label: 'Others',
            icon: Icons.group_outlined,
            isActive: activeTab == _DoubtTab.others,
            onTap: () => onTabChanged(_DoubtTab.others),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? kForeground : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive ? Colors.white : kMutedForeground,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? Colors.white : kMutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Search Bar Widget ────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14, color: kForeground),
      decoration: InputDecoration(
        hintText: 'Search doubts by title, subject, or author...',
        hintStyle: const TextStyle(fontSize: 13, color: kMutedForeground),
        prefixIcon: const Icon(Icons.search, size: 20, color: kMutedForeground),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (_, value, __) => value.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: kMutedForeground,
                  ),
                  onPressed: () => controller.clear(),
                )
              : const SizedBox.shrink(),
        ),
        filled: true,
        fillColor: kCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: kBorder, width: 1),
          borderRadius: BorderRadius.circular(kRadius),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: kPrimary, width: 1.5),
          borderRadius: BorderRadius.circular(kRadius),
        ),
      ),
    );
  }
}

// ─── Doubt Card ───────────────────────────────────────────────────────────────

class _DoubtCard extends StatelessWidget {
  final DoubtApiModel doubt;
  final VoidCallback onTap;
  final String currentUserName;
  final String currentUserAvatar;
  const _DoubtCard({
    required this.doubt,
    required this.onTap,
    required this.currentUserName,
    required this.currentUserAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(kRadius),
          border: Border.all(color: kBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Avatar(
              initials: (doubt.authorAvatar ?? '').toUpperCase() == 'YO'
                  ? currentUserAvatar
                  : (doubt.authorAvatar ?? '??'),
              size: 40,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doubt.title ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: kForeground,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${(doubt.author ?? '').toLowerCase() == 'you' ? currentUserName : (doubt.author ?? '')} • ${formatTimestamp(doubt.createdAt)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: kMutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _Badge(label: doubt.subject ?? ''),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    doubt.content ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: kMutedForeground,
                      height: 1.4,
                    ),
                  ),
                  if (doubt.hasImage == true) ...[
                    const SizedBox(height: 12),
                    _buildDoubtImage(doubt, height: 128),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 16,
                        color: kMutedForeground,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${(doubt.comments ?? []).length} answers',
                        style: const TextStyle(
                          fontSize: 13,
                          color: kMutedForeground,
                        ),
                      ),
                    ],
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

// ─── New Doubt Dialog ─────────────────────────────────────────────────────────

class _NewDoubtDialog extends StatefulWidget {
  final void Function(DoubtApiModel?) onSubmit;
  const _NewDoubtDialog({required this.onSubmit});
  @override
  State<_NewDoubtDialog> createState() => _NewDoubtDialogState();
}

class _NewDoubtDialogState extends State<_NewDoubtDialog> {
  final _titleCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  List<Uint8List> _imageBytes = [];
  bool _isPickingImage = false;

  String _currentUserName = 'You';
  String _currentUserAvatar = 'YO';

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    final name = await _loadUserName();
    if (mounted) {
      setState(() {
        _currentUserName = name;
        _currentUserAvatar = _avatarFromName(name);
      });
    }
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);
    try {
      final bytes = await pickImageFromWeb();
      if (bytes != null && mounted) {
        setState(() => _imageBytes.add(bytes));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick image: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  void _removeImage(int index) {
    setState(() => _imageBytes.removeAt(index));
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty || _contentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill title and description')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) =>
          const Center(child: CircularProgressIndicator(color: kPrimary)),
    );

    try {
      List<String> uploadedImageUrls = [];
      if (_imageBytes.isNotEmpty) {
        for (int i = 0; i < _imageBytes.length; i++) {
          final url = await DoubtApiService.uploadImage(
            _imageBytes[i],
            'doubt_image_$i.jpg',
          );
          if (url != null) {
            uploadedImageUrls.add(url);
          }
        }
      }

      final doubt = await DoubtApiService.createDoubt(
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        subject: _subjectCtrl.text.trim().isEmpty
            ? 'General'
            : _subjectCtrl.text.trim(),
        author: _currentUserName,
        authorAvatar: _currentUserAvatar,
        imageUrls: uploadedImageUrls,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }

      if (doubt != null) {
        widget.onSubmit(doubt);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Doubt posted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create doubt'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadius),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ask a New Doubt',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kForeground,
              ),
            ),
            const SizedBox(height: 20),

            const _FormLabel('Title'),
            const SizedBox(height: 8),
            _StyledInput(
              controller: _titleCtrl,
              hint: "What's your question about?",
            ),
            const SizedBox(height: 16),

            const _FormLabel('Subject'),
            const SizedBox(height: 8),
            _StyledInput(
              controller: _subjectCtrl,
              hint: 'e.g., Mathematics, Physics, DSA...',
            ),
            const SizedBox(height: 16),

            const _FormLabel('Description'),
            const SizedBox(height: 8),
            _StyledTextArea(
              controller: _contentCtrl,
              hint: 'Explain your doubt in detail...',
              minLines: 4,
            ),
            const SizedBox(height: 16),

            const _FormLabel('Add Images (optional)'),
            const SizedBox(height: 8),

            Column(
              children: [
                if (_imageBytes.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: kBorder, width: 1.5),
                      borderRadius: BorderRadius.circular(kRadius),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: _imageBytes.length,
                      itemBuilder: (ctx, idx) => Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(kRadius),
                            child: Image.memory(
                              _imageBytes[idx],
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(idx),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.55),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(3),
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_imageBytes.isNotEmpty) const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickImage,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: 96,
                    decoration: BoxDecoration(
                      color: kMuted,
                      borderRadius: BorderRadius.circular(kRadius),
                      border: Border.all(color: kBorder, width: 1.5),
                    ),
                    child: Center(
                      child: _isPickingImage
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: kPrimary,
                              ),
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 28,
                                  color: kMutedForeground,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _imageBytes.isEmpty
                                      ? 'Click to upload images'
                                      : 'Add more images',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: kMutedForeground,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kForeground,
                    side: const BorderSide(color: kBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kRadius),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: kPrimaryForeground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kRadius),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  child: const Text('Post Doubt'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Doubt Detail Page ────────────────────────────────────────────────────────

class _DoubtDetailPage extends StatefulWidget {
  final DoubtApiModel doubt;
  final void Function(DoubtApiModel) onUpdated;
  const _DoubtDetailPage({required this.doubt, required this.onUpdated});
  @override
  State<_DoubtDetailPage> createState() => _DoubtDetailPageState();
}

class _DoubtDetailPageState extends State<_DoubtDetailPage> {
  late DoubtApiModel _doubt;
  final _commentCtrl = TextEditingController();
  List<Uint8List> _commentImageBytes = [];
  bool _isPickingCommentImage = false;
  String? _replyingTo;
  final _replyCtrl = TextEditingController();
  final Set<String> _expandedReplies = {};

  String _currentUserName = 'You';
  String _currentUserAvatar = 'YO';

  @override
  void initState() {
    super.initState();
    _doubt = widget.doubt;
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    final name = await _loadUserName();
    if (mounted) {
      setState(() {
        _currentUserName = name;
        _currentUserAvatar = _avatarFromName(name);
      });
    }
  }

  Future<void> _pickCommentImage() async {
    if (_isPickingCommentImage) return;
    setState(() => _isPickingCommentImage = true);
    try {
      final bytes = await pickImageFromWeb();
      if (bytes != null && mounted) {
        setState(() => _commentImageBytes.add(bytes));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick image: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingCommentImage = false);
    }
  }

  void _removeCommentImage(int index) {
    setState(() => _commentImageBytes.removeAt(index));
  }

  Future<void> _addComment() async {
    if (_commentCtrl.text.trim().isEmpty && _commentImageBytes.isEmpty) return;

    final commentText = _commentCtrl.text.trim();
    final imagesToUpload = List<Uint8List>.from(_commentImageBytes);

    _commentCtrl.clear();
    _commentImageBytes = [];
    setState(() {});

    try {
      List<String> uploadedImageUrls = [];
      for (int i = 0; i < imagesToUpload.length; i++) {
        final url = await DoubtApiService.uploadImage(
          imagesToUpload[i],
          'comment_image_$i.jpg',
        );
        if (url != null) {
          uploadedImageUrls.add(url);
        }
      }

      final comment = await DoubtApiService.addComment(
        widget.doubt.id ?? '',
        author: _currentUserName,
        authorAvatar: _currentUserAvatar,
        content: commentText,
        imageUrls: uploadedImageUrls,
      );

      if (comment != null && mounted) {
        final updated = await DoubtApiService.getDoubtById(
          widget.doubt.id ?? '',
        );
        if (updated != null) {
          setState(() => _doubt = updated);
          widget.onUpdated(_doubt);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add comment'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _addReply(String commentId) async {
    if (_replyCtrl.text.trim().isEmpty) return;

    final replyText = _replyCtrl.text.trim();

    _replyCtrl.clear();
    setState(() {
      _replyingTo = null;
      _expandedReplies.add(commentId);
    });

    try {
      final reply = await DoubtApiService.addReply(
        widget.doubt.id ?? '',
        commentId,
        author: _currentUserName,
        authorAvatar: _currentUserAvatar,
        content: replyText,
      );

      if (reply != null && mounted) {
        final updated = await DoubtApiService.getDoubtById(
          widget.doubt.id ?? '',
        );
        if (updated != null) {
          setState(() => _doubt = updated);
          widget.onUpdated(_doubt);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reply added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add reply'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kForeground),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Doubt Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: kForeground,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: kBorder, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Avatar(initials: _doubt.authorAvatar ?? '??', size: 48),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _doubt.title ?? '',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: kForeground,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 6,
                                    children: [
                                      Text(
                                        _doubt.author ?? '',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: kForeground,
                                        ),
                                      ),
                                      _MonoBadge(
                                        label:
                                            '@${(_doubt.authorAvatar ?? '').toLowerCase()}',
                                      ),
                                      Text(
                                        '• ${formatTimestamp(_doubt.createdAt)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: kMutedForeground,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _Badge(label: _doubt.subject ?? ''),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _doubt.content ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: kForeground,
                      height: 1.6,
                    ),
                  ),
                  if (_doubt.hasImage == true) ...[
                    const SizedBox(height: 16),
                    _buildDoubtImage(_doubt),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 16,
                        color: kMutedForeground,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${(_doubt.comments?.length) ?? 0} answers',
                        style: const TextStyle(
                          fontSize: 13,
                          color: kMutedForeground,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _CardContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add Your Answer',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: kForeground,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Avatar(initials: _currentUserAvatar, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          children: [
                            _StyledTextArea(
                              controller: _commentCtrl,
                              hint: 'Write your answer here...',
                              minLines: 3,
                            ),
                            const SizedBox(height: 8),

                            Column(
                              children: [
                                if (_commentImageBytes.isNotEmpty)
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: kBorder,
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        kRadius,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 3,
                                            crossAxisSpacing: 8,
                                            mainAxisSpacing: 8,
                                          ),
                                      itemCount: _commentImageBytes.length,
                                      itemBuilder: (ctx, idx) => Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              kRadius,
                                            ),
                                            child: Image.memory(
                                              _commentImageBytes[idx],
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: GestureDetector(
                                              onTap: () =>
                                                  _removeCommentImage(idx),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withOpacity(0.55),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  size: 12,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (_commentImageBytes.isNotEmpty)
                                  const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: _pickCommentImage,
                                  behavior: HitTestBehavior.opaque,
                                  child: Container(
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: kMuted,
                                      borderRadius: BorderRadius.circular(
                                        kRadius,
                                      ),
                                      border: Border.all(
                                        color: kBorder,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Center(
                                      child: _isPickingCommentImage
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: kPrimary,
                                              ),
                                            )
                                          : Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons
                                                      .add_photo_alternate_outlined,
                                                  size: 24,
                                                  color: kMutedForeground,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _commentImageBytes.isEmpty
                                                      ? 'Attach images'
                                                      : 'Add more images',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: kMutedForeground,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: _addComment,
                                icon: const Icon(Icons.send, size: 16),
                                label: const Text('Post Answer'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimary,
                                  foregroundColor: kPrimaryForeground,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      kRadius,
                                    ),
                                  ),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  textStyle: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              '${((_doubt.comments?.length) ?? 0)} ${((_doubt.comments?.length) ?? 0) == 1 ? "Answer" : "Answers"}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: kMutedForeground,
              ),
            ),
            const SizedBox(height: 12),

            if ((_doubt.comments?.isEmpty) ?? true)
              _CardContainer(
                child: const Column(
                  children: [
                    SizedBox(height: 16),
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 40,
                      color: kMutedForeground,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No answers yet. Be the first to help!',
                      style: TextStyle(color: kMutedForeground, fontSize: 14),
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),

            ...List.generate((_doubt.comments?.length) ?? 0, (i) {
              final comment = (_doubt.comments ?? [])[i];
              final isReplying = _replyingTo == comment.id;
              final repliesExpanded = _expandedReplies.contains(comment.id);
              return Padding(
                padding: EdgeInsets.only(
                  bottom: i < ((_doubt.comments?.length) ?? 0) - 1 ? 16 : 0,
                ),
                child: _CardContainer(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: kAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Center(
                          child: Text(
                            comment.authorAvatar ?? '??',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: kAccent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  (comment.author ?? '').toLowerCase() == 'you'
                                      ? _currentUserName
                                      : (comment.author ?? ''),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: kForeground,
                                  ),
                                ),
                                _MonoBadge(
                                  label:
                                      '@${((comment.authorAvatar ?? '').toUpperCase() == 'YO' ? _currentUserAvatar : (comment.authorAvatar ?? '')).toLowerCase()}',
                                ),
                                Text(
                                  formatTimestamp(comment.createdAt),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: kMutedForeground,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              comment.content ?? '',
                              style: const TextStyle(
                                fontSize: 13,
                                color: kForeground,
                                height: 1.5,
                              ),
                            ),
                            if ((comment.imageUrls?.isNotEmpty) ?? false) ...[
                              const SizedBox(height: 8),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                    ),
                                itemCount: (comment.imageUrls?.length) ?? 0,
                                itemBuilder: (ctx, idx) => ClipRRect(
                                  borderRadius: BorderRadius.circular(kRadius),
                                  child: Image.network(
                                    'http://localhost:8000/${comment.imageUrls?[idx] ?? ''}',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: kMutedForeground.withOpacity(0.2),
                                      child: const Icon(
                                        Icons.image_not_supported,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _GhostButton(
                                  icon: Icons.chat_bubble_outline,
                                  label: 'Reply',
                                  onTap: () => setState(
                                    () => _replyingTo = isReplying
                                        ? null
                                        : comment.id,
                                  ),
                                ),
                                if ((comment.replies?.isNotEmpty) ?? false) ...[
                                  const SizedBox(width: 8),
                                  _GhostButton(
                                    icon: repliesExpanded
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    label:
                                        '${(comment.replies?.length) ?? 0} ${((comment.replies?.length) ?? 0) == 1 ? "reply" : "replies"}',
                                    onTap: () => setState(
                                      () => repliesExpanded
                                          ? _expandedReplies.remove(
                                              comment.id ?? '',
                                            )
                                          : _expandedReplies.add(
                                              comment.id ?? '',
                                            ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (isReplying) ...[
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _Avatar(
                                    initials: _currentUserAvatar,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        _StyledTextArea(
                                          controller: _replyCtrl,
                                          hint: 'Write your reply...',
                                          minLines: 2,
                                          fontSize: 12,
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            TextButton(
                                              onPressed: () => setState(
                                                () => _replyingTo = null,
                                              ),
                                              style: TextButton.styleFrom(
                                                foregroundColor:
                                                    kMutedForeground,
                                              ),
                                              child: const Text(
                                                'Cancel',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  _addReply(comment.id ?? ''),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: kPrimary,
                                                foregroundColor:
                                                    kPrimaryForeground,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        kRadius,
                                                      ),
                                                ),
                                                elevation: 0,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                textStyle: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                              child: const Text('Reply'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (repliesExpanded &&
                                ((comment.replies?.isNotEmpty) ?? false)) ...[
                              const SizedBox(height: 16),
                              Container(
                                decoration: const BoxDecoration(
                                  border: Border(
                                    left: BorderSide(color: kBorder, width: 2),
                                  ),
                                ),
                                padding: const EdgeInsets.only(left: 16),
                                child: Column(
                                  children: List.generate(
                                    (comment.replies?.length) ?? 0,
                                    (j) {
                                      final reply = (comment.replies ?? [])[j];
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          bottom:
                                              j <
                                                  ((comment.replies?.length) ??
                                                          0) -
                                                      1
                                              ? 12
                                              : 0,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 28,
                                              height: 28,
                                              decoration: BoxDecoration(
                                                color: kSecondary,
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  reply.authorAvatar ?? '??',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: kSecondaryForeground,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Wrap(
                                                    spacing: 6,
                                                    children: [
                                                      Text(
                                                        (reply.author ?? '')
                                                                    .toLowerCase() ==
                                                                'you'
                                                            ? _currentUserName
                                                            : (reply.author ??
                                                                  ''),
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: kForeground,
                                                        ),
                                                      ),
                                                      _MonoBadge(
                                                        label:
                                                            '@${((reply.authorAvatar ?? '').toUpperCase() == 'YO' ? _currentUserAvatar : (reply.authorAvatar ?? '')).toLowerCase()}',
                                                      ),
                                                      Text(
                                                        formatTimestamp(
                                                          reply.createdAt,
                                                        ),
                                                        style: const TextStyle(
                                                          fontSize: 10,
                                                          color:
                                                              kMutedForeground,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    reply.content ?? '',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: kForeground,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String initials;
  final double size;
  const _Avatar({required this.initials, required this.size});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: kPrimary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.3,
            fontWeight: FontWeight.w600,
            color: kPrimary,
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  const _Badge({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: kSecondary,
        borderRadius: BorderRadius.circular(kRadius),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: kSecondaryForeground,
        ),
      ),
    );
  }
}

class _MonoBadge extends StatelessWidget {
  final String label;
  const _MonoBadge({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: kMuted,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontFamily: 'monospace',
          color: kMutedForeground,
        ),
      ),
    );
  }
}

class _CardContainer extends StatelessWidget {
  final Widget child;
  const _CardContainer({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StyledInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _StyledInput({required this.controller, required this.hint});
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14, color: kForeground),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: kMutedForeground),
        filled: true,
        fillColor: kCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: kBorder, width: 1),
          borderRadius: BorderRadius.circular(kRadius),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: kPrimary, width: 1.5),
          borderRadius: BorderRadius.circular(kRadius),
        ),
      ),
    );
  }
}

class _StyledTextArea extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int minLines;
  final double fontSize;
  const _StyledTextArea({
    required this.controller,
    required this.hint,
    this.minLines = 4,
    this.fontSize = 14,
  });
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: null,
      style: TextStyle(fontSize: fontSize, color: kForeground),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: fontSize, color: kMutedForeground),
        filled: true,
        fillColor: kCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: kBorder, width: 1),
          borderRadius: BorderRadius.circular(kRadius),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: kPrimary, width: 1.5),
          borderRadius: BorderRadius.circular(kRadius),
        ),
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: kForeground,
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _GhostButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: kMutedForeground),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: kMutedForeground),
            ),
          ],
        ),
      ),
    );
  }
}
