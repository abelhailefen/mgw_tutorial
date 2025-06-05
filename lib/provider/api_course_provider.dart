// lib/provider/api_course_provider.dart
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:path/path.dart' as path;
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

  static const String _networkErrorMessage = "Sorry, there seems to be a network error. Please check your connection and try again.";
  static const String _timeoutErrorMessage = "The request timed out. Please check your connection or try again later.";
  static const String _unexpectedErrorMessage = "An unexpected error occurred.";
  static const String _failedToLoadCoursesMessage = "Failed to load courses.";

  Future<void> fetchCourses({bool forceRefresh = false}) async {
    print("ApiCourseProvider: fetchCourses called (forceRefresh: $forceRefresh)");

    bool showLoading = _courses.isEmpty || forceRefresh;
    if (showLoading) {
       _isLoading = true;
       if (_courses.isEmpty || forceRefresh) {
           _error = null;
       }
       notifyListeners();
       print("ApiCourseProvider: Loading state set.");
    } else {
       print("ApiCourseProvider: Courses already loaded and not forcing refresh. Skipping initial fetch state update.");
    }

    if (_courses.isEmpty || forceRefresh) {
         // Attempt to load from DB first ONLY if the list is currently empty OR force refreshing (to show stale data quickly)
        if (_courses.isEmpty || forceRefresh) {
            try {
              print("ApiCourseProvider: Attempting to load courses from DB...");
              final List<Map<String, dynamic>> courseMaps = await _dbHelper.query('courses', orderBy: 'title ASC');
              final List<ApiCourse> cachedCourses = courseMaps.map((map) => ApiCourse.fromMap(map)).toList();

              if (cachedCourses.isNotEmpty) {
                _courses = cachedCourses;
                _error = null;
                 // _isLoading remains true if forceRefresh, set to false only if this was the *only* load attempt
                 _isLoading = forceRefresh; // Keep loading true if we are about to fetch from network
                print("ApiCourseProvider: Successfully loaded ${_courses.length} courses from DB.");
                notifyListeners(); // Notify UI to show cached data
              } else {
                 print("ApiCourseProvider: No courses found in DB.");
                 _courses = [];
                 _error = null;
                 _isLoading = true; // Still loading from network
                 notifyListeners(); // Notify that DB was empty and still loading
              }
            } catch (e, s) {
              print("ApiCourseProvider: Error loading courses from DB: $e\n$s");
              _courses = [];
              // Keep the error for potential display later if network also fails, but don't notify yet
              // unless we have no cached data at all and couldn't even attempt network
              // For now, just log the DB error and proceed to network.
              // _error = "Failed to load cached courses: $e"; // Decide if we want to surface DB errors this way
              _isLoading = true;
              // notifyListeners(); // Avoid notifying twice if network fetch is imminent
            }
        }
    }


    // Always attempt network fetch unless explicitly told not to (which isn't an option currently)
    // or if we just loaded from DB and not force refreshing (handled by the initial showLoading check)
    if (forceRefresh || _courses.isEmpty || (_error != null && _error!.contains("DB"))) { // Fetch if force, empty, or had a DB read error
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
              String parseError = "Failed to load courses: API response format is unexpected.";
              print("ApiCourseProvider: $parseError Body: ${response.body}");
               if (_courses.isEmpty) {
                  _error = parseError;
                  _isLoading = false;
                  notifyListeners();
               } else {
                  // If cached data is shown, just log the parse error, don't overwrite UI error
                  print("ApiCourseProvider: Network response parse error after showing cached data.");
                   _error = null; // Ensure error is null in this case
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

            if (!listEquals(_courses, fetchedCourses) || forceRefresh) {
                 print("ApiCourseProvider: Network data is different or force refresh. Saving and updating state.");

                await _downloadAndSaveThumbnails(fetchedCourses);
                print("ApiCourseProvider: Finished thumbnail download/save process.");

                try {
                    await _saveCoursesToDb(fetchedCourses);
                    print("ApiCourseProvider: Courses saved to DB successfully.");

                    _courses = fetchedCourses;
                    _error = null;

                } catch (dbSaveError, dbSaveStack) {
                    print("ApiCourseProvider: !!! CRITICAL DB SAVE ERROR: $dbSaveError\n$dbSaveStack");
                    // If DB save failed, keep the old data if it exists, set an error
                    if (_courses.isEmpty) { // Only set error if no cached data to fall back on
                         _error = "Failed to save courses locally after fetching. Offline mode may not work correctly."; // More user-friendly error
                    } else {
                         // If cached data is shown, log the DB error but don't overwrite UI error
                         print("ApiCourseProvider: DB save failed after showing cached data.");
                         _error = null; // Ensure error is null in this case
                    }
                }

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
                // Failed to parse error body
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
          if (_courses.isEmpty) {
             _error = _networkErrorMessage;
          } else {
             _error = null;
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
           notifyListeners();
           print("ApiCourseProvider: Fetch process finished. Notified listeners. final isLoading=$isLoading, final error=$error, final coursesCount=${_courses.length}");
        }
    } else {
         print("ApiCourseProvider: Not forcing refresh and courses list is not empty. Skipping network fetch.");
          _isLoading = false; // Ensure loading is false if we truly skipped the fetch
          notifyListeners();
    }

  }

  Future<void> _saveCoursesToDb(List<ApiCourse> coursesToSave) async {
     print("ApiCourseProvider: Starting DB save process...");
     try {
        // This is where we orchestrate the DB save, including cleaning up old data and files
        final db = await _dbHelper.database;
        List<String> oldThumbnailPaths = [];

        // --- Step 1: Transactionally delete old data and get old paths ---
        print("ApiCourseProvider: Deleting old courses and getting paths...");
        try {
           await db.transaction((txn) async {
              oldThumbnailPaths = await _dbHelper.deleteCoursesInTxn(txn);
           });
           print("ApiCourseProvider: Old courses deleted from DB. ${oldThumbnailPaths.length} paths collected for file deletion.");
        } catch (e, s) {
           print("ApiCourseProvider: Error during old course deletion transaction: $e\n$s");
           // Re-throw so fetchCourses can catch it and decide how to handle the state
           rethrow;
        }

        // --- Step 2: Delete old thumbnail files (outside transaction) ---
        if (oldThumbnailPaths.isNotEmpty) {
          print("ApiCourseProvider: Deleting old thumbnail files...");
          await _dbHelper.deleteThumbnailFiles(oldThumbnailPaths);
           print("ApiCourseProvider: Old thumbnail files deletion attempted.");
        } else {
           print("ApiCourseProvider: No old thumbnail files to delete.");
        }

        // --- Step 3: Transactionally insert new data ---
        if (coursesToSave.isEmpty) {
           print("ApiCourseProvider: No new courses to save to DB.");
           // The old data was already cleared in step 1.
           return;
        }

        print("ApiCourseProvider: Saving ${coursesToSave.length} new courses to DB...");
        try {
           await db.transaction((txn) async {
              await _dbHelper.insertCoursesInTxn(txn, coursesToSave);
           });
           print("ApiCourseProvider: New courses saved to DB successfully.");
        } catch (e, s) {
          print("ApiCourseProvider: Error during new course insertion transaction: $e\n$s");
          // Re-throw so fetchCourses can catch it
          rethrow;
        }

     } catch (e, s) {
       print("ApiCourseProvider: Overall Error during _saveCoursesToDb process: $e");
       print("Stacktrace: $s");
       // Re-throw the ultimate error
       rethrow;
     }
   }

   bool listEquals(List<ApiCourse> a, List<ApiCourse> b) {
      if (a.length != b.length) return false;
      for(int i = 0; i < a.length; i++) {
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
              a[i].thumbnail != b[i].thumbnail ||
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
              a[i].category?.name != b[i].category?.name
             ) {
              return false;
           }
      }
      return true;
   }

   bool listEqualsString(List<String> a, List<String> b) {
       if (a.length != b.length) return false;
       for(int i = 0; i < a.length; i++) {
           if (a[i] != b[i]) return false;
       }
       return true;
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
                    print("ApiCourseProvider: Invalid scheme for thumbnail URL for course ${course.id}: $imageUrl");
                    course.localThumbnailPath = null;
                    continue;
                 }
               } catch(e) {
                  print("ApiCourseProvider: Invalid thumbnail URL for course ${course.id}: $imageUrl. Error: $e");
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
                course.localThumbnailPath = null;
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

  @override
  void dispose() {
    print("ApiCourseProvider: Dispose called.");
    super.dispose();
  }
}