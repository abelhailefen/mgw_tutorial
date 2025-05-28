// lib/models/faq.dart

class Faq {
  final String id;
  final String question;
  final String answer;
  final String category;
  final bool isActive;
  final DateTime? createdAt; // Made nullable if API might not send it
  final DateTime? updatedAt; // Made nullable if API might not send it

  Faq({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    required this.isActive,
    this.createdAt, // Now optional
    this.updatedAt, // Now optional
  });

  factory Faq.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse DateTime
    DateTime? parseDate(String? dateString) {
      if (dateString == null || dateString.isEmpty) return null;
      try {
        return DateTime.parse(dateString);
      } catch (e) {
        print("Error parsing date string '$dateString': $e");
        return null; // Or handle error differently
      }
    }

    return Faq(
      id: json['_id'] as String? ?? 'unknown_id', // Default if null
      question: json['question'] as String? ?? 'No question provided', // Default if null
      answer: json['answer'] as String? ?? 'No answer provided', // Default if null
      category: json['category'] as String? ?? 'General',
      isActive: json['isActive'] as bool? ?? false,
      createdAt: parseDate(json['createdAt'] as String?), // Use helper
      updatedAt: parseDate(json['updatedAt'] as String?), // Use helper
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'question': question,
      'answer': answer,
      'category': category,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}