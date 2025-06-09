// lib/models/question.dart

class Question {
  final int id;
  final String questionText; // Renamed from 'question' to avoid conflict
  final String answer;
  final String? time; // Data type might need adjustment
  final String? passage;
  final String? imageUrl; // Renamed from 'image'
  final String optionA; // Renamed from 'A'
  final String optionB; // Renamed from 'B'
  final String optionC; // Renamed from 'C'
  final String optionD; // Renamed from 'D'
  final String? explanation;
  final int subjectId;
  final int chapterId;
  final int examId;
  final String? explanationImageUrl; // Renamed from 'expimage'
  final String? explanationVideoUrl; // Renamed from 'expvideo'
  final String? examType;
  final String? examYear;

  // Optional: Add fields for local storage paths if caching media
  // String? localImagePath;
  // String? localExplanationImagePath;
  // String? localExplanationVideoPath;


  Question({
    required this.id,
    required this.questionText,
    required this.answer,
    this.time,
    this.passage,
    this.imageUrl,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    this.explanation,
    required this.subjectId,
    required this.chapterId,
    required this.examId,
    this.explanationImageUrl,
    this.explanationVideoUrl,
    this.examType,
    this.examYear,
    // this.localImagePath,
    // this.localExplanationImagePath,
    // this.localExplanationVideoPath,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: (json['id'] as num?)?.toInt() ?? 0,
      questionText: json['question'] as String? ?? 'No question text',
      answer: json['answer'] as String? ?? '', // Assume answer is A, B, C, D
      time: json['time'] as String?,
      passage: json['passage'] as String?,
      imageUrl: json['image'] as String?,
      optionA: json['A'] as String? ?? '',
      optionB: json['B'] as String? ?? '',
      optionC: json['C'] as String? ?? '',
      optionD: json['D'] as String? ?? '',
      explanation: json['explanation'] as String?,
      subjectId: (json['subject_id'] ?? json['subjectId'] as num?)?.toInt() ?? 0,
      chapterId: (json['chapter_id'] ?? json['chapterId'] as num?)?.toInt() ?? 0,
      examId: (json['exam_id'] ?? json['examId'] as num?)?.toInt() ?? 0,
      explanationImageUrl: json['expimage'] as String?,
      explanationVideoUrl: json['expvideo'] as String?,
      examType: json['exam_type'] ?? json['examType'] as String?,
      examYear: json['exam_year'] ?? json['examYear'] as String?,
      // localImagePath: json['localImagePath'] as String?, // Include if caching is implemented
      // localExplanationImagePath: json['localExplanationImagePath'] as String?,
      // localExplanationVideoPath: json['localExplanationVideoPath'] as String?,
    );
  }

  // Helper to convert to map for SQLite (adjust column names as needed)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': questionText,
      'answer': answer,
      'time': time,
      'passage': passage,
      'image': imageUrl,
      'A': optionA,
      'B': optionB,
      'C': optionC,
      'D': optionD,
      'explanation': explanation,
      'subjectId': subjectId,
      'chapterId': chapterId,
      'examId': examId,
      'expImage': explanationImageUrl,
      'expVideo': explanationVideoUrl,
      'examType': examType,
      'examYear': examYear,
      // 'localImagePath': localImagePath, // Include if caching is implemented
      // 'localExplanationImagePath': localExplanationImagePath,
      // 'localExplanationVideoPath': localExplanationVideoPath,
    };
  }
}