// lib/models/section.dart
import 'dart:convert';

class Section {
  final int id;
  final String title;
  final int courseId;
  final int? order;
  final DateTime createdAt;
  final DateTime updatedAt;

  Section({
    required this.id,
    required this.title,
    required this.courseId,
    this.order,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Section.fromJson(Map<String, dynamic> json) {
    String safeGetString(Map<String, dynamic> jsonMap, String key, {String defaultValue = ""}) {
      final value = jsonMap[key];
      if (value is String) {
        return value;
      }
      if (value != null) {
        return value.toString();
      }
      return defaultValue;
    }

    DateTime parseSafeDate(dynamic dateValue, String fieldName) {
      if (dateValue is String && dateValue.isNotEmpty) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          print("Error parsing date for Section field '$fieldName': $dateValue. Error: $e. Using current time as fallback.");
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    int safeGetInt(dynamic value, String fieldName, {int defaultValue = 0}) {
      if (value is int) {
        return value;
      }
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
       if (value is num) return value.toInt();
      print("Warning: Integer field '$fieldName' in Section JSON was not int or parsable string/number. Using default: '$defaultValue'. Value: $value");
      return defaultValue;
    }

    int? safeGetNullableInt(dynamic value, String fieldName) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is num) return value.toInt();
      print("Warning: Nullable integer field '$fieldName' in Section JSON was not int or parsable string/number. Returning null. Value: $value");
      return null;
    }

    return Section(
      id: safeGetInt(json['id'], 'id'),
      title: safeGetString(json, 'title', defaultValue: 'Untitled Section'),
      courseId: safeGetInt(json['course_id'], 'course_id', defaultValue: -1),
      order: safeGetNullableInt(json['order'], 'order'),
      createdAt: parseSafeDate(json['created_at'], 'created_at'),
      updatedAt: parseSafeDate(json['updated_at'], 'updated_at'),
    );
  }

  // Added for DB
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'order': order,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Added for DB
  factory Section.fromMap(Map<String, dynamic> map) {
     DateTime parseSafeDateFromDb(dynamic dateValue, String fieldName) {
      if (dateValue is String && dateValue.isNotEmpty) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          print("Error parsing date from DB for Section field '$fieldName': $dateValue. Error: $e. Using current time as fallback.");
          return DateTime.now();
        }
      }
      return DateTime.now();
    }
    return Section(
      id: map['id'] as int? ?? 0,
      courseId: map['courseId'] as int? ?? -1,
      title: map['title'] as String? ?? 'Untitled Section',
      order: map['order'] as int?,
      createdAt: parseSafeDateFromDb(map['createdAt'], 'createdAt'),
      updatedAt: parseSafeDateFromDb(map['updatedAt'], 'updatedAt'),
    );
  }
}