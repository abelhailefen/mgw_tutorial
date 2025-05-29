// lib/provider/api_course_provider.dart
import 'dart:convert';
import 'dart:async';
import 'dart:io'; // Needed for File
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart' as sqflite; // Import sqflite to use ConflictAlgorithm
import 'package:mgw_tutorial/models/api_course.dart'; // Import from models
import 'package:mgw_tutorial/services/database_helper.dart'; // Import DatabaseHelper
import 'package:path/path.dart' show join; // Needed for joining paths


class ApiCourseProvider with ChangeNotifier {
  List<ApiCourse> _courses = [];
  bool _isLoading = false;
  String? _error;

  List<ApiCourse> get courses => [..._courses];
  bool get isLoading => _isLoading;
  String? get error => _error;

  final DatabaseHelper _dbHelper = DatabaseHelper();


  static const String _networkErrorMessage = "Sorry, there seems to be a network error. Please check your connection and try again.";
  static const String _timeoutErrorMessage = "The request timed out. Please check your connection or try again later.";
  static const String _unexpectedErrorMessage = "An unexpected error occurred while fetching courses. Please try again later.";
  static const String _failedToLoadCoursesMessage = "Failed to load courses. Please try again.";

  static const String _apiBaseUrl = "https://mgw-backend.onrender.com/api";


  Future<void> fetchCourses({bool forceRefresh = false}) async {
    // First, try to load from DB immediately
    if (_courses.isEmpty) {
       print("Attempting to load courses from DB...");
       await _loadCoursesFromDb();
       if (_courses.isNotEmpty) {
         print("Loaded ${_courses.length} courses from DB.");
         // notifyListeners() is called within _loadCoursesFromDb if data is found
       } else {
          print("No courses found in DB.");
       }
    }

    // Check if we should SKIP the network fetch
    // Skip if not force refreshing AND we already have NON-EMPTY data from DB
    if (!forceRefresh && _courses.isNotEmpty && _error == null) { // Also check error state
      print("Skipping network fetch for courses as non-empty data is available and not forcing refresh.");
      // _isLoading = false; // Already false if loaded from DB
      return;
    }

    // We need to fetch from network
    _isLoading = true;
    _error = null; // Clear previous error before network fetch
    // Only notify listeners here if courses were empty before,
    // otherwise the DB load already notified.
    if (_courses.isEmpty) {
      notifyListeners();
    }


    final url = Uri.parse('$_apiBaseUrl/course');
    print("Fetching courses from network: $url (Force Refresh: $forceRefresh)");
    try {
      final response = await http.get(url, headers: {
        "Accept": "application/json",
      }).timeout(const Duration(seconds: 30));
      print("Courses API Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final dynamic decodedBody = json.decode(response.body);
        List<dynamic> extractedData = [];

        if (decodedBody is List) {
          extractedData = decodedBody;
        } else if (decodedBody is Map<String, dynamic> && decodedBody.containsKey('courses') && decodedBody['courses'] is List) {
          extractedData = decodedBody['courses'];
        }
        else {
          _error = "Failed to load courses: API response format is not a recognized list or object with a 'courses' key.";
          print(_error);
           // If network fails but we have DB data, keep DB data
           if (_courses.isEmpty) notifyListeners(); // Notify if no courses to show
          return; // Exit if API format is wrong
        }

        final List<ApiCourse> fetchedCourses = extractedData
            .map((courseJson) {
              try {
                return ApiCourse.fromJson(courseJson as Map<String, dynamic>);
              } catch (e) {
                print("Error parsing individual course JSON: ${e.runtimeType}: $e");
                print("Problematic course JSON: $courseJson");
                return null;
              }
            })
            .whereType<ApiCourse>()
            .toList();

        // NEW: Download and save images BEFORE saving to DB
        print("Attempting to download and save course thumbnails...");
        await _downloadAndSaveThumbnails(fetchedCourses);
        print("Finished thumbnail download/save process.");


        // NEW: Delete old courses and save new ones (including local paths)
        // _saveCoursesToDb already calls deleteAllCourses internally for cleanup
        await _saveCoursesToDb(fetchedCourses); // Now calls transaction internally
        print("Courses saved to DB.");

        _courses = fetchedCourses; // Update the provider's state with the new list
        _error = null; // Clear any previous error

      } else {
         _handleHttpErrorResponse(response, _failedToLoadCoursesMessage);
         // If network fails but we have DB data, keep DB data and show error
         if (_courses.isEmpty) notifyListeners(); // Notify if no courses to show
         return; // Exit on HTTP error
      }
    } on TimeoutException catch (e) {
      print("TimeoutException fetching courses: $e");
      _error = _timeoutErrorMessage;
    } on SocketException catch (e) {
      print("SocketException fetching courses: $e");
      _error = _networkErrorMessage;
    } on http.ClientException catch (e) {
      print("ClientException fetching courses: $e");
      _error = _networkErrorMessage;
    } catch (e, s) {
      print("Generic Exception during fetchCourses: $e");
      print("Stacktrace: $s");
      if (e is FormatException && e.source is List && e.message.contains("is not a subtype of type 'Map<String, dynamic>'")) {
         _error = "Failed to parse courses: API returned a list, but items inside were not valid course objects. $e";
      } else {
        _error = _unexpectedErrorMessage;
      }
    } finally {
      _isLoading = false;
      // Notify listeners to update the UI state (loading -> done, or error state)
       notifyListeners();
    }
  }

  // Helper method for batch upserting
  Future<void> _saveCoursesToDb(List<ApiCourse> coursesToSave) async {
     // deleteAllCourses now handles file cleanup before deleting DB records
     await _dbHelper.deleteAllCourses();
     if (coursesToSave.isEmpty) {
       print("No courses to save to DB.");
       return;
     }
     try {
        print("Saving ${coursesToSave.length} courses to DB...");
        // Use a transaction for efficiency when inserting many
        final db = await _dbHelper.database;
        await db.transaction((txn) async {
          for (final course in coursesToSave) {
            await txn.insert('courses', course.toMap(), conflictAlgorithm: sqflite.ConflictAlgorithm.replace); // Use sqflite.ConflictAlgorithm
          }
        });
       print("Courses saved to DB successfully.");
     } catch (e) {
       print("Error saving courses to DB: $e");
       // This is a critical error for offline functionality
       _error = "Failed to save courses for offline access: $e";
     }
   }


  Future<void> _loadCoursesFromDb() async {
    try {
      final List<Map<String, dynamic>> courseMaps = await _dbHelper.query('courses', orderBy: 'title ASC');
      _courses = courseMaps.map((map) => ApiCourse.fromMap(map)).toList();
       if (_courses.isNotEmpty) {
          // Only notify if we actually loaded courses
         notifyListeners();
       }
    } catch (e) {
      print("Error loading courses from DB: $e");
      // Optionally set an error if loading from DB fails
      // _error = "Failed to load cached courses: $e";
      // notifyListeners(); // Notify to show the error
    }
  }

  // NEW: Method to download and save thumbnails
  Future<void> _downloadAndSaveThumbnails(List<ApiCourse> courses) async {
      final thumbnailDir = await _dbHelper.getThumbnailDirectory(); // Call the public method
      final client = http.Client(); // Use a single client for multiple requests

      try {
        for (final course in courses) {
          final imageUrl = course.fullThumbnailUrl;
          if (imageUrl != null && imageUrl.isNotEmpty) {
            try {
              // Construct the local file path
              // Use a unique filename based on course ID and maybe a hash of the URL/timestamp for freshness
              // For simplicity now, just use course ID. Ensure extension is handled.
              // Let's try to infer extension from URL if possible, otherwise default
              String fileExtension = 'jpg'; // Default
              try {
                 Uri uri = Uri.parse(imageUrl);
                 String path = uri.path;
                 int lastDot = path.lastIndexOf('.');
                 if (lastDot != -1 && path.length > lastDot + 1) {
                    fileExtension = path.substring(lastDot + 1);
                 }
              } catch (_) {
                // Ignore parsing errors, use default
              }

              final fileName = 'course_${course.id}_thumb.${fileExtension}';
              final localPath = join(thumbnailDir.path, fileName);
              final localFile = File(localPath);

              // Check if the file exists from a previous fetch and is likely the same
              // (Advanced: compare file size or use ETag/Last-Modified headers if API supports them)
              // For simplicity, let's skip re-downloading if a file *with the same name* already exists.
              // This assumes the backend serves a unique URL or updates filenames when images change.
               if (await localFile.exists()) {
                  // print("Local thumbnail already exists for course ${course.id}: $localPath. Skipping download."); // Can be noisy
                   course.localThumbnailPath = localPath; // Assign the existing local path
                   continue; // Skip download for this course
               }


              final response = await client.get(Uri.parse(imageUrl));

              if (response.statusCode == 200) {
                await localFile.writeAsBytes(response.bodyBytes);
                course.localThumbnailPath = localPath; // Update the course object
                // print("Saved thumbnail for course ${course.id} to $localPath"); // Can be noisy
              } else {
                print("Failed to download thumbnail for course ${course.id} (Status: ${response.statusCode}): $imageUrl");
                // Leave localThumbnailPath as null, will use network on next attempt
              }
            } on http.ClientException catch (e) {
               // Handle client-specific errors during download (e.g., network issues)
               print("HTTP Client Error downloading thumbnail for course ${course.id} ($imageUrl): $e");
               // Leave localThumbnailPath as null
            } catch (e) {
              print("Generic Error downloading/saving thumbnail for course ${course.id} ($imageUrl): $e");
              // Leave localThumbnailPath as null
            }
          } else {
             // print("No thumbnail URL for course ${course.id}"); // Can be noisy
             // Ensure localThumbnailPath is null if no network URL
             course.localThumbnailPath = null;
          }
        }
      } finally {
        client.close(); // Close the client when done
      }
   }


  void _handleHttpErrorResponse(http.Response response, String defaultUserMessage) {
    try {
      final errorBody = json.decode(response.body);
      if (errorBody is Map && errorBody.containsKey('message') && errorBody['message'] != null && errorBody['message'].toString().isNotEmpty) {
        _error = errorBody['message'].toString();
      } else if (errorBody is Map && errorBody.containsKey('error') && errorBody['error'] != null && errorBody['error'].toString().isNotEmpty){
         _error = errorBody['error'].toString();
      }
      else {
        _error = "$defaultUserMessage (Status: ${response.statusCode})";
      }
    } catch (e) {
      _error = "$defaultUserMessage (Status: ${response.statusCode}). Response not parsable. Body: ${response.body.substring(0, (response.body.length > 200 ? 200 : response.body.length))}";
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}