// lib/models/lesson.dart
enum LessonType { video, document, quiz, text, unknown }
enum AttachmentType { youtube, vimeo, file, url, unknown }

class Lesson {
  final int id;
  final String title;
  final int sectionId;
  final String? summary;
  final int? order;
  final String? videoProvider;
  final String? videoUrl;
  final String? attachmentUrl;
  final String? attachmentTypeString;
  final String? lessonTypeString;
  final String? duration;
  final DateTime createdAt;
  final DateTime updatedAt;

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
      case 'video':
        return LessonType.video;
      case 'document':
      case 'pdf':
      case 'article':
        return LessonType.document;
      case 'quiz':
      case 'exam':
        return LessonType.quiz;
      case 'text':
        return LessonType.text;
      default:
        if (videoUrl != null && videoUrl!.isNotEmpty) return LessonType.video;
        if (attachmentUrl != null && attachmentUrl!.isNotEmpty) return LessonType.document;
        return LessonType.unknown;
    }
  }

  AttachmentType get attachmentType {
    switch (attachmentTypeString?.toLowerCase()) {
      case 'youtube':
        return AttachmentType.youtube;
      case 'vimeo':
        return AttachmentType.vimeo;
      case 'file':
      case 'pdf':
      case 'image':
      case 'doc':
        return AttachmentType.file;
      case 'url':
        return AttachmentType.url;
      default:
        if (videoUrl != null && videoUrl!.isNotEmpty) {
          if (videoProvider?.toLowerCase() == 'youtube') return AttachmentType.youtube;
          if (videoProvider?.toLowerCase() == 'vimeo') return AttachmentType.vimeo;
        }
        return AttachmentType.unknown;
    }
  }

  factory Lesson.fromJson(Map<String, dynamic> json) {
    String safeGetString(Map<String, dynamic> jsonMap, String key, {String defaultValue = ""}) {
      final value = jsonMap[key];
      if (value is String) {
        return value;
      }
      if (value != null) {
        print("Warning: Field '$key' in Lesson JSON was not a String (type: ${value.runtimeType}). Using its toString() or default. JSON: $jsonMap");
        return value.toString();
      }
      return defaultValue;
    }

    String? safeGetNullableString(Map<String, dynamic> jsonMap, String key) {
      final value = jsonMap[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
      if (value != null) {
        final strValue = value.toString();
        if (strValue.isNotEmpty) return strValue;
      }
      return null;
    }

    DateTime parseSafeDate(dynamic dateValue, String fieldName) {
      if (dateValue is String && dateValue.isNotEmpty) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          print("Error parsing date for Lesson field '$fieldName': $dateValue. Error: $e. Using current time as fallback.");
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
      print("Warning: Integer field '$fieldName' in Lesson JSON was not int or parsable string/number. Using default: '$defaultValue'. Value: $value");
      return defaultValue;
    }

    int? safeGetNullableInt(dynamic value, String fieldName) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is num) return value.toInt();
      print("Warning: Nullable integer field '$fieldName' in Lesson JSON was not int or parsable string/number. Returning null. Value: $value");
      return null;
    }

    String? inferredVideoProvider = safeGetNullableString(json, 'video_provider') ?? safeGetNullableString(json, 'video_type');
    if (inferredVideoProvider == null && safeGetNullableString(json, 'video_url')?.toLowerCase().contains('youtube') == true) {
      inferredVideoProvider = 'youtube';
    }

    return Lesson(
      id: safeGetInt(json['id'], 'id'),
      title: safeGetString(json, 'title', defaultValue: 'Untitled Lesson'),
      sectionId: safeGetInt(json['section_id'], 'section_id', defaultValue: -1),
      summary: safeGetNullableString(json, 'summary'),
      order: safeGetNullableInt(json['order'], 'order'),
      videoProvider: inferredVideoProvider,
      videoUrl: safeGetNullableString(json, 'video_url'),
      attachmentUrl: safeGetNullableString(json, 'attachment'),
      attachmentTypeString: safeGetNullableString(json, 'attachment_type'),
      lessonTypeString: safeGetNullableString(json, 'lesson_type'),
      duration: safeGetNullableString(json, 'duration'),
      createdAt: parseSafeDate(json['createdAt'], 'createdAt'),
      updatedAt: parseSafeDate(json['updatedAt'], 'updatedAt'),
    );
  }
}