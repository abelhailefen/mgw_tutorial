// lib/models/testimonial.dart
import 'package:mgw_tutorial/models/author.dart'; // We'll reuse the Author model

class Testimonial {
  final int id;
  final String title; // New: from your API
  final String description; // New: from your API (was 'text')
  final int userId; // New: from your API
  final String status; // New: from your API
  final List<String> images; // New: from your API
  final DateTime createdAt;
  final DateTime updatedAt; // New: from your API
  final Author author; // New: from your API

  // Base URL for images - This should ideally be configurable or come from a central place
  static const String imageBaseUrl = "https://mgw-backend.onrender.com";


  Testimonial({
    required this.id,
    required this.title,
    required this.description,
    required this.userId,
    required this.status,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
    required this.author,
  });

  String? get firstFullImageUrl {
    if (images.isNotEmpty) {
      final firstImage = images.first;
      if (firstImage.startsWith('http')) {
        return firstImage; // Already a full URL
      }
      if (firstImage.startsWith('/')) { // Path like /uploads/image.jpg
        return imageBaseUrl + firstImage;
      }
      // If it's just a filename, you might need a different prefix logic
      // For now, assume it starts with '/' if not absolute
    }
    return null;
  }

  factory Testimonial.fromJson(Map<String, dynamic> json) {
    // Helper for robust date parsing
    DateTime parseSafeDate(String? dateString) {
      if (dateString == null || dateString.isEmpty) {
        return DateTime.now(); // Fallback or throw error
      }
      try {
        return DateTime.parse(dateString);
      } catch (e) {
        print("Error parsing date for testimonial: $dateString. Error: $e");
        return DateTime.now(); // Fallback
      }
    }
    
    List<String> parseImages(dynamic imageList) {
        if (imageList is List) {
            return imageList.map((e) => e.toString()).toList();
        }
        return [];
    }


    final authorJson = json['author'];
    if (authorJson == null || authorJson is! Map<String, dynamic>) {
      throw FormatException("Field 'author' is missing or not a map in Testimonial JSON: $json");
    }

    return Testimonial(
      id: json['id'] as int,
      title: json['title'] as String? ?? 'Untitled Testimonial',
      description: json['description'] as String? ?? 'No description provided.',
      userId: json['userId'] as int? ?? 0,
      status: json['status'] as String? ?? 'unknown',
      images: parseImages(json['images']),
      createdAt: parseSafeDate(json['createdAt'] as String?),
      updatedAt: parseSafeDate(json['updatedAt'] as String?),
      author: Author.fromJson(authorJson),
    );
  }
}