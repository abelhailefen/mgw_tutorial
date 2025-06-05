// lib/provider/api_course_provider.dart
import 'dart:convert';
import 'dart:async';
import 'dart:io'; // For SocketException and File
import 'package:flutter/foundation.dart'; // For listEquals
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart' as sqflite; // Import sqflite to use ConflictAlgorithm
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

  static const String _apiBaseUrl = "https://courseservice.anbesgames.com/api";
  static const String _thumbnailBaseUrl = "https://courseservice.anbesgames.com"; // Defined here for thumbnail download


  // Define reusable error messages based on existing l10n keys if possible
  static const String _networkErrorMessage = "Sorry, there seems to be a network error. Please check your connection and try again.";
  static const String _timeoutErrorMessage = "The request timed out. Please check your connection or try again later.";
  static const String _unexpectedErrorMessage = "An unexpected error occurred.";
  static const String _failedToLoadCoursesMessage = "Failed to load courses.";


  Future<void> fetchCourses({bool forceRefresh = false}) async {
    print("ApiCourseProvider: fetchCourses called (forceRefresh: $forceRefresh)");

    // Determine if we should show a loading indicator
    // Show if the list is empty OR we are forcing a refresh (meaning network fetch will happen)
    bool showLoading = _courses.isEmpty || forceRefresh;
    if (showLoading) {
       _isLoading = true;
       // Clear error only if courses are empty OR explicitly refreshing
       if (_courses.isEmpty || forceRefresh) {
           _error = null;
       }
       notifyListeners(); // Notify UI about initial loading state
       print("ApiCourseProvider: Loading state set.");
    } else {
       // If courses are already loaded and not forcing refresh, just return.
       print("ApiCourseProvider: Courses already loaded and not forcing refresh. Skipping fetch.");
       return;
    }


    // Attempt to load from DB first ONLY if the list is currently empty
    if (_courses.isEmpty) {
      try {
        print("ApiCourseProvider: Attempting to load courses from DB...");
        final List<Map<String, dynamic>> courseMaps = await _dbHelper.query('courses', orderBy: 'title ASC');
        final List<ApiCourse> cachedCourses = courseMaps.map((map) => ApiCourse.fromMap(map)).toList();

        if (cachedCourses.isNotEmpty) {
          _courses = cachedCourses;
          _error = null; // Clear error if we successfully loaded from DB
          // Keep _isLoading true if forceRefresh, otherwise set to false
          _isLoading = forceRefresh;
          print("ApiCourseProvider: Successfully loaded ${_courses.length} courses from DB.");
          notifyListeners(); // Notify UI to show cached data
        } else {
           print("ApiCourseProvider: No courses found in DB.");
           _courses = []; // Ensure courses is empty
           _error = null; // Clear error if DB was just empty
           _isLoading = true; // Still loading from network
           notifyListeners(); // Notify that DB was empty and still loading
        }

      } catch (e, s) {
        print("ApiCourseProvider: Error loading courses from DB: $e\n$s");
        // If DB load fails entirely, _courses remains empty, and we continue to network fetch
        _courses = []; // Ensure list is empty if DB load failed
        _error = "Failed to load cached courses: $e"; // Keep the error for potential display later if network also fails
        _isLoading = true; // Still loading for network fetch
        notifyListeners(); // Notify about DB failure and continued loading
      }
    } else {
       // If _courses was NOT empty, it means we are force refreshing and already showed DB data.
       // _isLoading is already true from the initial check.
       print("ApiCourseProvider: Courses already in state, proceeding to network fetch (likely force refresh).");
    }


    // Fetch from Network (rely on http exceptions for network issues)
    print("ApiCourseProvider: Attempting network fetch from $_apiBaseUrl/course");
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
           if (_courses.isEmpty) { // Only notify if no cached data was displayed
              _isLoading = false; // Set loading to false on parse error
              notifyListeners();
           }
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

        // Check if the fetched list is different from the currently displayed list
        // Avoid unnecessary DB writes and UI updates if data hasn't changed
        if (!listEquals(_courses, fetchedCourses) || forceRefresh) {
             print("ApiCourseProvider: Network data is different or force refresh. Saving and updating state.");

            // NEW: Download and save images BEFORE saving to DB
            // Pass the fetchedCourses list so thumbnails are downloaded for the new data
            await _downloadAndSaveThumbnails(fetchedCourses);
            print("ApiCourseProvider: Finished thumbnail download/save process.");

            // NEW: Save the updated courses (which now include local paths) to DB
            // _saveCoursesToDb handles clearing old data and thumbnail files
            await _saveCoursesToDb(fetchedCourses);
            // print("ApiCourseProvider: Courses saved to DB."); // Log moved inside _saveCoursesToDb

            _courses = fetchedCourses; // Update the provider's state with the new list
            _error = null; // Clear any previous error on network success

        } else {
           print("ApiCourseProvider: Network data is same as current data. No DB write or state update.");
           _error = null; // Ensure error is null if network fetch was successful and data unchanged
        }


      } else {
         // Handle HTTP error response (e.g., 404, 500)
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
           // Show network error only if no cached data was displayed
           _error = apiError;
           print("ApiCourseProvider: Network fetch failed, no cached data. Error set: $_error");
         } else {
             // If cached data exists, just log the network error and don't show it over the data
             print("ApiCourseProvider: Network fetch failed after showing cached data: $apiError");
             _error = null; // Ensure error is null in this case
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
      if (_courses.isEmpty) {
         _error = _networkErrorMessage;
      } else {
         _error = null; // Hide network error if cached data is visible
      }
    } on http.ClientException catch (e, s) {
       print("ApiCourseProvider: HTTP Client Exception: ${e.message}");
       print("Stacktrace: $s");
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
       notifyListeners(); // Always notify listeners at the end
       print("ApiCourseProvider: Fetch process finished. Notified listeners. final isLoading=$isLoading, final error=$error");
    }
  }

  // Helper method for saving courses to DB (transactionally)
  // Includes deleting old courses and their thumbnails
  Future<void> _saveCoursesToDb(List<ApiCourse> coursesToSave) async {
     try {
        // deleteAllCourses now handles file cleanup before deleting DB records
        await _dbHelper.deleteAllCourses();
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
       print("ApiCourseProvider: Courses saved to DB successfully."); // <-- Log only on transaction success
     } catch (e, s) {
       print("ApiCourseProvider: Error saving courses to DB: $e");
       print("Stacktrace: $s");
       // This is a critical error for offline functionality, but we don't necessarily
       // want to overwrite the UI error state if a more relevant network error occurred.
       // The fetchCourses method already handles setting the UI error based on whether
       // cached data exists.
     }
   }

   // Helper function to compare lists for changes (shallow comparison)
   // Use this to avoid unnecessary DB writes and UI updates if fetched data is the same
   bool listEquals(List<ApiCourse> a, List<ApiCourse> b) {
      if (a.length != b.length) return false;
      for(int i = 0; i < a.length; i++) {
          // Compare relevant fields for equality check
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
              a[i].thumbnail != b[i].thumbnail || // Compare network thumbnail URL
              a[i].videoUrl != b[i].videoUrl ||
              a[i].isTopCourse != b[i].isTopCourse ||
              a[i].status != b[i].status ||
              a[i].isVideoCourse != b[i].isVideoCourse ||
              a[i].isFreeCourse != b[i].isFreeCourse ||
              a[i].multiInstructor != b[i].multiInstructor ||
              a[i].creator != b[i].creator ||
              a[i].createdAt.toIso8601String() != b[i].createdAt.toIso8601String() || // Compare date strings
              a[i].updatedAt.toIso8601String() != b[i].updatedAt.toIso8601String() || // Compare date strings
              // Shallow compare lists (may need deep compare if order/content matters)
              !listEqualsString(a[i].outcomes, b[i].outcomes) ||
              !listEqualsString(a[i].requirements, b[i].requirements) ||
              // Compare category by ID and name
              a[i].category?.id != b[i].category?.id ||
              a[i].category?.name != b[i].category?.name
             ) {
              return false;
           }
      }
      return true;
   }

   // Helper for shallow comparing List<String>
   bool listEqualsString(List<String> a, List<String> b) {
       if (a.length != b.length) return false;
       for(int i = 0; i < a.length; i++) {
           if (a[i] != b[i]) return false;
       }
       return true;
   }


  Future<void> _loadCoursesFromDb() async {
    try {
      print("ApiCourseProvider: Loading courses from DB...");
      final List<Map<String, dynamic>> courseMaps = await _dbHelper.query('courses', orderBy: 'title ASC');
      _courses = courseMaps.map((map) => ApiCourse.fromMap(map)).toList();
      print("ApiCourseProvider: Loaded ${_courses.length} courses from DB.");
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
      // Assuming DatabaseHelper provides the directory path correctly
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
                    course.localThumbnailPath = null; // Ensure local path is null if URL is bad
                    continue; // Skip this thumbnail
                 }
               } catch(e) {
                  print("ApiCourseProvider: Invalid thumbnail URL for course ${course.id}: $imageUrl. Error: $e");
                   course.localThumbnailPath = null; // Ensure local path is null if URL is bad
                  continue; // Skip this thumbnail
               }

              String fileExtension = 'jpg'; // Default extension
              String pathSegment = uri.path;
              int lastDot = pathSegment.lastIndexOf('.');
              if (lastDot != -1 && pathSegment.length > lastDot + 1) {
                 fileExtension = pathSegment.substring(lastDot + 1).split('?').first; // Handle query params in extension
               } else if (uri.queryParameters.containsKey('format')) {
                   fileExtension = uri.queryParameters['format']!;
               } else {
                 print("ApiCourseProvider: Could not determine file extension for thumbnail URL: $imageUrl. Using default '$fileExtension'.");
               }

              // Create a unique filename. Using course ID is good.
              final fileName = 'course_${course.id}_thumb.${fileExtension}';
              final localPath = path.join(thumbnailDir.path, fileName);
              final localFile = File(localPath);

               if (await localFile.exists()) {
                   // Assign the existing local path to the course object
                   course.localThumbnailPath = localPath;
                   continue; // Skip download for this course
               }

              print("ApiCourseProvider: Downloading thumbnail for course ${course.id} from $imageUrl to $localPath");
              final response = await client.get(uri).timeout(const Duration(seconds: 15));

              if (response.statusCode == 200) {
                await localFile.writeAsBytes(response.bodyBytes);
                course.localThumbnailPath = localPath; // Update the course object with the new local path
                print("ApiCourseProvider: Saved thumbnail for course ${course.id}.");
              } else {
                print("ApiCourseProvider: Failed to download thumbnail for course ${course.id} (Status: ${response.statusCode}): $imageUrl");
                // Leave localThumbnailPath as null, the UI will try network on next attempt
                course.localThumbnailPath = null; // Explicitly set to null on failure
              }
            } on TimeoutException catch (e) {
               print("ApiCourseProvider: Timeout downloading thumbnail for course ${course.id} ($imageUrl): $e");
                course.localThumbnailPath = null;
            } on http.ClientException catch (e) {
               print("ApiCourseProvider: HTTP Client Error downloading thumbnail for course ${course.id} ($imageUrl): ${e.message}");
                course.localThumbnailPath = null;
            } catch (e, s) {
              print("ApiCourseProvider: Generic Error downloading/saving thumbnail for course ${course.id} ($imageUrl): $e");
              print("Stacktrace: $s");
               course.localThumbnailPath = null;
            }
          } else {
             print("ApiCourseProvider: No thumbnail URL for course ${course.id}");
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