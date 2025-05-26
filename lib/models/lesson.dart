// lib/models/lesson.dart

// Enums for lesson and attachment types
enum LessonType { video, document, quiz, text, unknown }
enum AttachmentType { youtube, vimeo, file, url, unknown } // Added file, url for clarity


// Represents a lesson within a section/chapter
class Lesson {
  final int id;
  final String title;
  final int sectionId; // Link back to the section
  final String? summary; // Text content or description
  final int? order; // Order within the section

  // Fields related to media/attachments
  final String? videoProvider; // e.g., 'youtube', 'vimeo'
  final String? videoUrl; // The actual video URL

  final String? attachmentUrl; // URL for documents, etc.
  final String? attachmentTypeString; // String from API for attachment type (e.g., 'pdf', 'image')

  // General lesson type string from API
  final String? lessonTypeString;
  final String? duration; // e.g., "5:30" for videos

  // Timestamps
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

  // Getter to convert lessonTypeString to LessonType enum
  LessonType get lessonType {
    switch (lessonTypeString?.toLowerCase()) {
      case 'video':
        return LessonType.video;
      case 'document':
      case 'pdf': // Add other document-like types from your API if needed
      case 'article':
        return LessonType.document;
      case 'quiz':
      case 'exam': // Add other quiz-like types if needed
        return LessonType.quiz;
      case 'text':
        return LessonType.text;
      default:
        // Fallback: if videoUrl is present, maybe it's a video even if type is unknown?
        if (videoUrl != null && videoUrl!.isNotEmpty) return LessonType.video;
        // If attachmentUrl is present, maybe it's a document?
        if (attachmentUrl != null && attachmentUrl!.isNotEmpty) return LessonType.document;
        return LessonType.unknown;
    }
  }

  // Getter to convert attachmentTypeString or video info to AttachmentType enum
  AttachmentType get attachmentType {
    switch (attachmentTypeString?.toLowerCase()) {
      case 'youtube':
        return AttachmentType.youtube;
      case 'vimeo':
        return AttachmentType.vimeo;
      case 'file':
      case 'pdf': // Can map specific file types to 'file'
      case 'image':
      case 'doc':
        return AttachmentType.file;
      case 'url':
        return AttachmentType.url; // Generic URL not matching other types
      default:
        // If attachmentTypeString is unknown, check video fields as fallback
        if (videoUrl != null && videoUrl!.isNotEmpty) {
          if (videoProvider?.toLowerCase() == 'youtube') return AttachmentType.youtube;
          if (videoProvider?.toLowerCase() == 'vimeo') return AttachmentType.vimeo;
        }
        return AttachmentType.unknown;
    }
  }

  // Factory constructor to create a Lesson object from JSON data (e.g., from API)
  factory Lesson.fromJson(Map<String, dynamic> json) {
    // Helper to safely get a string, providing a default if null or not a string
    String safeGetString(Map<String, dynamic> jsonMap, String key, {String defaultValue = ""}) {
      final value = jsonMap[key];
      if (value is String) {
        return value;
      }

      // if (value is num) { return value.toString(); } // Uncomment if API might send numbers as strings
      if (value != null) { // It's not null but also not a string
        print("Warning: Field '$key' in Lesson JSON was not a String (type: ${value.runtimeType}). Using its toString() or default. JSON: $jsonMap");
        return value.toString(); // Attempt to convert if not null but wrong type
      }
      // print("Warning: Field '$key' in Lesson JSON was null. Using default: '$defaultValue'. JSON: $jsonMap"); // Too verbose
      return defaultValue;
    }

    // Helper for nullable strings (returns null if key is missing or value is null/empty string)
    String? safeGetNullableString(Map<String, dynamic> jsonMap, String key) {
      final value = jsonMap[key];
      if (value is String && value.isNotEmpty) { // Also check if string is not empty
        return value;
      }
      if (value != null) { // Not null/empty string, but exists - try toString
        // print("Warning: Nullable field '$key' in Lesson JSON was not a String or was empty (type: ${value.runtimeType}). Using its toString(). Value: $value"); // Too verbose
        final strValue = value.toString();
         if (strValue.isNotEmpty) return strValue;
      }
      return null; // If value is null, key is missing, or value toString is empty
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
      // print("Warning: Date field '$fieldName' in Lesson JSON was null or not a valid string. Using current time as fallback. Value: $dateValue"); // Too verbose
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
       if (value is num) return value.toInt(); // Also handle other numbers
      print("Warning: Integer field '$fieldName' in Lesson JSON was not int or parsable string/number. Using default: '$defaultValue'. Value: $value");
      return defaultValue;
    }

    // Helper for safe nullable int parsing
    int? safeGetNullableInt(dynamic value, String fieldName) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
       if (value is num) return value.toInt(); // Also handle other numbers
      print("Warning: Nullable integer field '$fieldName' in Lesson JSON was not int or parsable string/number. Returning null. Value: $value");
      return null;
    }


    return Lesson(
      id: safeGetInt(json['id'], 'id'), // Assuming 'id' is always provided and must be an int
      title: safeGetString(json, 'title', defaultValue: 'Untitled Lesson'), // SAFELY GET STRING
      sectionId: safeGetInt(json['section_id'], 'section_id', defaultValue: -1), // Assuming 'section_id' is required
      summary: safeGetNullableString(json, 'summary'),
      order: safeGetNullableInt(json['order'], 'order'),

      videoProvider: safeGetNullableString(json, 'video_provider') ?? safeGetNullableString(json, 'video_type'), // Check both keys for provider
      videoUrl: safeGetNullableString(json, 'video_url'),

      attachmentUrl: safeGetNullableString(json, 'attachment'), // Use 'attachment' key
      attachmentTypeString: safeGetNullableString(json, 'attachment_type'),

      lessonTypeString: safeGetNullableString(json, 'lesson_type'),
      duration: safeGetNullableString(json, 'duration'),

      createdAt: parseSafeDate(json['created_at'], 'created_at'), // SAFELY PARSE DATE
      updatedAt: parseSafeDate(json['updated_at'], 'updated_at'), // SAFELY PARSE DATE
    );
  }
}