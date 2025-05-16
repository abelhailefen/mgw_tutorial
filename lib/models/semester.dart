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
            ?.map((e) => e.toString()) // Use .toString() for safety if items might not be strings
            .toList() ??
        [];
    var courseListRaw = json['courses'] as List<dynamic>? ?? [];
    List<Course> parsedCourses =
        courseListRaw.map((courseData) => Course.fromJson(courseData)).toList();

    return Semester(
      id: json['id'] as int? ?? 0, // Default if null
      name: json['name'] as String? ?? 'Unnamed Semester',
      year: json['year'] as String? ?? 'N/A',
      price: json['price'] as String? ?? '0.00',
      images: imageList,
      courses: parsedCourses,
      createdAt: json['createdAt'] != null && (json['createdAt'] as String).isNotEmpty
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0), // Default to epoch or a known placeholder
      updatedAt: json['updatedAt'] != null && (json['updatedAt'] as String).isNotEmpty
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0), // Default to epoch
    );
  }

  String? get firstImageUrl {
    if (images.isNotEmpty) {
      if (images.first.startsWith('/')) {
        return "https://mgw-backend-1.onrender.com${images.first}";
      }
      return images.first;
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