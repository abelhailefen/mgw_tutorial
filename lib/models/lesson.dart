// lib/models/lesson.dart
import 'dart:convert';

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
    final type = lessonTypeString?.toLowerCase();
    final attachmentType = attachmentTypeString?.toLowerCase();

    if (type == 'video') return LessonType.video;
    if (type == 'quiz' || type == 'exam') return LessonType.quiz;

    if (type == 'attachment' && attachmentType == 'html') return LessonType.quiz;

    if (type == 'attachment' &&
        (attachmentType == 'pdf' || attachmentType == 'epub' || attachmentType == 'doc' || attachmentType == 'article')) {
      return LessonType.document;
    }

    if (type == 'text') return LessonType.text;

    if (videoUrl != null && videoUrl!.isNotEmpty) return LessonType.video;
    if (attachmentType == 'html') return LessonType.quiz;
    if (attachmentUrl != null && attachmentUrl!.isNotEmpty) return LessonType.document;

    return LessonType.unknown;
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

  String? get htmlUrl {
    if ((lessonType == LessonType.quiz || lessonType == LessonType.text) && attachmentUrl != null && attachmentUrl!.isNotEmpty) {
      return attachmentUrl;
    }
    return null;
  }

  factory Lesson.fromJson(Map<String, dynamic> json) {
    String safeGetString(Map<String, dynamic> jsonMap, String key, {String defaultValue = ""}) {
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
      duration: map['duration'] as String?,
      createdAt: parseSafeDateFromDb(map['createdAt']),
      updatedAt: parseSafeDateFromDb(map['updatedAt']),
    );
  }
}