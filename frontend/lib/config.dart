/// Configuration file for LastBench application
/// This allows the app to work across different devices and systems
/// without hardcoded URLs

class AppConfig {
  // API Base URL - Change this for different environments
  static const String apiBaseUrl = "http://localhost:8000/api";

  // Quiz and Flashcard generation parameters
  static const int numQuestions = 3;
  static const int numFlashcards = 3;

  // Request timeout in seconds (set to 600 = 10 minutes for quiz/flashcard generation)
  static const int requestTimeoutSeconds = 600;

  /// Get full upload endpoint
  static String get uploadEndpoint => "$apiBaseUrl/upload";

  /// Get full quiz attempt endpoint
  static String get quizAttemptEndpoint => "$apiBaseUrl/quiz/attempt";

  /// Get full flashcard progress endpoint
  static String get flashcardProgressEndpoint =>
      "$apiBaseUrl/flashcards/progress";

  /// Get query parameters for generation
  static String get generationParams =>
      "?num_questions=$numQuestions&num_flashcards=$numFlashcards";
}
