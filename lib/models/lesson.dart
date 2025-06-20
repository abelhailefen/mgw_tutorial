import 'dart:convert';

enum LessonType { video, note, attachment, exam, unknown }
enum AttachmentType { youtube, vimeo, file, url, unknown }
enum ExamType { video_exam, image, note_exam, attachment, none }

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
  final String? examTypeString;
  final String? richText;
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
    this.examTypeString,
    this.richText,
    this.duration,
    required this.createdAt,
    required this.updatedAt,
  });

  LessonType get lessonType {
    final type = lessonTypeString?.toLowerCase();

    switch (type) {
      case 'video':
        return LessonType.video;
      case 'note':
        return LessonType.note;
      case 'attachment':
        return LessonType.attachment;
      case 'exam':
        return LessonType.exam;
      default:
        if (videoUrl != null && videoUrl!.isNotEmpty) return LessonType.video;
        if (attachmentUrl != null && attachmentUrl!.isNotEmpty) return LessonType.attachment;
        if (richText != null && richText!.isNotEmpty) return LessonType.note;
        return LessonType.unknown;
    }
  }

  ExamType get examType {
    if (lessonType != LessonType.exam) return ExamType.none;
    switch (examTypeString?.toLowerCase()) {
      case 'video_exam':
        return ExamType.video_exam;
      case 'image':
        return ExamType.image;
      case 'note_exam':
        return ExamType.note_exam;
      case 'attachment':
        return ExamType.attachment;
      default:
        return ExamType.none;
    }
  }

  String? get htmlUrl {
    if ((lessonType == LessonType.note || (lessonType == LessonType.exam && examType == ExamType.note_exam)) && richText != null && richText!.isNotEmpty) {
      return richText;
    }
    return null;
  }

  factory Lesson.fromJson(Map<String, dynamic> json) {
    String safeGetString(Map<String, dynamic> jsonMap, String key, {String defaultValue = ''}) {
      final value = jsonMap[key];
      if (value is String && value.isNotEmpty) return value;
      if (value != null) {
        final strValue = value.toString();
        if (strValue.isNotEmpty) return strValue;
      }
      return defaultValue;
    }

    String? safeGetNullableString(Map<String, dynamic> jsonMap, String key) {
      final value = jsonMap[key];
      if (value is String && value.isNotEmpty) return value;
      if (value != null) {
        final strValue = value.toString();
        if (strValue.isNotEmpty) return strValue;
      }
      return null;
    }

    DateTime parseSafeDate(dynamic dateValue) {
      if (dateValue is String && dateValue.isNotEmpty) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    int safeGetInt(dynamic value, {int defaultValue = 0}) {
      if (value is int) return value;
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
      if (value is num) return value.toInt();
      return defaultValue;
    }

    int? safeGetNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is num) return value.toInt();
      return null;
    }

    String? inferredVideoProvider = safeGetNullableString(json, 'video_provider') ?? safeGetNullableString(json, 'video_type');
    if (inferredVideoProvider == null && safeGetNullableString(json, 'video_url')?.toLowerCase().contains('youtube') == true) {
      inferredVideoProvider = 'youtube';
    }

    return Lesson(
      id: safeGetInt(json['id']),
      title: safeGetString(json, 'title', defaultValue: 'Untitled Lesson'),
      sectionId: safeGetInt(json['section_id'], defaultValue: -1),
      summary: safeGetNullableString(json, 'summary'),
      order: safeGetNullableInt(json['order']),
      videoProvider: inferredVideoProvider,
      videoUrl: safeGetNullableString(json, 'video_url'),
      attachmentUrl: safeGetNullableString(json, 'attachment'),
      attachmentTypeString: safeGetNullableString(json, 'attachment_type'),
      lessonTypeString: safeGetNullableString(json, 'lesson_type'),
      examTypeString: safeGetNullableString(json, 'exam_type'),
      richText: safeGetNullableString(json, 'rich_text'),
      duration: safeGetNullableString(json, 'duration'),
      createdAt: parseSafeDate(json['createdAt']),
      updatedAt: parseSafeDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sectionId': sectionId,
      'title': title,
      'summary': summary,
      'order': order,
      'videoProvider': videoProvider,
      'videoUrl': videoUrl,
      'attachmentUrl': attachmentUrl,
      'attachmentTypeString': attachmentTypeString,
      'lessonTypeString': lessonTypeString,
      'examTypeString': examTypeString,
      'richText': richText,
      'duration': duration,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Lesson.fromMap(Map<String, dynamic> map) {
    DateTime parseSafeDateFromDb(dynamic dateValue) {
      if (dateValue is String && dateValue.isNotEmpty) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }
    return Lesson(
      id: map['id'] as int? ?? 0,
      sectionId: map['sectionId'] as int? ?? -1,
      title: map['title'] as String? ?? 'Untitled Lesson',
      summary: map['summary'] as String?,
      order: map['order'] as int?,
      videoProvider: map['videoProvider'] as String?,
      videoUrl: map['videoUrl'] as String?,
      attachmentUrl: map['attachmentUrl'] as String?,
      attachmentTypeString: map['attachmentTypeString'] as String?,
      lessonTypeString: map['lessonTypeString'] as String?,
      examTypeString: map['examTypeString'] as String?,
      richText: map['richText'] as String?,
      duration: map['duration'] as String?,
      createdAt: parseSafeDateFromDb(map['createdAt']),
      updatedAt: parseSafeDateFromDb(map['updatedAt']),
    );
  }
}