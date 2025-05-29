// lib/models/api_course.dart
import 'dart:convert'; // Import jsonEncode/jsonDecode
import 'dart:io'; // Import File class

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

  // Added for DB conversion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  // Added for DB conversion
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
  final String? thumbnail; // Network path from API
  final String? videoUrl; // Note: This seems to be a course-level video URL
  final bool? isTopCourse;
  final String status;
  final bool? isVideoCourse;
  final bool? isFreeCourse;
  final bool? multiInstructor;
  final String? creator;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CourseCategoryInfo? category;

  // NEW: Field to store the local file path of the thumbnail
  String? localThumbnailPath;


  static const String thumbnailBaseUrl = "https://mgw-backend.onrender.com";


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
    // NEW: Initialize localThumbnailPath
    this.localThumbnailPath,
  });

  // Corrected getter for the full thumbnail URL (network)
  String? get fullThumbnailUrl {
    if (thumbnail != null && thumbnail!.isNotEmpty) {
      if (thumbnail!.toLowerCase().startsWith('http')) {
        return thumbnail; // Already a full URL
      }
      // Ensure there's a slash between base URL and thumbnail path
      String baseUrl = thumbnailBaseUrl;
      String thumbPath = thumbnail!;

      // Ensure base URL doesn't end with / and thumbPath doesn't start with /
      // If base URL ends with / and thumbPath starts with /, remove the thumbPath's leading /
      if (baseUrl.endsWith('/') && thumbPath.startsWith('/')) {
        return baseUrl + thumbPath.substring(1);
      }
      // If base URL doesn't end with / and thumbPath doesn't start with /, add a /
      else if (!baseUrl.endsWith('/') && !thumbPath.startsWith('/')) {
         return '$baseUrl/$thumbPath';
      }
      // Otherwise, one has a slash, the other doesn't - they fit
      else {
        return baseUrl + thumbPath;
      }
    }
    return null;
  }

  // NEW: Getter to use for display - prioritizes local path
  String? get displayThumbnailPath {
     // Check if the local path exists and the file is actually there
     if (localThumbnailPath != null && localThumbnailPath!.isNotEmpty) {
         try {
           final file = File(localThumbnailPath!);
           if (file.existsSync()) {
             return localThumbnailPath; // Use local path
           } else {
              // File not found, clear the path and use network
              print("Local thumbnail file not found: ${localThumbnailPath}. Falling back to network.");
              localThumbnailPath = null; // Clear invalid path
           }
         } catch (e) {
            print("Error checking local thumbnail file: $e. Falling back to network.");
            localThumbnailPath = null; // Clear invalid path on error
         }
     }
     // If local path is null, empty, or file doesn't exist, use network URL
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
          print("Could not parse string list: $jsonField, error: $e");
        }
      } else if (jsonField is List) {
        return jsonField.map((item) => item.toString()).toList();
      }
      return [];
    }

    bool? parseBoolFromString(dynamic value) {
        if (value is bool) return value;
        if (value is String) return value.toLowerCase() == 'true';
        // Added for robust parsing, though API should send bool/string
        if (value is int) return value == 1;
        return null;
    }

     DateTime parseSafeDate(dynamic dateValue, String fieldName) {
      if (dateValue is String && dateValue.isNotEmpty) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          print("Error parsing date for Course field '$fieldName': $dateValue. Error: $e. Using current time as fallback.");
          return DateTime.now();
        }
      }
      return DateTime.now(); // Fallback
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
      discountFlag: json['discount_flag'] as bool?,
      discountedPrice: json['discounted_price'] as String?,
      thumbnail: json['thumbnail'] as String?,
      videoUrl: json['video_url'] as String?,
      isTopCourse: json['is_top_course'] as bool?,
      status: json['status'] as String? ?? 'unknown',
      isVideoCourse: parseBoolFromString(json['video']),
      isFreeCourse: json['is_free_course'] as bool?,
      multiInstructor: json['multi_instructor'] as bool?,
      creator: json['creator'] as String?,
      createdAt: parseSafeDate(json['createdAt'], 'createdAt'),
      updatedAt: parseSafeDate(json['updatedAt'], 'updatedAt'),
      category: json['category'] != null && json['category'] is Map<String, dynamic>
          ? CourseCategoryInfo.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      // localThumbnailPath is not from API, so it's not included here
      localThumbnailPath: null,
    );
  }

  // Added for DB conversion (saving to SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'shortDescription': shortDescription,
      'description': description,
      'outcomes': jsonEncode(outcomes), // Store list as JSON string
      'language': language,
      'categoryId': categoryId,
      'section': section,
      'requirements': jsonEncode(requirements), // Store list as JSON string
      'price': price,
      // Store bool as int (1 for true, 0 for false, null for null)
      'discountFlag': discountFlag == null ? null : (discountFlag! ? 1 : 0),
      'discountedPrice': discountedPrice,
      'thumbnail': thumbnail, // Save the network path
      'videoUrl': videoUrl,
      'isTopCourse': isTopCourse == null ? null : (isTopCourse! ? 1 : 0),
      'status': status,
      'isVideoCourse': isVideoCourse == null ? null : (isVideoCourse! ? 1 : 0),
      'isFreeCourse': isFreeCourse == null ? null : (isFreeCourse! ? 1 : 0),
      'multiInstructor': multiInstructor == null ? null : (multiInstructor! ? 1 : 0),
      'creator': creator,
      'createdAt': createdAt.toIso8601String(), // Store DateTime as ISO 8601 string
      'updatedAt': updatedAt.toIso8601String(), // Store DateTime as ISO 8601 string
      // Store category info flattened (assuming CourseCategoryInfo won't change often)
      'courseCategoryId': category?.id,
      'courseCategoryName': category?.name,
      // NEW: Include local thumbnail path
      'localThumbnailPath': localThumbnailPath,
    };
  }

  // Added for DB conversion (loading from SQLite)
  factory ApiCourse.fromMap(Map<String, dynamic> map) {
     DateTime parseSafeDateFromDb(dynamic dateValue, String fieldName) {
      if (dateValue is String && dateValue.isNotEmpty) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          print("Error parsing date from DB for Course field '$fieldName': $dateValue. Error: $e. Using current time as fallback.");
          return DateTime.now();
        }
      }
      return DateTime.now(); // Fallback
    }

     List<String> parseStringListFromDb(dynamic dbField) {
      if (dbField is String && dbField.isNotEmpty) {
        try {
          final decoded = jsonDecode(dbField);
          if (decoded is List) {
            return decoded.map((item) => item.toString()).toList();
          }
        } catch (e) {
           print("Could not parse DB string list: $dbField, error: $e");
        }
      }
      return [];
    }

     bool? intToBool(dynamic value) {
      if (value is int) return value == 1;
      return null;
    }

    // Safely get category info from flattened DB fields
    CourseCategoryInfo? categoryInfo;
    if (map['courseCategoryId'] != null && map['courseCategoryName'] != null) {
       categoryInfo = CourseCategoryInfo(
         id: map['courseCategoryId'] as int,
         name: map['courseCategoryName'] as String,
       );
    }

    // Create the ApiCourse object
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
      thumbnail: map['thumbnail'] as String?, // Load the network path
      videoUrl: map['videoUrl'] as String?,
      isTopCourse: intToBool(map['isTopCourse']),
      status: map['status'] as String? ?? 'unknown',
      isVideoCourse: intToBool(map['isVideoCourse']),
      isFreeCourse: intToBool(map['isFreeCourse']),
      multiInstructor: intToBool(map['multiInstructor']),
      creator: map['creator'] as String?,
      createdAt: parseSafeDateFromDb(map['createdAt'], 'createdAt'),
      updatedAt: parseSafeDateFromDb(map['updatedAt'], 'updatedAt'),
      category: categoryInfo, // Use the parsed category info
      // NEW: Load the local thumbnail path
      localThumbnailPath: map['localThumbnailPath'] as String?,
    );

    return course;
  }
}