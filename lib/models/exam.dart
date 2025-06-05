class Exam {
  final int id;
  final String title;
  final String? description;
  final int chapterId;
  final int totalQuestions;
  final int timeLimit;
  final String status;
  final bool isAnswerBefore;
  final int passingScore;
  final String examType;
  final String? examYear;
  final int maxAttempts;
  final bool shuffleQuestions;
  final bool showResultsImmediately;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? instructions;

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
    DateTime? parseDate(dynamic date) {
      if (date == null || date is! String) return null;
      try {
        return DateTime.parse(date).toLocal();
      } catch (e) {
        print('Invalid date format "$date": $e');
        return null;
      }
    }

    return Exam(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? 'Unnamed Exam',
      description: json['description'] as String?,
      chapterId: (json['chapter_id'] ?? json['chapterId'] as num?)?.toInt() ?? 0,
      totalQuestions: (json['total_questions'] ?? json['totalQuestions'] as num?)?.toInt() ?? 0,
      timeLimit: (json['time_limit'] ?? json['timeLimit'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'unknown',
      isAnswerBefore: (json['isAnswerBefore'] ?? json['is_answer_before']) is bool
          ? json['isAnswerBefore'] ?? json['is_answer_before']
          : (json['isAnswerBefore'] ?? json['is_answer_before'] as num?)?.toInt() == 1,
      passingScore: (json['passing_score'] ?? json['passingScore'] as num?)?.toInt() ?? 0,
      examType: json['exam_type'] ?? json['examType'] as String? ?? 'general',
      examYear: json['exam_year'] ?? json['examYear'] as String?,
      maxAttempts: (json['max_attempts'] ?? json['maxAttempts'] as num?)?.toInt() ?? 0,
      shuffleQuestions: (json['shuffle_questions'] ?? json['shuffleQuestions']) is bool
          ? json['shuffle_questions'] ?? json['shuffleQuestions']
          : (json['shuffle_questions'] ?? json['shuffleQuestions'] as num?)?.toInt() == 1,
      showResultsImmediately: (json['show_results_immediately'] ?? json['showResultsImmediately']) is bool
          ? json['show_results_immediately'] ?? json['showResultsImmediately']
          : (json['show_results_immediately'] ?? json['showResultsImmediately'] as num?)?.toInt() == 1,
      startDate: parseDate(json['start_date'] ?? json['startDate']),
      endDate: parseDate(json['end_date'] ?? json['endDate']),
      instructions: json['instructions'] as String?,
    );
  }
}