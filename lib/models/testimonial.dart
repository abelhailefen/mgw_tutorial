import 'package:mgw_tutorial/models/author.dart';

class Testimonial {
  final int id;
  final String title;
  final String description;
  final int userId;
  final String status;
  final List<String> images;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Author author;

  static const String imageBaseUrl = "https://courseservice.anbesgames.com";

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

  // This getter constructs the full image URL
  String? get firstFullImageUrl {
    if (images.isNotEmpty) {
      final firstImage = images.first;
      if (firstImage.startsWith('http')) {
        return firstImage; // Already a full URL
      }

      // Assume relative path like "uploads/image.jpg" or "/uploads/image.jpg"
      // Ensure imageBaseUrl doesn't end with / and firstImage starts with /
      final cleanBaseUrl = imageBaseUrl.endsWith('/') ? imageBaseUrl.substring(0, imageBaseUrl.length - 1) : imageBaseUrl;
      final cleanImagePath = firstImage.startsWith('/') ? firstImage : '/$firstImage';

      return cleanBaseUrl + cleanImagePath;
    }
    return null;
  }

  factory Testimonial.fromJson(Map<String, dynamic> json) {
    DateTime parseSafeDate(String? dateString) {
      if (dateString == null || dateString.isEmpty) {
        return DateTime.now();
      }
      try {
        return DateTime.parse(dateString);
      } catch (e) {
        // Consider logging the error more formally if needed
        return DateTime.now();
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
      throw FormatException("Field 'author' is missing or not a map in Testimonial JSON.");
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