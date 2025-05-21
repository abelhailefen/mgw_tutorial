// lib/models/lesson_model.dart

enum LessonType { video, document, quiz, text, unknown }
enum AttachmentType { youtube, vimeo, file, url, unknown }

class Lesson {
  final int id;
  final String title; // Potential culprit if API sends null
  final int sectionId;
  final String? summary;
  final int? order;

  final String? videoProvider;
  final String? videoUrl;

  final String? attachmentUrl;
  final String? attachmentTypeString;

  final String? lessonTypeString;
  final String? duration;
  final DateTime createdAt; // Potential culprit if API sends null
  final DateTime updatedAt; // Potential culprit if API sends null

  Lesson({
    required this.id,
    required this.title,
    required this.sectionId,
    this.summary,
    this.order,
    this.videoProvider,
    this.videoUrl,
    this.attachmentUrl,
    this.attachmentTypeString,
    this.lessonTypeString,
    this.duration,
    required this.createdAt,
    required this.updatedAt,
  });

  LessonType get lessonType {
    switch (lessonTypeString?.toLowerCase()) {
      case 'video': return LessonType.video;
      case 'document': case 'pdf': case 'article': return LessonType.document;
      case 'quiz': case 'exam': return LessonType.quiz;
      case 'text': return LessonType.text;
      default: return LessonType.unknown;
    }
  }

  AttachmentType get attachmentType {
     switch (attachmentTypeString?.toLowerCase()) {
      case 'youtube': return AttachmentType.youtube;
      case 'vimeo': return AttachmentType.vimeo;
      case 'file': case 'pdf': case 'image': case 'doc': return AttachmentType.file;
      case 'url': return AttachmentType.url;
      default:
        if (videoUrl != null && videoUrl!.isNotEmpty) {
          if (videoProvider?.toLowerCase() == 'youtube') return AttachmentType.youtube;
          if (videoProvider?.toLowerCase() == 'vimeo') return AttachmentType.vimeo;
        }
        return AttachmentType.unknown;
    }
  }

  factory Lesson.fromJson(Map<String, dynamic> json) {
    // Helper to safely get a string, providing a default if null or not a string
    String safeGetString(Map<String, dynamic> jsonMap, String key, {String defaultValue = ""}) {
      final value = jsonMap[key];
      if (value is String) {
        return value;
      }
      // If you expect it to sometimes be a number and want to convert:
      // if (value is num) { return value.toString(); }
      if (value != null) { // It's not null but also not a string
          print("Warning: Field '$key' in Lesson JSON was not a String (type: ${value.runtimeType}). Using its toString() or default. JSON: $jsonMap");
          return value.toString(); // Attempt to convert if not null but wrong type
      }
      print("Warning: Field '$key' in Lesson JSON was null. Using default: '$defaultValue'. JSON: $jsonMap");
      return defaultValue;
    }
    
    // Helper for nullable strings (returns null if key is missing or value is null)
    String? safeGetNullableString(Map<String, dynamic> jsonMap, String key) {
        final value = jsonMap[key];
        if (value is String) {
            return value;
        }
        if (value != null) { // Not null but not a string
             print("Warning: Nullable field '$key' in Lesson JSON was not a String (type: ${value.runtimeType}). Using its toString(). JSON: $jsonMap");
             return value.toString();
        }
        return null; // If value is null or key is missing
    }


    // Helper for robust date parsing
    DateTime parseSafeDate(dynamic dateValue, String fieldName) {
      if (dateValue is String && dateValue.isNotEmpty) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          print("Error parsing date for Lesson field '$fieldName': $dateValue. Error: $e. Using current time as fallback.");
          return DateTime.now();
        }
      }
      print("Warning: Date field '$fieldName' in Lesson JSON was null or not a valid string. Using current time as fallback. Value: $dateValue");
      return DateTime.now();
    }

    // Helper for safe int parsing
    int safeGetInt(dynamic value, String fieldName, {int defaultValue = 0}) {
      if (value is int) {
        return value;
      }
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
      print("Warning: Integer field '$fieldName' in Lesson JSON was not int or parsable string. Using default: '$defaultValue'. Value: $value");
      return defaultValue;
    }
    
    int? safeGetNullableInt(dynamic value, String fieldName) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      print("Warning: Nullable integer field '$fieldName' in Lesson JSON was not int or parsable string. Returning null. Value: $value");
      return null;
    }


    return Lesson(
      id: safeGetInt(json['id'], 'id'),
      title: safeGetString(json, 'title', defaultValue: 'Untitled Lesson'), // SAFELY GET STRING
      sectionId: safeGetInt(json['section_id'], 'section_id'), // Assuming API sends this and it's required
      
      summary: safeGetNullableString(json, 'summary'),
      order: safeGetNullableInt(json['order'], 'order'),
      
      videoProvider: safeGetNullableString(json, 'video_provider') ?? safeGetNullableString(json, 'video_type'),
      videoUrl: safeGetNullableString(json, 'video_url'),
      
      attachmentUrl: safeGetNullableString(json, 'attachment'),
      attachmentTypeString: safeGetNullableString(json, 'attachment_type'),
      
      lessonTypeString: safeGetNullableString(json, 'lesson_type'),
      duration: safeGetNullableString(json, 'duration'),
      
      createdAt: parseSafeDate(json['created_at'], 'created_at'), // SAFELY PARSE DATE
      updatedAt: parseSafeDate(json['updated_at'], 'updated_at'), // SAFELY PARSE DATE
    );
  }
}