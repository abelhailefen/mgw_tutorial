// lib/provider/api_course_provider.dart
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mgw_tutorial/models/api_course.dart'; // Import from models
import 'package:mgw_tutorial/services/database_helper.dart'; // Import DatabaseHelper


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
         notifyListeners();
       } else {
          print("No courses found in DB.");
       }
    }

    // Check if we should SKIP the network fetch
    // Skip if not force refreshing AND we already have NON-EMPTY data
    if (!forceRefresh && _courses.isNotEmpty) {
      print("Skipping network fetch for courses as non-empty data is available and not forcing refresh.");
      _isLoading = false;
      return;
    }

    _isLoading = true;
    if (forceRefresh || _courses.isEmpty) {
       _error = null;
    }
    notifyListeners();


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
        }

        final List<ApiCourse> fetchedCourses = extractedData
            .map((courseJson) {
              try {
                return ApiCourse.fromJson(courseJson as Map<String, dynamic>);
              } catch (e) {
                print("Error parsing individual course JSON: $e");
                print("Problematic course JSON: $courseJson");
                return null;
              }
            })
            .whereType<ApiCourse>()
            .toList();

        await _saveCoursesToDb(fetchedCourses);
        _courses = fetchedCourses;
        _error = null;

      } else {
         _handleHttpErrorResponse(response, _failedToLoadCoursesMessage);
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
      notifyListeners();
    }
  }

  Future<void> _loadCoursesFromDb() async {
    try {
      final List<Map<String, dynamic>> courseMaps = await _dbHelper.query('courses', orderBy: 'title ASC');
      _courses = courseMaps.map((map) => ApiCourse.fromMap(map)).toList();
    } catch (e) {
      print("Error loading courses from DB: $e");
    }
  }

   Future<void> _saveCoursesToDb(List<ApiCourse> coursesToSave) async {
     if (coursesToSave.isEmpty) {
       print("No courses to save to DB.");
       return;
     }
     try {
        print("Clearing existing courses from DB...");
       await _dbHelper.deleteAllCourses();
       print("Saving ${coursesToSave.length} courses to DB...");
       for (final course in coursesToSave) {
         await _dbHelper.upsert('courses', course.toMap());
       }
       print("Courses saved to DB successfully.");
     } catch (e) {
       print("Error saving courses to DB: $e");
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