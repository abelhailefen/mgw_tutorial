// lib/models/section_model.dart

class Section {
  final int id;
  final String title; // This is likely the culprit if API sends null for title
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
    // Helper to safely get a string, providing a default if null
    String safeGetString(Map<String, dynamic> jsonMap, String key, {String defaultValue = ""}) {
      final value = jsonMap[key];
      if (value is String) {
        return value;
      }
      // If you expect it to sometimes be a number and want to convert:
      // if (value is num) {
      //   return value.toString();
      // }
      print("Warning: Field '$key' in Section JSON was null or not a String. Using default: '$defaultValue'. JSON: $jsonMap");
      return defaultValue;
    }

    // Helper for robust date parsing
    DateTime parseSafeDate(dynamic dateValue, String fieldName) {
      if (dateValue is String && dateValue.isNotEmpty) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          print("Error parsing date for Section field '$fieldName': $dateValue. Error: $e. Using current time as fallback.");
          return DateTime.now();
        }
      }
      print("Warning: Date field '$fieldName' in Section JSON was null or not a valid string. Using current time as fallback. Value: $dateValue");
      return DateTime.now();
    }
    
    // Helper for safe int parsing (can also handle strings if needed)
    int safeGetInt(dynamic value, String fieldName, {int defaultValue = 0}) {
      if (value is int) {
        return value;
      }
      if (value is String) {
        return int.tryParse(value) ?? defaultValue;
      }
      print("Warning: Integer field '$fieldName' in Section JSON was not int or string. Using default: '$defaultValue'. Value: $value");
      return defaultValue;
    }


    return Section(
      id: safeGetInt(json['id'], 'id'), // Use helper or ensure 'id' is never null
      title: safeGetString(json, 'title', defaultValue: 'Untitled Section'), // SAFELY GET STRING
      courseId: safeGetInt(json['course_id'], 'course_id'), // Ensure 'course_id' is never null or handle it
      order: json['order'] as int?, // 'order' is already nullable in the model, so `as int?` is okay if API might omit it
      createdAt: parseSafeDate(json['created_at'], 'created_at'), // SAFELY PARSE DATE
      updatedAt: parseSafeDate(json['updated_at'], 'updated_at'), // SAFELY PARSE DATE
    );
  }
}