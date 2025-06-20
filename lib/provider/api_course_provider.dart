import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:mgw_tutorial/models/api_course.dart';
import 'package:mgw_tutorial/services/database_helper.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ApiCourseProvider with ChangeNotifier {
  List<ApiCourse> _courses = [];
  bool _isLoading = false;
  String? _error;

  List<ApiCourse> get courses => [..._courses];
  bool get isLoading => _isLoading;
  String? get error => _error;

  final DatabaseHelper _dbHelper = DatabaseHelper();

  static const String _apiBaseUrl = "https://courseservice.anbesgames.com/api";

  static const String _networkErrorMessage = "Sorry, there seems to be a network error. Please check your connection and try again.";
  static const String _timeoutErrorMessage = "The request timed out. Please check your connection or try again later.";
  static const String _unexpectedErrorMessage = "An unexpected error occurred.";
  static const String _failedToLoadCoursesMessage = "Failed to load courses.";

  Future<void> fetchCourses({bool forceRefresh = false}) async {
    if (!forceRefresh && _courses.isNotEmpty) {
 
    } else {
      // If force refreshing or no data, clear current data and show loading
      _isLoading = true;
      _error = null;
      _courses = []; // Clear to show loading indicator clearly
      notifyListeners();
    }

    List<ApiCourse> fetchedCourses = [];
    bool networkAttempted = false;
    bool networkSuccess = false;
    String? networkError;

    // ---- CONNECTIVITY CHECK ----
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = connectivityResult != ConnectivityResult.none;

    if (!isOnline) {
      // Device is offline, skip API, load from DB immediately.
      try {
        final List<Map<String, dynamic>> courseMaps = await _dbHelper.query('courses', orderBy: 'title ASC');
        _courses = courseMaps.map((map) => ApiCourse.fromMap(map)).toList();

        // Re-validate local thumbnail paths for loaded courses
        for (var course in _courses) {
          if (course.localThumbnailPath != null) {
            final file = File(course.localThumbnailPath!);
            if (!await file.exists()) {
              course.localThumbnailPath = null;
              // Optionally update DB here if path is null, but doing it
              // during a save transaction is safer/more efficient.
            }
          }
        }

        _error = _courses.isEmpty
            ? _failedToLoadCoursesMessage
            : null;
      } catch (dbError) {
        _courses = [];
        _error = "Failed to load courses from database.";
      }
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      networkAttempted = true;
      final url = Uri.parse('$_apiBaseUrl/course');
      final response = await http.get(url, headers: {
        "Accept": "application/json",
      }).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final dynamic decodedBody = json.decode(response.body);
        List<dynamic> extractedData = [];

        if (decodedBody is List) {
          extractedData = decodedBody;
        } else if (decodedBody is Map<String, dynamic> && decodedBody.containsKey('courses') && decodedBody['courses'] is List) {
          extractedData = decodedBody['courses'];
        } else {
          throw Exception("API response format is unexpected.");
        }

        fetchedCourses = extractedData
            .map((courseJson) {
              try {
                return ApiCourse.fromJson(courseJson as Map<String, dynamic>);
              } catch (e, s) {
                print("Error parsing individual course JSON: ${e.runtimeType}: $e\n$s\nProblematic JSON: $courseJson");
                return null;
              }
            })
            .whereType<ApiCourse>()
            .toList();

        // Only update DB and state if fetched data is different or force refreshing
        if (forceRefresh || !listEquals(_courses, fetchedCourses)) {
          await _downloadAndSaveThumbnails(fetchedCourses);
          await _saveCoursesToDb(fetchedCourses);
          _courses = fetchedCourses;
          _error = null; // Clear any previous error if fetch was successful
          networkSuccess = true;
        } else {
          // Data is the same, no need to update state or DB
          networkSuccess = true;
          _error = null; // Clear any previous error if fetch was successful
        }

      } else {
        String apiError = '$_failedToLoadCoursesMessage (Status: ${response.statusCode})';
        try {
          final errorBody = json.decode(response.body);
          if (errorBody is Map) {
            if (errorBody.containsKey('message') && errorBody['message'] != null && errorBody['message'].toString().isNotEmpty) {
              apiError = errorBody['message'].toString();
            } else if (errorBody.containsKey('error') && errorBody['error'] != null && errorBody['error'].toString().isNotEmpty) {
              apiError = errorBody['error'].toString();
            }
          }
        } catch (e) {
          // Ignore JSON decode errors
        }
        networkError = apiError;
      }
    } on TimeoutException catch (e) {
      networkAttempted = true;
      networkError = _timeoutErrorMessage;
    } on SocketException catch (e) {
      networkAttempted = true;
      networkError = _networkErrorMessage;
    } on http.ClientException catch (e, s) {
      networkAttempted = true;
      print("HTTP Client Exception: ${e.message}\n$s");
      networkError = "${_networkErrorMessage}: ${e.message}";
    } catch (e, s) {
      networkAttempted = true;
      print("Generic Exception during fetchCourses: $e\n$s");
      networkError = "${_unexpectedErrorMessage}: ${e.toString()}";
    }

    // If network failed or was not attempted (shouldn't happen with this logic, but defensive),
    // or if forceRefresh requires potentially clearing old data, load from DB.
    // Load from DB also happens if network was successful but fetched data was the same,
    // to ensure local paths are re-validated/set correctly for existing items.
    if (!networkSuccess || _courses.isEmpty) { // _courses could be empty if network failed OR if network succeeded but returned empty list
      try {
        final List<Map<String, dynamic>> courseMaps = await _dbHelper.query('courses', orderBy: 'title ASC');
        _courses = courseMaps.map((map) => ApiCourse.fromMap(map)).toList();

        // Re-validate local thumbnail paths for loaded courses
        for (var course in _courses) {
          if (course.localThumbnailPath != null) {
            final file = File(course.localThumbnailPath!);
            if (!await file.exists()) {
              course.localThumbnailPath = null;
              // Optionally update DB here if path is null, but doing it
              // during a save transaction is safer/more efficient.
            }
          }
        }

        if (_courses.isEmpty) {
          // No courses from network AND none from DB
          _error = networkAttempted
              ? (networkError ?? _failedToLoadCoursesMessage)
              : _failedToLoadCoursesMessage;
        } else {
          // Courses loaded from DB (after network fail or if network returned same data)
          _error = networkAttempted && networkError != null
              ? "Could not get latest courses from network ($networkError). Showing cached data."
              : null;
        }
      } catch (dbError, dbStack) {
        print("Error loading courses from DB after network failure: $dbError\n$dbStack");
        _courses = [];
        _error = networkAttempted
            ? (networkError ?? "Failed to load courses from database.")
            : "Failed to load courses from database.";
        if (networkAttempted && networkError != null) {
          _error = "$networkError\nAlso failed to load from database.";
        } else {
          _error = "Failed to load courses from database.";
        }
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveCoursesToDb(List<ApiCourse> coursesToSave) async {
    try {
      final db = await _dbHelper.database;
      List<String> oldThumbnailPaths = [];
      List<String> newCourseIds = coursesToSave.map((c) => c.id.toString()).toList();

      try {
        await db.transaction((txn) async {
          oldThumbnailPaths = await _dbHelper.getOldThumbnailPathsInTxn(txn);
          if (newCourseIds.isNotEmpty) {
            await txn.delete('courses', where: 'id NOT IN (${newCourseIds.map((_) => '?').join(',')})', whereArgs: newCourseIds);
          } else {
            await txn.delete('courses'); // Delete all if the new list is empty
          }
        });
      } catch (e, s) {
        print("Error during old course deletion transaction: $e\n$s");
        rethrow;
      }

      List<String> thumbnailsToDelete = oldThumbnailPaths.where((path) {
        if (path.isEmpty) return false;
        try {
          final fileName = path.split('/').last;
          final parts = fileName.split('_');
          if (parts.length > 1) {
            final courseIdPart = parts[1].split('.').first;
            if (int.tryParse(courseIdPart) != null) {
              return !newCourseIds.contains(courseIdPart);
            }
          }
        } catch (e) {
          // Ignore parsing errors
        }
        return false; // Default to not deleting if parsing fails
      }).toList();

      if (thumbnailsToDelete.isNotEmpty) {
        await _dbHelper.deleteThumbnailFiles(thumbnailsToDelete);
      }

      if (coursesToSave.isEmpty) {
        return;
      }

      try {
        await db.transaction((txn) async {
          await _dbHelper.insertCoursesInTxn(txn, coursesToSave);
        });
      } catch (e, s) {
        print("Error during new course insertion transaction: $e\n$s");
        rethrow;
      }
    } catch (e, s) {
      print("Overall Error during _saveCoursesToDb process: $e\n$s");
      rethrow;
    }
  }

  bool listEquals(List<ApiCourse> a, List<ApiCourse> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      // Compare fields relevant for detecting changes that require a DB update
      if (a[i].id != b[i].id ||
          a[i].title != b[i].title ||
          a[i].shortDescription != b[i].shortDescription ||
          a[i].description != b[i].description ||
          a[i].language != b[i].language ||
          a[i].categoryId != b[i].categoryId ||
          a[i].section != b[i].section ||
          a[i].price != b[i].price ||
          a[i].discountFlag != b[i].discountFlag ||
          a[i].discountedPrice != b[i].discountedPrice ||
          a[i].thumbnail != b[i].thumbnail || // Important to check thumbnail URL change
          a[i].videoUrl != b[i].videoUrl ||
          a[i].isTopCourse != b[i].isTopCourse ||
          a[i].status != b[i].status ||
          a[i].isVideoCourse != b[i].isVideoCourse ||
          a[i].isFreeCourse != b[i].isFreeCourse ||
          a[i].multiInstructor != b[i].multiInstructor ||
          a[i].creator != b[i].creator ||
          a[i].createdAt.toIso8601String() != b[i].createdAt.toIso8601String() ||
          a[i].updatedAt.toIso8601String() != b[i].updatedAt.toIso8601String() ||
          !listEqualsString(a[i].outcomes, b[i].outcomes) ||
          !listEqualsString(a[i].requirements, b[i].requirements) ||
          a[i].category?.id != b[i].category?.id ||
          a[i].category?.name != b[i].category?.name) {
        return false;
      }
    }
    return true;
  }

  bool listEqualsString(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _downloadAndSaveThumbnails(List<ApiCourse> courses) async {
    if (courses.isEmpty) {
      return;
    }
    final thumbnailDir = await _dbHelper.getThumbnailDirectory();
    final client = http.Client();

    try {
      for (final course in courses) {
        final imageUrl = course.fullThumbnailUrl;
        if (imageUrl != null && imageUrl.isNotEmpty) {
          try {
            Uri? uri;
            try {
              uri = Uri.parse(imageUrl);
              if (!uri.hasScheme || !(uri.scheme == 'http' || uri.scheme == 'https')) {
                course.localThumbnailPath = null;
                continue;
              }
            } catch (e) {
              course.localThumbnailPath = null;
              continue;
            }

            String fileExtension = 'jpg';
            String pathSegment = uri.path;
            int lastDot = pathSegment.lastIndexOf('.');
            if (lastDot != -1 && pathSegment.length > lastDot + 1) {
              fileExtension = pathSegment.substring(lastDot + 1).split('?').first;
            } else if (uri.queryParameters.containsKey('format')) {
              fileExtension = uri.queryParameters['format']!;
            }

            final fileName = 'course_${course.id}_thumb.${fileExtension}';
            final localPath = path.join(thumbnailDir.path, fileName);
            final localFile = File(localPath);

            // Check if a file with the same name already exists and is likely the correct one
            if (await localFile.exists()) {
              course.localThumbnailPath = localPath;
              continue; // Skip download if file exists
            }

            final response = await client.get(uri).timeout(const Duration(seconds: 15));

            if (response.statusCode == 200) {
              await localFile.writeAsBytes(response.bodyBytes);
              course.localThumbnailPath = localPath;
            } else {
              course.localThumbnailPath = null;
            }
          } on TimeoutException catch (e) {
            course.localThumbnailPath = null;
          } on http.ClientException catch (e) {
            course.localThumbnailPath = null;
          } catch (e, s) {
            course.localThumbnailPath = null;
          }
        } else {
          course.localThumbnailPath = null;
        }
      }
    } finally {
      client.close();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}