// lib/models/subject.dart

class Subject {
  final int id; // Changed to int based on API
  final String name; // Changed from subjectName to name
  final String category;
  final String year;
  final String imageUrl; // Changed from image to imageUrl

  Subject({
    required this.id,
    required this.name,
    required this.category,
    required this.year,
    required this.imageUrl, // Keep as imageUrl for consistency with CourseCard field name
  });

  // Factory constructor to create a Subject from JSON data
  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] ?? 0, // Use default 0 if null, assuming id is always present and int
      name: json['name'] ?? 'Unnamed Subject', // Use default if null
      category: json['category'] ?? 'N/A', // Use default if null
      year: json['year'] ?? 'N/A', // Use default if null
      // Handle imageUrl potentially being null in API response
      imageUrl: json['image'] ?? '', // Use 'image' key from API, default to empty string if null
    );
  }
}