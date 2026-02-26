import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

class QuizAndFlashScreen extends StatefulWidget {
  final String sessionId;
  final Map<String, dynamic> quiz;
  final Map<String, dynamic> flashcards;
  final String? difficulty;

  const QuizAndFlashScreen({
    Key? key,
    required this.sessionId,
    required this.quiz,
    required this.flashcards,
    this.difficulty,
  }) : super(key: key);

  @override
  State<QuizAndFlashScreen> createState() => _QuizAndFlashScreenState();
}

class _QuizAndFlashScreenState extends State<QuizAndFlashScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCFCFC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Learning Center',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(color: Color(0xFFFCFCFC)),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 32.0,
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 768),
                    child: Column(
                      children: [
                        const Text(
                          'Learning Center',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Test your knowledge with quizzes or study with flashcards',
                          style: TextStyle(
                            fontSize: 18,
                            color: const Color(0xFF0F172A).withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (widget.difficulty != null) ...[
                          const SizedBox(height: 16),
                          _buildDifficultyBadge(widget.difficulty!),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Tabs
                  Container(
                    constraints: const BoxConstraints(maxWidth: 768),
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F1F2), // light grey background
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      dividerColor: Colors.transparent,
                      splashFactory: NoSplash.splashFactory,
                      overlayColor: MaterialStateProperty.all(
                        Colors.transparent,
                      ),
                      labelColor: Colors.black,
                      unselectedLabelColor: const Color(0xFF6B7280),
                      labelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      tabs: const [
                        Tab(child: Center(child: Text('Quiz'))),
                        Tab(child: Center(child: Text('Flashcards'))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Tab Content
                  Container(
                    constraints: const BoxConstraints(maxWidth: 768),
                    height: 650,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        QuizSection(
                          sessionId: widget.sessionId,
                          quizData: widget.quiz,
                        ),
                        FlashcardsSection(
                          sessionId: widget.sessionId,
                          flashcardsData: widget.flashcards,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyBadge(String difficulty) {
    Color color;
    String icon;

    switch (difficulty.toLowerCase()) {
      case 'easy':
        color = const Color(0xFF10B981);
        icon = '📘';
        break;
      case 'hard':
        color = const Color(0xFFEF4444);
        icon = '🔥';
        break;
      case 'medium':
      default:
        color = const Color(0xFFF59E0B);
        icon = '⚡';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            'Difficulty: ${difficulty[0].toUpperCase()}${difficulty.substring(1)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// Quiz Section
// Fixed Quiz Section - Replace the QuizSection class in quizandflash.dart

class QuizSection extends StatefulWidget {
  final String sessionId;
  final Map<String, dynamic> quizData;

  const QuizSection({Key? key, required this.sessionId, required this.quizData})
    : super(key: key);

  @override
  State<QuizSection> createState() => _QuizSectionState();
}

class _QuizSectionState extends State<QuizSection> {
  late List<Map<String, dynamic>> quizQuestions;
  int currentQuestion = 0;
  int? selectedAnswer;
  bool isAnswered = false;
  int score = 0;
  bool quizComplete = false;
  List<Map<String, dynamic>> results = [];

  @override
  void initState() {
    super.initState();
    quizQuestions = _parseQuizData();
  }

  List<Map<String, dynamic>> _parseQuizData() {
    final questions = widget.quizData['questions'] as List? ?? [];
    return questions.map((q) {
      // FIXED: Handle correct_answer properly
      var correctAnswer = q['correct_answer'];

      // If correct_answer is an integer (index), keep it as is
      // If it's a string, find its index in options
      if (correctAnswer is String) {
        final options = (q['options'] as List?)?.cast<String>() ?? [];
        correctAnswer = options.indexOf(correctAnswer);
        if (correctAnswer == -1) correctAnswer = 0; // Fallback
      }

      return {
        'id': q['id'] ?? 0,
        'question': q['question'] ?? '',
        'options': (q['options'] as List?)?.cast<String>() ?? [],
        'correct_answer': correctAnswer, // Now always an index (int)
        'explanation': q['explanation'] ?? '',
      };
    }).toList();
  }

  void handleAnswerSelect(int index) {
    if (isAnswered) return;
    setState(() {
      selectedAnswer = index;
    });
  }

  void handleSubmit() {
    if (selectedAnswer == null) return;

    final question = quizQuestions[currentQuestion];

    // FIXED: Compare indices, not strings
    final correctAnswerIndex = question['correct_answer'] as int;
    final isCorrect = selectedAnswer == correctAnswerIndex;

    setState(() {
      isAnswered = true;
      if (isCorrect) {
        score++;
      }
      results.add({
        'question': question['question'],
        'selectedAnswer': question['options'][selectedAnswer!],
        'correctAnswer':
            question['options'][correctAnswerIndex], // Get the actual text
        'isCorrect': isCorrect,
      });
    });
  }

  void handleNext() {
    if (currentQuestion < quizQuestions.length - 1) {
      setState(() {
        currentQuestion++;
        selectedAnswer = null;
        isAnswered = false;
      });
    } else {
      setState(() {
        quizComplete = true;
      });
      _submitQuizAttempt();
    }
  }

  void handleRestart() {
    setState(() {
      currentQuestion = 0;
      selectedAnswer = null;
      isAnswered = false;
      score = 0;
      quizComplete = false;
      results = [];
    });
  }

  Future<void> _submitQuizAttempt() async {
    try {
      final answers = results.asMap().entries.map((entry) {
        final idx = entry.key;
        final r = entry.value;
        return {
          'question_id': idx,
          'question': r['question'],
          'user_answer': r['selectedAnswer'],
          'correct_answer': r['correctAnswer'],
          'is_correct': r['isCorrect'],
          'options': quizQuestions[idx]['options'],
        };
      }).toList();

      final response = await http.post(
        Uri.parse(AppConfig.quizAttemptEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'session_id': widget.sessionId,
          'answers': answers,
          'score': score,
          'total_questions': quizQuestions.length,
        }),
      );

      if (response.statusCode == 200) {
        print('Quiz attempt saved successfully');
      } else {
        print('Failed to save quiz attempt: ${response.statusCode}');
      }
    } catch (e) {
      print('Error submitting quiz: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (quizComplete) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                'Quiz Complete!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'You scored $score out of ${quizQuestions.length}',
                style: const TextStyle(fontSize: 18, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 32),
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF379392),
                      const Color(0xFF379392).withOpacity(0.7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF379392).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${((score / quizQuestions.length) * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Accuracy',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 32),

              // Results List
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Your Answers:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...results.asMap().entries.map((entry) {
                final index = entry.key;
                final result = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: result['isCorrect']
                        ? const Color(0xFF379392).withOpacity(0.1)
                        : const Color(0xFFEF4444).withOpacity(0.1),
                    border: Border.all(
                      color: result['isCorrect']
                          ? const Color(0xFF379392)
                          : const Color(0xFFEF4444),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: result['isCorrect']
                                  ? const Color(0xFF379392)
                                  : const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Q${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            result['isCorrect']
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: result['isCorrect']
                                ? const Color(0xFF379392)
                                : const Color(0xFFEF4444),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            result['isCorrect'] ? 'Correct' : 'Incorrect',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: result['isCorrect']
                                  ? const Color(0xFF379392)
                                  : const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        result['question'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your answer: ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              result['selectedAnswer'],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: result['isCorrect']
                                    ? const Color(0xFF379392)
                                    : const Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (!result['isCorrect']) ...[
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Correct answer: ',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                result['correctAnswer'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF379392),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: handleRestart,
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text(
                    'Try Again',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final question = quizQuestions[currentQuestion];
    final options = question['options'] as List<String>;
    final correctAnswerIndex = question['correct_answer'] as int;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${currentQuestion + 1} of ${quizQuestions.length}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF379392).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Score: $score/${quizQuestions.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF379392),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Question
          Text(
            question['question'],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Options in 2x2 Grid
          SizedBox(
            height: 200,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 10,
                childAspectRatio: 4.0,
              ),
              itemCount: options.length,
              itemBuilder: (context, index) {
                final isSelected = selectedAnswer == index;
                final isCorrect =
                    index ==
                    correctAnswerIndex; // FIXED: Now comparing int with int
                final showResult = isAnswered;

                Color bgColor = Colors.white;
                Color borderColor = const Color(0xFFE2E8F0);
                Color textColor = const Color(0xFF0F172A);

                if (showResult && isCorrect) {
                  // FIXED: Always show correct answer in green
                  bgColor = const Color(0xFF379392);
                  borderColor = const Color(0xFF379392);
                  textColor = Colors.white;
                } else if (showResult && isSelected && !isCorrect) {
                  // FIXED: Show wrong answer in red
                  bgColor = const Color(0xFFEF4444).withOpacity(0.1);
                  borderColor = const Color(0xFFEF4444);
                  textColor = const Color(0xFFEF4444);
                } else if (showResult) {
                  // Other options fade out
                  bgColor = const Color(0xFFF5F5F6).withOpacity(0.5);
                  borderColor = const Color(0xFFE2E8F0);
                  textColor = const Color(0xFF94A3B8);
                } else if (isSelected) {
                  // Before submitting, show selection
                  bgColor = const Color(0xFF379392).withOpacity(0.1);
                  borderColor = const Color(0xFF379392);
                }

                return InkWell(
                  onTap: () => handleAnswerSelect(index),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: bgColor,
                      border: Border.all(color: borderColor, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Center(
                            child: Text(
                              options[index],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        if (showResult && isCorrect)
                          const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 20,
                          ),
                        if (showResult && isSelected && !isCorrect)
                          const Icon(
                            Icons.cancel,
                            color: Color(0xFFEF4444),
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Submit/Next Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isAnswered ? handleNext : handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                isAnswered
                    ? (currentQuestion == quizQuestions.length - 1
                          ? 'Submit Quiz'
                          : 'Next Question')
                    : 'Submit Answer',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Flashcards Section
class FlashcardsSection extends StatefulWidget {
  final String sessionId;
  final Map<String, dynamic> flashcardsData;

  const FlashcardsSection({
    Key? key,
    required this.sessionId,
    required this.flashcardsData,
  }) : super(key: key);

  @override
  State<FlashcardsSection> createState() => _FlashcardsSectionState();
}

class _FlashcardsSectionState extends State<FlashcardsSection> {
  late List<Map<String, dynamic>> flashcards;
  int currentCard = 0;
  bool isFlipped = false;

  @override
  void initState() {
    super.initState();
    flashcards = _parseFlashcardsData();
  }

  List<Map<String, dynamic>> _parseFlashcardsData() {
    final cards = widget.flashcardsData['cards'] as List? ?? [];
    return cards.map((c) {
      return {
        'id': c['id'] ?? 0,
        'question': c['question'] ?? '',
        'answer': c['answer'] ?? '',
        'card_order': c['card_order'] ?? 0,
      };
    }).toList();
  }

  void handleFlip() {
    setState(() {
      isFlipped = !isFlipped;
    });
  }

  void handlePrevious() {
    if (currentCard > 0) {
      setState(() {
        currentCard--;
        isFlipped = false;
      });
    }
  }

  void handleNext() {
    if (currentCard < flashcards.length - 1) {
      setState(() {
        currentCard++;
        isFlipped = false;
      });
    }
  }

  void handleReset() {
    setState(() {
      currentCard = 0;
      isFlipped = false;
    });
  }

  Future<void> _saveCardProgress(bool isKnown) async {
    try {
      await http.post(
        Uri.parse(
          '${AppConfig.flashcardProgressEndpoint}?session_id=${widget.sessionId}&card_id=${flashcards[currentCard]['id']}&is_known=$isKnown',
        ),
      );
    } catch (e) {
      print('Error saving flashcard progress: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = flashcards[currentCard];

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Card ${currentCard + 1} of ${flashcards.length}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              TextButton.icon(
                onPressed: handleReset,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reset'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),

        // === Main Flashcard – FIXED SIZE ===
        SizedBox(
          height: 420, // ← This is the key! Fixed height for all cards
          child: GestureDetector(
            onTap: handleFlip,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Container(
                key: ValueKey<bool>(isFlipped),
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: isFlipped
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF379392), Color(0xFF2D7675)],
                        )
                      : const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1E293B), Color(0xFF334155)],
                        ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isFlipped
                                  ? const Color(0xFF379392)
                                  : const Color(0xFF1E293B))
                              .withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 40,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isFlipped ? 'ANSWER' : 'QUESTION',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.7),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Text(
                            isFlipped ? card['answer'] : card['question'],
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      isFlipped
                          ? 'Click to flip back'
                          : 'Click to reveal answer',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.65),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Navigation + Progress
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: currentCard > 0 ? handlePrevious : null,
                icon: const Icon(Icons.chevron_left, size: 20),
                label: const Text('Previous'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E293B),
                  disabledBackgroundColor: const Color(0xFFF5F5F6),
                  disabledForegroundColor: const Color(0xFFCBD5E1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFE2E8F0), width: 2),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: currentCard < flashcards.length - 1
                    ? handleNext
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFF5F5F6),
                  disabledForegroundColor: const Color(0xFFCBD5E1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Next'),
                    SizedBox(width: 8),
                    Icon(Icons.chevron_right, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Progress Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            flashcards.length,
            (index) => GestureDetector(
              onTap: () {
                setState(() {
                  currentCard = index;
                  isFlipped = false;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: index == currentCard ? 36 : 10,
                height: 10,
                decoration: BoxDecoration(
                  color: index == currentCard
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
