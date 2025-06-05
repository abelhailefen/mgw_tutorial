// lib/provider/api_course_provider.dart
import 'dart:convert';
import 'dart:async';
import 'dart:io'; // For SocketException and File
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:path/path.dart' as path; // Import path package with a prefix
import 'package:mgw_tutorial/models/api_course.dart';
import 'package:mgw_tutorial/services/database_helper.dart';


class ApiCourseProvider with ChangeNotifier {
  List<ApiCourse> _courses = [];
  bool _isLoading = false;
  String? _error;

  List<ApiCourse> get courses => [..._courses];
  bool get isLoading => _isLoading;
  String? get error => _error;

  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Store API base URL locally
  static const String _apiBaseUrl = "https://mgw-backend.onrender.com/api";

  // Define reusable error messages based on existing l10n keys if possible
  static const String _networkErrorMessage = "Sorry, there seems to be a network error. Please check your connection and try again.";
  static const String _timeoutErrorMessage = "The request timed out. Please check your connection or try again later.";
  static const String _unexpectedErrorMessage = "An unexpected error occurred.";
  static const String _failedToLoadCoursesMessage = "Failed to load courses.";


  Future<void> fetchCourses({bool forceRefresh = false}) async {
    // Indicate start of loading ONLY if the list is currently empty or forcing refresh
    if (_courses.isEmpty || forceRefresh) {
       _isLoading = true;
       if (_courses.isEmpty || forceRefresh) {
           _error = null;
       }
       notifyListeners();
       print("ApiCourseProvider: FetchCourses initiated. isLoading=$isLoading, error=$error, courses.isEmpty=${_courses.isEmpty}, forceRefresh=$forceRefresh");
    } else {
       print("ApiCourseProvider: Courses already loaded and not forcing refresh. Skipping fetch.");
       return;
    }


    // Attempt to load from DB first if courses are currently empty
    if (_courses.isEmpty) {
      try {
        print("ApiCourseProvider: Attempting to load courses from DB...");
        final List<Map<String, dynamic>> courseMaps = await _dbHelper.query('courses', orderBy: 'title ASC');
        final List<ApiCourse> cachedCourses = courseMaps.map((map) => ApiCourse.fromMap(map)).toList();

        if (cachedCourses.isNotEmpty && !forceRefresh) {
          _courses = cachedCourses;
          _error = null;
          _isLoading = forceRefresh; // Keep loading true if forcing refresh for network
          print("ApiCourseProvider: Successfully loaded ${_courses.length} courses from DB.");
          notifyListeners();
        } else if (cachedCourses.isNotEmpty && forceRefresh) {
           _courses = cachedCourses;
           _error = null;
           _isLoading = true; // Keep loading true for network fetch
           print("ApiCourseProvider: Loaded ${_courses.length} courses from DB for background refresh.");
      } else {
         print("ApiCourseProvider: No courses found in DB.");
          _courses = [];
          _error = null;
          _isLoading = true;
          notifyListeners(); // Notify that DB was empty and still loading
      }

      } catch (e, s) {
        print("ApiCourseProvider: Error loading courses from DB: $e\n$s");
        _courses = [];
        _error = "Failed to load cached courses: $e";
        _isLoading = true;
        notifyListeners();
      }
    } else {
       print("ApiCourseProvider: Courses already in state, proceeding to network fetch (likely force refresh).");
    }


    // Fetch from Network (rely on http exceptions for network issues)
    print("ApiCourseProvider: Attempting network fetch.");
    final url = Uri.parse('$_apiBaseUrl/course');

    try {
      final response = await http.get(url, headers: {
        "Accept": "application/json",
      }).timeout(const Duration(seconds: 45));

      print("ApiCourseProvider: Network Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final dynamic decodedBody = json.decode(response.body);
        List<dynamic> extractedData = [];

        if (decodedBody is List) {
          extractedData = decodedBody;
          print("ApiCourseProvider: API returned a list directly.");
        } else if (decodedBody is Map<String, dynamic> && decodedBody.containsKey('courses') && decodedBody['courses'] is List) {
          extractedData = decodedBody['courses'];
          print("ApiCourseProvider: API returned object with 'courses' key.");
        }
        else {
          _error = "Failed to load courses: API response format is unexpected.";
          print("ApiCourseProvider: $_error Body: ${response.body}");
           if (_courses.isEmpty) notifyListeners();
          _isLoading = false;
          notifyListeners();
          return;
        }

        final List<ApiCourse> fetchedCourses = extractedData
            .map((courseJson) {
              try {
                return ApiCourse.fromJson(courseJson as Map<String, dynamic>);
              } catch (e, s) {
                print("ApiCourseProvider: Error parsing individual course JSON: ${e.runtimeType}: $e");
                 print("Stacktrace: $s");
                print("Problematic course JSON: $courseJson");
                return null;
              }
            })
            .whereType<ApiCourse>()
            .toList();

        if (!listEquals(_courses, fetchedCourses) || forceRefresh) {
             print("ApiCourseProvider: Network data is different or force refresh. Saving and updating state.");

            await _downloadAndSaveThumbnails(fetchedCourses);
            print("ApiCourseProvider: Finished thumbnail download/save process.");

            await _saveCoursesToDb(fetchedCourses);
            print("ApiCourseProvider: Courses saved to DB.");

            _courses = fetchedCourses;
            _error = null;

        } else {
           print("ApiCourseProvider: Network data is same as current data. No DB write or state update.");
           _error = null;
        }


      } else {
         String apiError = '$_failedToLoadCoursesMessage (Status: ${response.statusCode})';
         try {
            final errorBody = json.decode(response.body);
            if (errorBody is Map) {
               if (errorBody.containsKey('message') && errorBody['message'] != null && errorBody['message'].toString().isNotEmpty) {
                   apiError = errorBody['message'].toString();
               } else if (errorBody.containsKey('error') && errorBody['error'] != null && errorBody['error'].toString().isNotEmpty){
                  apiError = errorBody['error'].toString();
               }
            }
         } catch (e) {
            // Failed to parse error body, use default message
         }

         if (_courses.isEmpty) {
           _error = apiError;
           print("ApiCourseProvider: Network fetch failed, no cached data. Error set: $_error");
         } else {
             print("ApiCourseProvider: Network fetch failed after showing cached data: $apiError");
             _error = null;
         }
      }
    } on TimeoutException catch (e) {
      print("ApiCourseProvider: TimeoutException fetching courses: $e");
      if (_courses.isEmpty) {
         _error = _timeoutErrorMessage;
      } else {
         _error = null;
      }
    } on SocketException catch (e) {
      print("ApiCourseProvider: SocketException fetching courses: $e");
       // Rely solely on SocketException/ClientException for network down check
      if (_courses.isEmpty) {
         _error = _networkErrorMessage;
      } else {
         _error = null; // Hide network error if cached data is visible
      }
    } on http.ClientException catch (e, s) {
       print("ApiCourseProvider: HTTP Client Exception: ${e.message}");
       print("Stacktrace: $s");
       // This can also indicate network issues (e.g., connection refused)
       if (_courses.isEmpty) {
           _error = "${_networkErrorMessage}: ${e.message}";
       } else {
           _error = null;
       }
    }
    catch (e, s) {
       print("ApiCourseProvider: Generic Exception during fetchCourses: $e");
       print("Stacktrace: $s");
       if (_courses.isEmpty) {
           _error = "${_unexpectedErrorMessage}: ${e.toString()}";
       } else {
           _error = null;
       }
    } finally {
      _isLoading = false;
       notifyListeners();
       print("ApiCourseProvider: Fetch process finished. Notified listeners. final isLoading=$isLoading, final error=$error");
    }
  }

  Future<void> _saveCoursesToDb(List<ApiCourse> coursesToSave) async {
     try {
        await _dbHelper.deleteAllCourses(); // This handles file cleanup
        if (coursesToSave.isEmpty) {
          print("ApiCourseProvider: No courses to save to DB after clearing old data.");
          return;
        }
        print("ApiCourseProvider: Saving ${coursesToSave.length} courses to DB...");
        final db = await _dbHelper.database;
        await db.transaction((txn) async {
          for (final course in coursesToSave) {
            await txn.insert('courses', course.toMap(), conflictAlgorithm: sqflite.ConflictAlgorithm.replace);
          }
        });
       print("ApiCourseProvider: Courses saved to DB successfully.");
     } catch (e, s) {
       print("ApiCourseProvider: Error saving courses to DB: $e");
       print("Stacktrace: $s");
     }
   }


  Future<void> _loadCoursesFromDb() async {
    try {
      final List<Map<String, dynamic>> courseMaps = await _dbHelper.query('courses', orderBy: 'title ASC');
      _courses = courseMaps.map((map) => ApiCourse.fromMap(map)).toList();
    } catch (e, s) {
      print("ApiCourseProvider: Error loading courses from DB: $e");
      print("Stacktrace: $s");
      _courses = [];
    }
  }

  Future<void> _downloadAndSaveThumbnails(List<ApiCourse> courses) async {
      if (courses.isEmpty) {
         print("ApiCourseProvider: No courses to download thumbnails for.");
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
                    print("ApiCourseProvider: Invalid scheme for thumbnail URL: $imageUrl");
                    continue;
                 }
               } catch(e) {
                  print("ApiCourseProvider: Invalid thumbnail URL for course ${course.id}: $imageUrl. Error: $e");
                  continue;
               }

              String fileExtension = 'jpg';
              String pathSegment = uri.path;
              int lastDot = pathSegment.lastIndexOf('.');
              if (lastDot != -1 && pathSegment.length > lastDot + 1) {
                 fileExtension = pathSegment.substring(lastDot + 1).split('?').first;
               } else if (uri.queryParameters.containsKey('format')) {
                   fileExtension = uri.queryParameters['format']!;
               } else {
                 print("ApiCourseProvider: Could not determine file extension for thumbnail URL: $imageUrl. Using default '$fileExtension'.");
               }

              final fileName = 'course_${course.id}_thumb.${fileExtension}';
              final localPath = path.join(thumbnailDir.path, fileName);
              final localFile = File(localPath);

               if (await localFile.exists()) {
                   course.localThumbnailPath = localPath;
                   continue;
               }

              print("ApiCourseProvider: Downloading thumbnail for course ${course.id} from $imageUrl to $localPath");
              final response = await client.get(uri).timeout(const Duration(seconds: 15));

              if (response.statusCode == 200) {
                await localFile.writeAsBytes(response.bodyBytes);
                course.localThumbnailPath = localPath;
                print("ApiCourseProvider: Saved thumbnail for course ${course.id}.");
              } else {
                print("ApiCourseProvider: Failed to download thumbnail for course ${course.id} (Status: ${response.statusCode}): $imageUrl");
              }
            } on TimeoutException catch (e) {
               print("ApiCourseProvider: Timeout downloading thumbnail for course ${course.id} ($imageUrl): $e");
            } on http.ClientException catch (e) {
               print("ApiCourseProvider: HTTP Client Error downloading thumbnail for course ${course.id} ($imageUrl): ${e.message}");
            } catch (e, s) {
              print("ApiCourseProvider: Generic Error downloading/saving thumbnail for course ${course.id} ($imageUrl): $e");
              print("Stacktrace: $s");
            }
          } else {
             course.localThumbnailPath = null;
          }
        }
      } finally {
        client.close();
         print("ApiCourseProvider: Thumbnail download client closed.");
      }
   }


  void _handleHttpErrorResponse(http.Response response, String defaultUserMessage) {
    try {
      final errorBody = json.decode(response.body);
      if (errorBody is Map) {
         if (errorBody.containsKey('message') && errorBody['message'] != null && errorBody['message'].toString().isNotEmpty) {
            _error = errorBody['message'].toString();
         } else if (errorBody.containsKey('error') && errorBody['error'] != null && errorBody['error'].toString().isNotEmpty){
            _error = errorBody['error'].toString();
         }
         else {
           _error = "$defaultUserMessage (Status: ${response.statusCode})";
         }
      } else {
        _error = "$defaultUserMessage (Status: ${response.statusCode}). Response not parsable.";
        String bodySnippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print("ApiCourseProvider: Failed to parse error body. Snippet: $bodySnippet");
      }
    } catch (e) {
      _error = "$defaultUserMessage (Status: ${response.statusCode}). Failed to parse error body. Generic error: $e";
    }
  }

  @override
  void dispose() {
    print("ApiCourseProvider: Dispose called.");
    super.dispose();
  }
}