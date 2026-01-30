import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'quizandflash.dart';
import 'config.dart';

class UploadFileScreen extends StatefulWidget {
  const UploadFileScreen({Key? key}) : super(key: key);

  @override
  State<UploadFileScreen> createState() => _UploadFileScreenState();
}

class _UploadFileScreenState extends State<UploadFileScreen> {
  Uint8List? pdfBytes;
  String? pdfName;

  Uint8List? imageBytes;
  String? imageName;

  bool isLoading = false;
  String? errorMessage;
  String? progressMessage;

  // New state for extracted text
  String? extractedText;
  bool showTextPreview = false;

  // History state
  List<Map<String, dynamic>> sessions = [];
  bool isLoadingHistory = false;
  Map<String, bool> expandedSessions = {};

  // Logged-in user
  String? currentUserEmail;

  static const navy = Color(0xFF033F63);
  static const teal = Color(0xFF379392);

  Future<void> pickPdf() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (res == null) return;
    setState(() {
      pdfBytes = res.files.single.bytes;
      pdfName = res.files.single.name;
      imageBytes = null;
      imageName = null;
      errorMessage = null;
      extractedText = null;
      showTextPreview = false;
    });
  }

  Future<void> pickImage() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (res == null) return;
    setState(() {
      imageBytes = res.files.single.bytes;
      imageName = res.files.single.name;
      pdfBytes = null;
      pdfName = null;
      errorMessage = null;
      extractedText = null;
      showTextPreview = false;
    });
  }

  bool get canGenerate => (pdfBytes != null) || (imageBytes != null);

  Future<void> loadSessionsHistory() async {
    setState(() {
      isLoadingHistory = true;
    });

    try {
      // Include user email as query param when available so backend can filter sessions
      final uri = currentUserEmail == null
          ? Uri.parse('${AppConfig.uploadEndpoint}/sessions/history')
          : Uri.parse(
              '${AppConfig.uploadEndpoint}/sessions/history?email=${Uri.encodeComponent(currentUserEmail!)}',
            );

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          sessions = List<Map<String, dynamic>>.from(data['sessions'] ?? []);
          isLoadingHistory = false;
        });
      } else {
        setState(() {
          isLoadingHistory = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load history: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        isLoadingHistory = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading history: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> loadSessionDetails(String sessionId) async {
    try {
      // Request full session details and include user email so backend can enforce ownership
      final uri = currentUserEmail == null
          ? Uri.parse('${AppConfig.uploadEndpoint}/sessions/$sessionId/full')
          : Uri.parse(
              '${AppConfig.uploadEndpoint}/sessions/$sessionId/full?email=${Uri.encodeComponent(currentUserEmail!)}',
            );

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          _showSessionDetailsDialog(context, data);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load session: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentUserAndHistory();
  }

  Future<void> _loadCurrentUserAndHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      currentUserEmail = prefs.getString('user_email');
    } catch (_) {}

    await loadSessionsHistory();
  }

  Future<void> generateQuizAndFlashcards() async {
    if (!canGenerate) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
      progressMessage = "📤 Uploading file...";
      showTextPreview = false;
    });

    try {
      final fileName = pdfName ?? imageName ?? "file";
      final fileBytes = pdfBytes ?? imageBytes;

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.uploadEndpoint}${AppConfig.generationParams}'),
      );

      request.files.add(
        http.MultipartFile.fromBytes('file', fileBytes!, filename: fileName),
      );

      // Attach user identifier if available so backend can associate sessions
      if (currentUserEmail != null) {
        request.fields['user_email'] = currentUserEmail!;
      }

      if (mounted) {
        setState(() {
          progressMessage = "⚙️ Extracting text from file...";
        });
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);

        // Store extracted text
        final fullExtractedText = data['extracted_text'] ?? '';

        if (mounted) {
          setState(() {
            extractedText = fullExtractedText;
            showTextPreview = true;
            isLoading = false;
            progressMessage = "✅ Text extracted successfully!";
          });
        }

        // Show text preview dialog and wait for user confirmation
        final shouldContinue = await _showTextPreviewDialog(
          context,
          fullExtractedText,
          data,
        );

        if (!shouldContinue) {
          // User cancelled
          setState(() {
            showTextPreview = false;
            extractedText = null;
          });
          return;
        }

        // User confirmed - proceed to quiz/flashcards screen
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuizAndFlashScreen(
                sessionId: data['session_id'],
                quiz: data['quiz'],
                flashcards: data['flashcards'],
              ),
            ),
          );
        }
      } else {
        setState(() {
          errorMessage =
              "Error: ${response.statusCode} - Failed to process file";
          progressMessage = null;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage =
            "Error: Unable to connect to backend. Is the server running?\n\n$e";
        progressMessage = null;
        isLoading = false;
      });
    }
  }

  Future<bool> _showTextPreviewDialog(
    BuildContext context,
    String text,
    Map<String, dynamic> data,
  ) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 800,
                  maxHeight: 700,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [navy, teal],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.text_snippet,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Extracted Text Preview',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Review the extracted text before generating quiz',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Stats Row
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            Icons.article,
                            'Characters',
                            text.length.toString(),
                            Colors.blue,
                          ),
                          _buildStatItem(
                            Icons.notes,
                            'Words',
                            text.split(RegExp(r'\s+')).length.toString(),
                            Colors.green,
                          ),
                          _buildStatItem(
                            Icons.quiz,
                            'Questions',
                            data['quiz']['total_questions'].toString(),
                            Colors.orange,
                          ),
                          _buildStatItem(
                            Icons.style,
                            'Flashcards',
                            data['flashcards']['total_cards'].toString(),
                            Colors.purple,
                          ),
                        ],
                      ),
                    ),

                    // Text Content
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(24),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: SingleChildScrollView(
                          child: SelectableText(
                            text.isEmpty ? 'No text extracted' : text,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.6,
                              color: Colors.grey.shade800,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Action Buttons
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop(false);
                              },
                              icon: const Icon(Icons.close),
                              label: const Text('Cancel'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(
                                  color: Colors.red,
                                  width: 2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop(true);
                              },
                              icon: const Icon(Icons.check_circle),
                              label: const Text(
                                'Continue to Quiz & Flashcards',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: navy,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ) ??
        false;
  }

  Widget _buildStatItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Future<void> _showSessionDetailsDialog(
    BuildContext context,
    Map<String, dynamic> sessionData,
  ) async {
    return await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final quiz = sessionData['quiz'] as Map<String, dynamic>? ?? {};
        final flashcards =
            sessionData['flashcards'] as Map<String, dynamic>? ?? {};
        final questions = List<Map<String, dynamic>>.from(
          quiz['questions'] ?? [],
        );
        final cards = List<Map<String, dynamic>>.from(
          flashcards['cards'] ?? [],
        );

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900, maxHeight: 800),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [navy, teal],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.history, color: Colors.white, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Session Details',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Session ID: ${sessionData['session_id']}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                Icons.quiz,
                                'Questions',
                                questions.length.toString(),
                                Colors.blue,
                              ),
                              _buildStatItem(
                                Icons.style,
                                'Flashcards',
                                cards.length.toString(),
                                Colors.purple,
                              ),
                            ],
                          ),
                        ),

                        // Quiz Section
                        if (questions.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.quiz,
                                      color: navy,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Quiz Questions',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: navy,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ...questions.asMap().entries.map((entry) {
                                  int idx = entry.key;
                                  Map<String, dynamic> q = entry.value;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Q${idx + 1}: ${q['question'] ?? ''}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ...(q['options'] as List? ?? [])
                                            .asMap()
                                            .entries
                                            .map((opt) {
                                              int optIdx = opt.key;
                                              String optValue = opt.value
                                                  .toString();
                                              bool isCorrect =
                                                  q['correct_answer'] == optIdx;
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 6,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 20,
                                                      height: 20,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: isCorrect
                                                            ? Colors.green
                                                            : Colors
                                                                  .grey
                                                                  .shade300,
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          String.fromCharCode(
                                                            65 + optIdx,
                                                          ),
                                                          style: TextStyle(
                                                            color: isCorrect
                                                                ? Colors.white
                                                                : Colors
                                                                      .grey
                                                                      .shade600,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        optValue,
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color: isCorrect
                                                              ? Colors.green
                                                              : Colors.black,
                                                          fontWeight: isCorrect
                                                              ? FontWeight.w600
                                                              : FontWeight
                                                                    .normal,
                                                        ),
                                                      ),
                                                    ),
                                                    if (isCorrect)
                                                      const Icon(
                                                        Icons.check_circle,
                                                        color: Colors.green,
                                                        size: 16,
                                                      ),
                                                  ],
                                                ),
                                              );
                                            })
                                            .toList(),
                                        if (q['explanation'] != null &&
                                            q['explanation']
                                                .toString()
                                                .isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 8,
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.amber.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Explanation: ${q['explanation']}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.amber.shade900,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),

                        // Flashcards Section
                        if (cards.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.style,
                                      color: navy,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Flashcards',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: navy,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ...cards.asMap().entries.map((entry) {
                                  int idx = entry.key;
                                  Map<String, dynamic> card = entry.value;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.purple.shade300,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Card ${idx + 1}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: navy,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Front:',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                card['question'] ??
                                                    card['front'] ??
                                                    '',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Back:',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                card['answer'] ??
                                                    card['back'] ??
                                                    '',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),

                        if (questions.isEmpty && cards.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Text(
                                'No quiz or flashcard data available',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
                  child: Column(
                    children: [
                      const Text(
                        "Upload File",
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: navy,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: 80,
                        height: 4,
                        decoration: BoxDecoration(
                          color: teal,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Upload a PDF or an image to generate quizzes and flashcards.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: navy,
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                  child: Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    alignment: WrapAlignment.center,
                    children: [
                      uploadCard(
                        title: "Upload PDF",
                        subtitle: "Upload a PDF (e.g., notes or questions)",
                        color: navy,
                        fileName: pdfName,
                        onTap: pickPdf,
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(bottom: 30, top: 30),
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: (canGenerate && !isLoading)
                            ? generateQuizAndFlashcards
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: navy,
                          disabledBackgroundColor: Colors.grey.shade300,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 36,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Generate Quiz",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  height: 2,
                                  color: Colors.white,
                                ),
                              ),
                      ),

                      const SizedBox(height: 12),

                      if (progressMessage != null && isLoading)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            border: Border.all(color: Colors.blue.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            progressMessage!,
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                      if (errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            border: Border.all(color: Colors.red.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // History Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 50),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.blue),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Pull to refresh to see latest sessions',
                                style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.history, color: navy, size: 28),
                          const SizedBox(width: 12),
                          const Text(
                            'History',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: navy,
                            ),
                          ),
                          const Spacer(),
                          if (sessions.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: teal,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${sessions.length} session${sessions.length > 1 ? 's' : ''}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (isLoadingHistory)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                const SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      teal,
                                    ),
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Loading history...',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (sessions.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.history_toggle_off,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No sessions yet',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Upload a file and generate quizzes to see them here',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Column(
                          children: sessions.map((session) {
                            String sessionId = session['session_id'] ?? '';
                            String createdAt =
                                session['created_at'] ?? 'Unknown';
                            String textPreview =
                                session['text'] ?? 'No preview';

                            // Format date
                            String formattedDate = 'Unknown';
                            try {
                              DateTime dateTime = DateTime.parse(createdAt);
                              formattedDate =
                                  '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
                            } catch (e) {
                              formattedDate = createdAt;
                            }

                            bool isExpanded =
                                expandedSessions[sessionId] ?? false;

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isExpanded
                                      ? teal
                                      : Colors.grey.shade300,
                                  width: isExpanded ? 2 : 1,
                                ),
                                boxShadow: isExpanded
                                    ? [
                                        BoxShadow(
                                          color: teal.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Column(
                                children: [
                                  GestureDetector(
                                    onTap: () async {
                                      setState(() {
                                        expandedSessions[sessionId] =
                                            !isExpanded;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Session: ${sessionId.substring(0, 8)}...',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: navy,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  formattedDate,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Container(
                                                  constraints:
                                                      const BoxConstraints(
                                                        maxWidth: 400,
                                                      ),
                                                  child: Text(
                                                    'Preview: $textPreview...',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          Colors.grey.shade500,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          AnimatedRotation(
                                            turns: isExpanded ? 0.5 : 0,
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            child: Icon(
                                              Icons.expand_more,
                                              color: teal,
                                              size: 24,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (isExpanded)
                                    Container(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        0,
                                        16,
                                        16,
                                      ),
                                      child: Column(
                                        children: [
                                          const Divider(),
                                          const SizedBox(height: 12),
                                          ElevatedButton.icon(
                                            onPressed: () async {
                                              await loadSessionDetails(
                                                sessionId,
                                              );
                                            },
                                            icon: const Icon(Icons.visibility),
                                            label: const Text(
                                              'View Full Details',
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: teal,
                                              foregroundColor: Colors.white,
                                              minimumSize: const Size(
                                                double.infinity,
                                                44,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            top: 36,
            left: 26,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              iconSize: 28,
              color: navy,
              onPressed: () => Navigator.pop(context),
              tooltip: "Back",
            ),
          ),
        ],
      ),
    );
  }

  Widget uploadCard({
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    String? fileName,
  }) {
    return SizedBox(
      width: 420,
      height: 320,
      child: DottedBorder(
        dashPattern: const [6, 4],
        color: Colors.grey.shade400,
        borderType: BorderType.RRect,
        radius: const Radius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.upload_file,
                    color: Colors.white,
                    size: 46,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Supported formats: PDF, PNG, JPG (Max: 10 MB)",
                  style: TextStyle(fontSize: 13, color: Colors.black45),
                ),
                const SizedBox(height: 18),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: color, width: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: onTap,
                  child: Text(
                    "Select File",
                    style: TextStyle(color: color, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 16),
                if (fileName != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          fileName,
                          style: const TextStyle(
                            color: teal,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
