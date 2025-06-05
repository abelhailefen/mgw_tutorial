// lib/models/exam.dart

class Exam {
  final int id;
  final String title;
  final String? description; // Nullable
  final int chapterId;
  final int totalQuestions;
  final int timeLimit; // Seems like seconds or minutes based on API, adjust if needed
  final String status;
  final bool isAnswerBefore;
  final int passingScore;
  final String examType;
  final String? examYear; // Nullable
  final int maxAttempts;
  final bool shuffleQuestions;
  final bool showResultsImmediately;
  final DateTime? startDate; // Nullable, parse String to DateTime
  final DateTime? endDate; // Nullable, parse String to DateTime
  final String? instructions; // Nullable

  Exam({
    required this.id,
    required this.title,
    this.description,
    required this.chapterId,
    required this.totalQuestions,
    required this.timeLimit,
    required this.status,
    required this.isAnswerBefore,
    required this.passingScore,
    required this.examType,
    this.examYear,
    required this.maxAttempts,
    required this.shuffleQuestions,
    required this.showResultsImmediately,
    this.startDate,
    this.endDate,
    this.instructions,
  });

  factory Exam.fromJson(Map<String, dynamic> json) {
    // Helper to parse nullable DateTime strings
    DateTime? parseDate(dynamic date) {
      if (date == null) return null;
      if (date is String) {
        try {
          return DateTime.parse(date).toLocal(); // Convert to local time zone
        } catch (e) {
          print('Error parsing date "$date": $e');
          return null;
        }
      }
      return null;
    }

    return Exam(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Unnamed Exam',
      description: json['description'], // Direct access, can be null
      chapterId: json['chapter_id'] ?? 0,
      totalQuestions: json['total_questions'] ?? 0,
      timeLimit: json['time_limit'] ?? 0,
      status: json['status'] ?? 'unknown',
      isAnswerBefore: json['isAnswerBefore'] ?? false, // Handle potential null or wrong type
      passingScore: json['passing_score'] ?? 0,
      examType: json['exam_type'] ?? 'general',
      examYear: json['exam_year'], // Direct access, can be null
      maxAttempts: json['max_attempts'] ?? 0,
      shuffleQuestions: json['shuffle_questions'] ?? false, // Handle potential null or wrong type
      showResultsImmediately: json['show_results_immediately'] ?? false, // Handle potential null or wrong type
      startDate: parseDate(json['start_date']),
      endDate: parseDate(json['end_date']),
      instructions: json['instructions'], // Direct access, can be null
    );
  }
}