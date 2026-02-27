// doubts_section.dart
// Uses dart:html FileUploadInputElement directly — zero packages needed, works on Flutter Web!
// No pubspec.yaml changes required.

// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/material.dart';

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
      // depending on browser / dart2js output we may get either a
      // ByteBuffer or a plain Uint8List. earlier code only handled
      // ByteBuffer which meant the picker would silently return null
      // even though a valid image was chosen.
      if (result is ByteBuffer) {
        completer.complete(result.asUint8List());
      } else if (result is Uint8List) {
        completer.complete(result);
      } else {
        completer.complete(null);
      }
    });
  });

  // If user closes dialog without picking
  input.onAbort.listen((_) => completer.complete(null));

  return completer.future;
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
  final List<Uint8List> imageBytes; // multiple user-uploaded images
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
  final String? imageUrl; // network image (sample data)
  final List<Uint8List> imageBytes; // multiple user-picked bytes via dart:html
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

Widget _buildDoubtImage(Doubt doubt, {double? height}) {
  final br = BorderRadius.circular(kRadius);
  if (doubt.imageBytes.isNotEmpty) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: doubt.imageBytes.length,
      itemBuilder: (ctx, idx) => ClipRRect(
        borderRadius: br,
        child: Image.memory(
          doubt.imageBytes[idx],
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
  if (doubt.imageUrl != null) {
    return ClipRRect(
      borderRadius: br,
      child: Image.network(
        doubt.imageUrl!,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }
  return const SizedBox.shrink();
}

// ─── Main Widget ──────────────────────────────────────────────────────────────

class DoubtsSection extends StatefulWidget {
  const DoubtsSection({super.key});
  @override
  State<DoubtsSection> createState() => _DoubtsSectionState();
}

class _DoubtsSectionState extends State<DoubtsSection> {
  List<Doubt> _doubts = List.from(initialDoubts);

  void _openNewDoubtDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (ctx) => _NewDoubtDialog(
        onSubmit: (doubt) => setState(() => _doubts.insert(0, doubt)),
      ),
    );
  }

  void _openDoubtDetail(Doubt doubt) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _DoubtDetailPage(
          doubt: doubt,
          onUpdated: (updated) {
            setState(() {
              final i = _doubts.indexWhere((d) => d.id == updated.id);
              if (i != -1) _doubts[i] = updated;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          ...List.generate(_doubts.length, (i) {
            final doubt = _doubts[i];
            return Padding(
              padding: EdgeInsets.only(bottom: i < _doubts.length - 1 ? 16 : 0),
              child: _DoubtCard(
                doubt: doubt,
                onTap: () => _openDoubtDetail(doubt),
              ),
            );
          }),
          if (_doubts.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'No doubts yet. Post the first one!',
                  style: TextStyle(color: kMutedForeground, fontSize: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Doubt Card ───────────────────────────────────────────────────────────────

class _DoubtCard extends StatelessWidget {
  final Doubt doubt;
  final VoidCallback onTap;
  const _DoubtCard({required this.doubt, required this.onTap});

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
            _Avatar(initials: doubt.authorAvatar, size: 40),
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
                              doubt.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: kForeground,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${doubt.author} • ${doubt.createdAt}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: kMutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _Badge(label: doubt.subject),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    doubt.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: kMutedForeground,
                      height: 1.4,
                    ),
                  ),
                  if (doubt.hasImage) ...[
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
                        '${doubt.comments.length} answers',
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
  final void Function(Doubt) onSubmit;
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

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);
    try {
      final bytes = await pickImageFromWeb(); // ← uses dart:html directly
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

  void _submit() {
    if (_titleCtrl.text.trim().isEmpty || _contentCtrl.text.trim().isEmpty)
      return;
    widget.onSubmit(
      Doubt(
        id: generateId(),
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        imageBytes: _imageBytes,
        author: 'You',
        authorAvatar: 'YO',
        subject: _subjectCtrl.text.trim().isEmpty
            ? 'General'
            : _subjectCtrl.text.trim(),
        createdAt: 'Just now',
      ),
    );
    Navigator.of(context).pop();
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
  final Doubt doubt;
  final void Function(Doubt) onUpdated;
  const _DoubtDetailPage({required this.doubt, required this.onUpdated});
  @override
  State<_DoubtDetailPage> createState() => _DoubtDetailPageState();
}

class _DoubtDetailPageState extends State<_DoubtDetailPage> {
  late Doubt _doubt;
  final _commentCtrl = TextEditingController();
  List<Uint8List> _commentImageBytes = [];
  bool _isPickingCommentImage = false;
  String? _replyingTo;
  final _replyCtrl = TextEditingController();
  final Set<String> _expandedReplies = {};

  @override
  void initState() {
    super.initState();
    _doubt = widget.doubt;
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

  void _addComment() {
    if (_commentCtrl.text.trim().isEmpty && _commentImageBytes.isEmpty) return;
    setState(() {
      _doubt.comments.add(
        Comment(
          id: generateId(),
          author: 'You',
          authorAvatar: 'YO',
          content: _commentCtrl.text.trim(),
          createdAt: 'Just now',
          imageBytes: _commentImageBytes,
        ),
      );
      _commentCtrl.clear();
      _commentImageBytes = [];
    });
    widget.onUpdated(_doubt);
  }

  void _addReply(String commentId) {
    if (_replyCtrl.text.trim().isEmpty) return;
    setState(() {
      _doubt.comments
          .firstWhere((c) => c.id == commentId)
          .replies
          .add(
            Reply(
              id: generateId(),
              author: 'You',
              authorAvatar: 'YO',
              content: _replyCtrl.text.trim(),
              createdAt: 'Just now',
            ),
          );
      _replyCtrl.clear();
      _replyingTo = null;
      _expandedReplies.add(commentId);
    });
    widget.onUpdated(_doubt);
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
                      _Avatar(initials: _doubt.authorAvatar, size: 48),
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
                                    _doubt.title,
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
                                        _doubt.author,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: kForeground,
                                        ),
                                      ),
                                      _MonoBadge(
                                        label:
                                            '@${_doubt.authorAvatar.toLowerCase()}',
                                      ),
                                      Text(
                                        '• ${_doubt.createdAt}',
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
                            _Badge(label: _doubt.subject),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _doubt.content,
                    style: const TextStyle(
                      fontSize: 14,
                      color: kForeground,
                      height: 1.6,
                    ),
                  ),
                  if (_doubt.hasImage) ...[
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
                        '${_doubt.comments.length} answers',
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
                      const _Avatar(initials: 'YO', size: 32),
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

                            // image picker for multiple answer images
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
              '${_doubt.comments.length} ${_doubt.comments.length == 1 ? "Answer" : "Answers"}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: kMutedForeground,
              ),
            ),
            const SizedBox(height: 12),

            if (_doubt.comments.isEmpty)
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

            ...List.generate(_doubt.comments.length, (i) {
              final comment = _doubt.comments[i];
              final isReplying = _replyingTo == comment.id;
              final repliesExpanded = _expandedReplies.contains(comment.id);
              return Padding(
                padding: EdgeInsets.only(
                  bottom: i < _doubt.comments.length - 1 ? 16 : 0,
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
                            comment.authorAvatar,
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
                                  comment.author,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: kForeground,
                                  ),
                                ),
                                _MonoBadge(
                                  label:
                                      '@${comment.authorAvatar.toLowerCase()}',
                                ),
                                Text(
                                  comment.createdAt,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: kMutedForeground,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              comment.content,
                              style: const TextStyle(
                                fontSize: 13,
                                color: kForeground,
                                height: 1.5,
                              ),
                            ),
                            if (comment.imageBytes.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              // display multiple images in grid
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                    ),
                                itemCount: comment.imageBytes.length,
                                itemBuilder: (ctx, idx) => ClipRRect(
                                  borderRadius: BorderRadius.circular(kRadius),
                                  child: Image.memory(
                                    comment.imageBytes[idx],
                                    fit: BoxFit.cover,
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
                                if (comment.replies.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  _GhostButton(
                                    icon: repliesExpanded
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    label:
                                        '${comment.replies.length} ${comment.replies.length == 1 ? "reply" : "replies"}',
                                    onTap: () => setState(
                                      () => repliesExpanded
                                          ? _expandedReplies.remove(comment.id)
                                          : _expandedReplies.add(comment.id),
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
                                  const _Avatar(initials: 'YO', size: 28),
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
                                                  _addReply(comment.id),
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
                                comment.replies.isNotEmpty) ...[
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
                                    comment.replies.length,
                                    (j) {
                                      final reply = comment.replies[j];
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          bottom: j < comment.replies.length - 1
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
                                                  reply.authorAvatar,
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
                                                        reply.author,
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: kForeground,
                                                        ),
                                                      ),
                                                      _MonoBadge(
                                                        label:
                                                            '@${reply.authorAvatar.toLowerCase()}',
                                                      ),
                                                      Text(
                                                        reply.createdAt,
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
                                                    reply.content,
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
