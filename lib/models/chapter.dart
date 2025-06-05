// lib/models/chapter.dart

class Chapter {
  final int id;
  final String name;
  final String? description; // Description can be null
  final String status;
  final int subjectId;
  final int order;

  Chapter({
    required this.id,
    required this.name,
    this.description, // description is optional
    required this.status,
    required this.subjectId,
    required this.order,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unnamed Chapter',
      description: json['description'], // Nullable field
      status: json['status'] ?? 'unknown',
      subjectId: json['subject_id'] ?? 0,
      order: json['order'] ?? 0,
    );
  }
}