// models/api_course.dart
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' show join;

class CourseCategoryInfo {
  final int id;
  final String name;

  CourseCategoryInfo({required this.id, required this.name});

  factory CourseCategoryInfo.fromJson(Map<String, dynamic> json) {
    return CourseCategoryInfo(
      id: json['id'] as int? ?? 0,
      name: json['catagory'] as String? ?? 'Unknown Category',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory CourseCategoryInfo.fromMap(Map<String, dynamic> map) {
     return CourseCategoryInfo(
      id: map['id'] as int? ?? 0,
      name: map['name'] as String? ?? 'Unknown Category',
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
  final String? section;
  final List<String> requirements;
  final String price;
  final bool? discountFlag;
  final String? discountedPrice;
  final String? thumbnail;
  final String? videoUrl;
  final bool? isTopCourse;
  final String status;
  final bool? isVideoCourse;
  final bool? isFreeCourse;
  final bool? multiInstructor;
  final String? creator;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CourseCategoryInfo? category;

  String? localThumbnailPath;

  static const String thumbnailBaseUrl = "https://courseservice.anbesgames.com";

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
    this.localThumbnailPath,
  });

  String? get fullThumbnailUrl {
    if (thumbnail != null && thumbnail!.isNotEmpty) {
      if (thumbnail!.toLowerCase().startsWith('http')) {
        return thumbnail;
      }
      String baseUrl = thumbnailBaseUrl;
      String thumbPath = thumbnail!;
      return '$baseUrl/${thumbPath.startsWith('/') ? thumbPath.substring(1) : thumbPath}';
    }
    return null;
  }

  String? get displayThumbnailPath {
     if (localThumbnailPath != null && localThumbnailPath!.isNotEmpty) {
         try {
           final file = File(localThumbnailPath!);
           if (file.existsSync()) {
             return localThumbnailPath;
           }
         } catch (e) {
           // Error checking file existence, fall back to network URL
         }
     }
     return fullThumbnailUrl;
  }

  factory ApiCourse.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic jsonField) {
      if (jsonField is String) {
        try {
          final decoded = jsonDecode(jsonField);
          if (decoded is List) {
            return decoded.map((item) => item.toString()).toList();
          }
        } catch (e) {
          // Could not parse string list JSON
        }
      } else if (jsonField is List) {
        return jsonField.map((item) => item.toString()).toList();
      }
      return [];
    }

    bool? parseBoolFromString(dynamic value) {
        if (value is bool) return value;
        if (value is String) return value.toLowerCase() == 'true' || value == '1';
        if (value is int) return value == 1;
        return null;
    }

     DateTime parseSafeDate(dynamic dateValue) {
      if (dateValue is String && dateValue.isNotEmpty) {
        try {
          return DateTime.parse(dateValue).toLocal();
        } catch (e) {
          // Error parsing date string
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return ApiCourse(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? 'Untitled Course',
      shortDescription: json['short_description'] as String?,
      description: json['description'] as String?,
      outcomes: parseStringList(json['outcomes']),
      language: json['language'] as String?,
      categoryId: json['category_id'] as int?,
      section: json['section']?.toString(),
      requirements: parseStringList(json['requirements']),
      price: json['price'] as String? ?? "0.00",
      discountFlag: parseBoolFromString(json['discount_flag']),
      discountedPrice: json['discounted_price'] as String?,
      thumbnail: json['thumbnail'] as String?,
      videoUrl: json['video_url'] as String?,
      isTopCourse: parseBoolFromString(json['is_top_course']),
      status: json['status'] as String? ?? 'unknown',
      isVideoCourse: parseBoolFromString(json['video']),
      isFreeCourse: parseBoolFromString(json['is_free_course']),
      multiInstructor: parseBoolFromString(json['multi_instructor']),
      creator: json['creator'] as String?,
      createdAt: parseSafeDate(json['createdAt']),
      updatedAt: parseSafeDate(json['updatedAt']),
      category: json['category'] != null && json['category'] is Map<String, dynamic>
          ? CourseCategoryInfo.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      localThumbnailPath: null,
    );
  }

  Map<String, dynamic> toMap() {
     int? boolToInt(bool? b) => b == null ? null : (b ? 1 : 0);

    return {
      'id': id,
      'title': title,
      'shortDescription': shortDescription,
      'description': description,
      'outcomes': jsonEncode(outcomes),
      'language': language,
      'categoryId': categoryId,
      'section': section,
      'requirements': jsonEncode(requirements),
      'price': price,
      'discountFlag': boolToInt(discountFlag),
      'discountedPrice': discountedPrice,
      'thumbnail': thumbnail,
      'videoUrl': videoUrl,
      'isTopCourse': boolToInt(isTopCourse),
      'status': status,
      'isVideoCourse': boolToInt(isVideoCourse),
      'isFreeCourse': boolToInt(isFreeCourse),
      'multiInstructor': boolToInt(multiInstructor),
      'creator': creator,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'courseCategoryId': category?.id,
      'courseCategoryName': category?.name,
      'localThumbnailPath': localThumbnailPath,
    };
  }

  factory ApiCourse.fromMap(Map<String, dynamic> map) {
     DateTime parseSafeDateFromDb(dynamic dateValue) {
      if (dateValue is String && dateValue.isNotEmpty) {
        try {
          return DateTime.parse(dateValue).toLocal();
        } catch (e) {
          // Error parsing date string from DB
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

     List<String> parseStringListFromDb(dynamic dbField) {
      if (dbField is String && dbField.isNotEmpty) {
        try {
          final decoded = jsonDecode(dbField);
          if (decoded is List) {
            return decoded.map((item) => item.toString()).toList();
          }
        } catch (e) {
           // Could not parse DB string list JSON
        }
      }
      return [];
    }

     bool? intToBool(dynamic value) {
      if (value is int) return value == 1;
      if (value is String) return value.toLowerCase() == 'true' || value == '1';
      return null;
    }

    CourseCategoryInfo? categoryInfo;
    if (map['courseCategoryId'] != null && map['courseCategoryName'] != null) {
       categoryInfo = CourseCategoryInfo(
         id: map['courseCategoryId'] as int,
         name: map['courseCategoryName'] as String,
       );
    }

    final course = ApiCourse(
      id: map['id'] as int? ?? 0,
      title: map['title'] as String? ?? 'Untitled Course',
      shortDescription: map['shortDescription'] as String?,
      description: map['description'] as String?,
      outcomes: parseStringListFromDb(map['outcomes']),
      language: map['language'] as String?,
      categoryId: map['categoryId'] as int?,
      section: map['section'] as String?,
      requirements: parseStringListFromDb(map['requirements']),
      price: map['price'] as String? ?? "0.00",
      discountFlag: intToBool(map['discountFlag']),
      discountedPrice: map['discountedPrice'] as String?,
      thumbnail: map['thumbnail'] as String?,
      videoUrl: map['videoUrl'] as String?,
      isTopCourse: intToBool(map['isTopCourse']),
      status: map['status'] as String? ?? 'unknown',
      isVideoCourse: intToBool(map['isVideoCourse']),
      isFreeCourse: intToBool(map['isFreeCourse']),
      multiInstructor: intToBool(map['multiInstructor']),
      creator: map['creator'] as String?,
      createdAt: parseSafeDateFromDb(map['createdAt']),
      updatedAt: parseSafeDateFromDb(map['updatedAt']),
      category: categoryInfo,
      localThumbnailPath: map['localThumbnailPath'] as String?,
    );

    return course;
  }
}