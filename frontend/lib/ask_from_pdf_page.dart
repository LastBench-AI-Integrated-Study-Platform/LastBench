import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';


class UploadScreen extends StatefulWidget {
  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  Uint8List? questionsPdfBytes;
  Uint8List? notesPdfBytes;

  String? questionsPdfName;
  String? notesPdfName;

  double uploadProgress = 0;

  static const navy = Color(0xFF033F63);
  static const teal = Color(0xFF379392);

  Future<void> pickPdf(bool isQuestions) async {
  final res = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf'],
    withData: true,
  );

  if (res == null) return;

  setState(() {
    if (isQuestions) {
      questionsPdfBytes = res.files.single.bytes;
      questionsPdfName = res.files.single.name;
    } else {
      notesPdfBytes = res.files.single.bytes;
      notesPdfName = res.files.single.name;
    }
  });
}


  bool get canAnalyze =>
    questionsPdfBytes != null && notesPdfBytes != null;

   Future<void> analyzePdfs() async {
  if (!canAnalyze) return;

  final BuildContext uploadContext = context;

  showDialog(
    context: uploadContext,
    barrierDismissible: false,
    builder: (dialogCtx) => WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: navy),
              const SizedBox(height: 24),
              const Text("Uploading & Analyzing...", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: navy)),
              const SizedBox(height: 12),
              const Text("Please wait...", style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 16),
              if (uploadProgress > 0 && uploadProgress < 1) ...[
                LinearProgressIndicator(value: uploadProgress, color: teal),
                const SizedBox(height: 8),
                Text("${(uploadProgress * 100).toStringAsFixed(0)}%"),
              ],
            ],
          ),
        ),
      ),
    ),
  );

  setState(() => uploadProgress = 0.0);

  try {
    final uri = Uri.parse("http://127.0.0.1:8000/analyze");
    final request = http.MultipartRequest('POST', uri);

    request.files.add(http.MultipartFile.fromBytes('notes', notesPdfBytes!, filename: notesPdfName, contentType: MediaType('application', 'pdf')));
    request.files.add(http.MultipartFile.fromBytes('questions', questionsPdfBytes!, filename: questionsPdfName, contentType: MediaType('application', 'pdf')));

    final streamedResponse = await request.send();

    int received = 0;
    final total = streamedResponse.contentLength ?? 1;

    

    final response = await http.Response.fromStream(streamedResponse);

    // Always try to close dialog
    if (mounted && Navigator.canPop(uploadContext)) {
      Navigator.of(uploadContext, rootNavigator: true).pop();
    }

    if (response.statusCode != 200) {
      throw Exception("Server error: ${response.statusCode} – ${response.body.substring(0, 200)}...");
    }

    // ── Safe JSON parsing ────────────────────────────────────────────────
    String body = response.body.trim();
    print("Raw response length: ${body.length} chars"); // Debug
    print("First 200 chars: ${body.substring(0, body.length > 200 ? 200 : body.length)}");

    Map<String, dynamic> data;
    try {
      data = jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      print("JSON decode failed: $e");
      throw Exception("Invalid response format from server (not valid JSON): $e");
    }

    final rawResults = data['results'];
    List<dynamic> results = [];

    if (rawResults is List) {
      results = rawResults;
    } else if (rawResults != null) {
      print("Warning: 'results' key is not a List – type: ${rawResults.runtimeType}");
    }

    print("Parsed ${results.length} results successfully");

    if (mounted) {
      Navigator.push(
        uploadContext,
        MaterialPageRoute(builder: (_) => ResultsScreen(results: results.cast<Map<String, dynamic>>())),
      );

      setState(() {
        questionsPdfBytes = null;
        notesPdfBytes = null;
        questionsPdfName = null;
        notesPdfName = null;
        uploadProgress = 0;
      });
    }

  } catch (e, stackTrace) {
    print("Full error in analyzePdfs: $e");
    print(stackTrace);

    if (mounted && Navigator.canPop(uploadContext)) {
      Navigator.of(uploadContext, rootNavigator: true).pop();
    }

    if (mounted) {
      ScaffoldMessenger.of(uploadContext).showSnackBar(
        SnackBar(
          content: Text("Analysis failed: ${e.toString().split('\n').first}"),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }
}
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,

    body: Stack(
      children: [

        /// MAIN SCROLLABLE CONTENT
        SingleChildScrollView(
          child: Column(
            children: [

              /// HEADER
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
                child: Column(
                  children: [
                    const Text(
                      "Upload PDFs",
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
                      "Upload your exam questions and study notes to analyze how well your notes cover the\n"
                      "exam topics. Our tool will match your questions with relevant notes and provide a\n"
                      "comprehensive summary.",
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

              /// UPLOAD CARDS
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
                child: Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  alignment: WrapAlignment.center,
                  children: [
                    uploadCard(
                      title: "Exam Questions",
                      subtitle: "Upload your exam or test questions",
                      color: navy,
                      fileName: questionsPdfName,
                      onTap: () => pickPdf(true),
                    ),
                    uploadCard(
                      title: "Study Notes",
                      subtitle: "Upload your study notes or textbook",
                      color: teal,
                      fileName: notesPdfName,
                      onTap: () => pickPdf(false),
                    ),
                  ],
                ),
              ),

              /// ANALYZE BUTTON
              Padding(
                padding: const EdgeInsets.only(bottom: 50, top: 30),
                child: ElevatedButton(
                  onPressed: canAnalyze ? analyzePdfs : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navy,
                    disabledBackgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 36, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Analyze PDFs",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        /// BACK BUTTON (ALWAYS ON TOP)
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

                /// ICON
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

                /// TITLE
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),

                const SizedBox(height: 6),

                /// SUBTITLE
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),

                const SizedBox(height: 6),

                const Text(
                  "PDF format (Max: 10 MB)",
                  style: TextStyle(fontSize: 13, color: Colors.black45),
                ),

                const SizedBox(height: 18),

                /// SELECT FILE BUTTON
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: navy, width: 2),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: onTap,
                  child: const Text(
                    "Select File",
                    style: TextStyle(
                      color: navy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                if (uploadProgress > 0 && uploadProgress < 1)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: LinearProgressIndicator(value: uploadProgress),
                ),

              /// FILE NAME
                if (fileName != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 16),
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
class ResultsScreen extends StatelessWidget {
  final List<dynamic> results;

  const ResultsScreen({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF033F63);
    const teal = Color(0xFF379392);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: const Text("Analysis Results"),
        centerTitle: true,
      ),
      body: results.isEmpty
          ? const Center(
              child: Text(
                "No results found",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final item = results[index] as Map<String, dynamic>;
                final question = item['question'] as String? ?? "Missing question";
                final answer = item['answer'] as String? ?? "No answer available";

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${index + 1}. $question",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: navy,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          answer,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: teal,
        onPressed: () => Navigator.pop(context),
        child: const Icon(Icons.arrow_back, color: Colors.white),
      ),
    );
  }
}