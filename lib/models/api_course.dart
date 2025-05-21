// lib/models/api_course.dart
import 'dart:convert';

class CourseCategoryInfo {
  final int id;
  final String name; // API has "catagory"

  CourseCategoryInfo({required this.id, required this.name});

  factory CourseCategoryInfo.fromJson(Map<String, dynamic> json) {
    return CourseCategoryInfo(
      id: json['id'] as int? ?? 0,
      name: json['catagory'] as String? ?? 'Unknown Category', // API uses "catagory"
    );
  }
}

class ApiCourse {
  final int id;
  final String title;
  final String? shortDescription;
  final String? description;
  final List<String> outcomes;
  final String? language;
  final int? categoryId;
  final String? section; // API shows "10", might be string or int
  final List<String> requirements;
  final String price;
  final bool? discountFlag;
  final String? discountedPrice;
  final String? thumbnail; // e.g., "uploads/uee.jpg"
  final String? videoUrl;
  final bool? isTopCourse;
  final String status;
  final bool? isVideoCourse; // API has "video": "false" (string)
  final bool? isFreeCourse;
  final bool? multiInstructor;
  final String? creator;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CourseCategoryInfo? category;

  // Base URL for thumbnails - This should ideally be configurable
  static const String thumbnailBaseUrl = "https://courseservice.zsecreteducation.com/";


  ApiCourse({
    required this.id,
    required this.title,
    this.shortDescription,
    this.description,
    required this.outcomes,
    this.language,
    this.categoryId,
    this.section,
    required this.requirements,
    required this.price,
    this.discountFlag,
    this.discountedPrice,
    this.thumbnail,
    this.videoUrl,
    this.isTopCourse,
    required this.status,
    this.isVideoCourse,
    this.isFreeCourse,
    this.multiInstructor,
    this.creator,
    required this.createdAt,
    required this.updatedAt,
    this.category,
  });

  String? get fullThumbnailUrl {
    if (thumbnail != null && thumbnail!.isNotEmpty) {
      if (thumbnail!.toLowerCase().startsWith('http')) {
        return thumbnail; // It's already a full URL
      }
      return thumbnailBaseUrl + thumbnail!;
    }
    return null;
  }

  factory ApiCourse.fromJson(Map<String, dynamic> json) {
    // Helper to parse string lists like "[]" or "[\"item1\", \"item2\"]"
    List<String> parseStringList(dynamic jsonField) {
      if (jsonField is String) {
        try {
          final decoded = jsonDecode(jsonField);
          if (decoded is List) {
            return decoded.map((item) => item.toString()).toList();
          }
        } catch (e) {
          // If not a valid JSON string, or not a list, return empty or handle as needed
          print("Could not parse string list: $jsonField, error: $e");
        }
      } else if (jsonField is List) {
        return jsonField.map((item) => item.toString()).toList();
      }
      return [];
    }
    
    bool? parseBoolFromString(dynamic value) {
        if (value is bool) return value;
        if (value is String) return value.toLowerCase() == 'true';
        return null;
    }

    return ApiCourse(
      id: json['id'] as int,
      title: json['title'] as String? ?? 'Untitled Course',
      shortDescription: json['short_description'] as String?,
      description: json['description'] as String?,
      outcomes: parseStringList(json['outcomes']),
      language: json['language'] as String?,
      categoryId: json['category_id'] as int?,
      section: json['section']?.toString(), // API sends "10" (string)
      requirements: parseStringList(json['requirements']),
      price: json['price'] as String? ?? "0.00",
      discountFlag: json['discount_flag'] as bool?,
      discountedPrice: json['discounted_price'] as String?,
      thumbnail: json['thumbnail'] as String?,
      videoUrl: json['video_url'] as String?,
      isTopCourse: json['is_top_course'] as bool?,
      status: json['status'] as String? ?? 'unknown',
      isVideoCourse: parseBoolFromString(json['video']), // API sends "false" as string
      isFreeCourse: json['is_free_course'] as bool?,
      multiInstructor: json['multi_instructor'] as bool?,
      creator: json['creator'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      category: json['category'] != null
          ? CourseCategoryInfo.fromJson(json['category'] as Map<String, dynamic>)
          : null,
    );
  }
}