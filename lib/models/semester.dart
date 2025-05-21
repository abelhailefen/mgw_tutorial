// lib/models/semester.dart
import 'package:flutter/foundation.dart';

// Assuming Course model is defined as previously:
class Course {
  final String name;
  Course({required this.name});
  factory Course.fromJson(dynamic json) {
    if (json is String) return Course(name: json);
    if (json is Map<String, dynamic>) return Course(name: json['name'] as String? ?? 'Unnamed Course');
    return Course(name: 'Invalid Course Data');
  }
  Map<String, dynamic> toJson() => {'name': name}; // For completeness
  @override
  String toString() => name;
}

class Semester {
  final int id;
  final String name;
  final String year;
  final String price;
  final List<String> images;
  final List<Course> courses;
  final DateTime createdAt;
  final DateTime updatedAt;

  Semester({
    required this.id,
    required this.name,
    required this.year,
    required this.price,
    required this.images,
    required this.courses,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Semester.fromJson(Map<String, dynamic> json) {
    var imageList = (json['images'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    if (kDebugMode) { // Only print in debug mode
      print("Semester.fromJson - Raw images for semester ID ${json['id']}: $imageList");
    }

    var courseListRaw = json['courses'] as List<dynamic>? ?? [];
    List<Course> parsedCourses =
        courseListRaw.map((courseData) => Course.fromJson(courseData)).toList();

    return Semester(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unnamed Semester',
      year: json['year'] as String? ?? 'N/A',
      price: json['price'] as String? ?? '0.00',
      images: imageList,
      courses: parsedCourses,
      createdAt: json['createdAt'] != null && (json['createdAt'] as String).isNotEmpty
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: json['updatedAt'] != null && (json['updatedAt'] as String).isNotEmpty
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  String? get firstImageUrl {
    if (images.isNotEmpty) {
      final imagePath = images.first;
      if (kDebugMode) {
        print("Semester ID: $id, firstImageUrl getter - Raw imagePath: $imagePath");
      }

      if (imagePath.startsWith('http')) { // Already a full URL
        if (kDebugMode) {
          print("Semester ID: $id, firstImageUrl getter - Returning full URL: $imagePath");
        }
        return imagePath;
      }

      // Define your base URL here. Make sure it's correct.
      const String imageBaseUrl = "https://mgw-backend.onrender.com"; // Ensure this is correct

      if (imagePath.startsWith('/')) { // Path like /uploads/image.jpg
        final fullUrl = "$imageBaseUrl$imagePath";
        if (kDebugMode) {
          print("Semester ID: $id, firstImageUrl getter - Path starts with '/', Generated URL: $fullUrl");
        }
        return fullUrl;
      } else { // Path like uploads/image.jpg (needs a leading slash for concatenation)
        final fullUrl = "$imageBaseUrl/$imagePath";
        if (kDebugMode) {
          print("Semester ID: $id, firstImageUrl getter - Path does NOT start with '/', Generated URL: $fullUrl");
        }
        return fullUrl;
      }
    }
    if (kDebugMode) {
      print("Semester ID: $id, firstImageUrl getter - No images found, returning null.");
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'year': year,
      'price': price,
      'images': images,
      'courses': courses.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Semester(id: $id, name: $name, year: $year, price: $price, images: ${images.length}, courses: ${courses.length})';
  }
}