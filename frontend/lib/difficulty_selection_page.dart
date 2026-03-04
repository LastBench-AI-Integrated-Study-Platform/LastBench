import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'config.dart';
import 'quizandflash.dart';

class DifficultySelectionScreen extends StatefulWidget {
  final Uint8List? fileBytes;
  final String fileName;
  final String? userEmail;

  const DifficultySelectionScreen({
    Key? key,
    required this.fileBytes,
    required this.fileName,
    this.userEmail,
  }) : super(key: key);

  @override
  State<DifficultySelectionScreen> createState() =>
      _DifficultySelectionScreenState();
}

class _DifficultySelectionScreenState extends State<DifficultySelectionScreen> {
  bool isLoading = false;
  String? errorMessage;
  String? progressMessage;

  static const navy = Color(0xFF033F63);
  static const teal = Color(0xFF379392);
  static const lightBg = Color(0xFFFCFCFC);

  Future<void> generateQuiz(String difficulty) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      progressMessage = 'Generating $difficulty quiz...';
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(AppConfig.uploadEndpoint),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          widget.fileBytes!,
          filename: widget.fileName,
        ),
      );

      request.fields['num_questions'] = '10';
      request.fields['num_flashcards'] = '10';
      if (widget.userEmail != null) {
        request.fields['user_email'] = widget.userEmail!;
      }
      request.fields['difficulty'] = difficulty;

      final response = await request.send().timeout(
        const Duration(seconds: 120),
      );
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        setState(() {
          progressMessage = null;
          isLoading = false;
        });

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => QuizAndFlashScreen(
                sessionId: data['session_id'],
                quiz: data['quiz'],
                flashcards: data['flashcards'],
                difficulty: difficulty,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        backgroundColor: lightBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: navy),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select Difficulty Level',
          style: TextStyle(
            color: navy,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            children: [
              // Header - slightly compacted
              const Text(
                'Choose Your Quiz Level',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: navy,
                  letterSpacing: -0.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Select difficulty for your quiz',
                style: TextStyle(fontSize: 14, color: navy.withOpacity(0.7)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Cards - now more compact
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Easy
                        SizedBox(
                          width: 180,
                          child: _buildDifficultyCard(
                            title: 'Easy',
                            icon: Icons.lightbulb_outline,
                            description:
                                'Simple, foundational concepts\nPerfect for beginners',
                            color: const Color(0xFF10B981),
                            onTap: () => generateQuiz('easy'),
                          ),
                        ),
                        const SizedBox(width: 20),

                        // Medium
                        SizedBox(
                          width: 180,
                          child: _buildDifficultyCard(
                            title: 'Medium',
                            icon: Icons.school_outlined,
                            description:
                                'Balanced complexity\nInterpretation & application',
                            color: const Color(0xFFF59E0B),
                            onTap: () => generateQuiz('medium'),
                          ),
                        ),
                        const SizedBox(width: 20),

                        // Hard
                        SizedBox(
                          width: 180,
                          child: _buildDifficultyCard(
                            title: 'Hard',
                            icon: Icons.psychology_outlined,
                            description:
                                'Complex, advanced concepts\nCritical thinking required',
                            color: const Color(0xFFEF4444),
                            onTap: () => generateQuiz('hard'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Loading / Error
              if (isLoading)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(color: teal),
                      const SizedBox(height: 10),
                      Text(
                        progressMessage ?? 'Processing...',
                        style: const TextStyle(
                          fontSize: 13,
                          color: teal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.1),
                      border: Border.all(
                        color: const Color(0xFFEF4444),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Error',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          errorMessage!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyCard({
    required String title,
    required IconData icon,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20), // ← reduced from 30
        child: Column(
          mainAxisSize: MainAxisSize.min, // ← important: don't expand
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10), // ← was 8
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 6), // ← reduced
            Text(
              description,
              style: TextStyle(
                fontSize: 11,
                color: navy.withOpacity(0.65),
                height: 1.25,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12), // ← was bigger
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Select',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
