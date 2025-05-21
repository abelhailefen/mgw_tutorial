// lib/provider/api_course_provider.dart
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mgw_tutorial/models/api_course.dart';

class ApiCourseProvider with ChangeNotifier {
  List<ApiCourse> _courses = [];
  bool _isLoading = false;
  String? _error;

  List<ApiCourse> get courses => [..._courses];
  bool get isLoading => _isLoading;
  String? get error => _error;

  static const String _networkErrorMessage = "Sorry, there seems to be a network error. Please check your connection and try again.";
  static const String _timeoutErrorMessage = "The request timed out. Please check your connection or try again later.";
  static const String _unexpectedErrorMessage = "An unexpected error occurred while fetching courses. Please try again later.";
  static const String _failedToLoadCoursesMessage = "Failed to load courses. Please try again.";

  static const String _apiBaseUrl = "https://mgw-backend.onrender.com/api"; // Example

  Future<void> fetchCourses({bool forceRefresh = false}) async {
    // If not forcing refresh, and data exists (and not currently loading), return.
    // This is more relevant when fetching from an API.
    if (!forceRefresh && _courses.isNotEmpty && !_isLoading) {
      // print("Courses already loaded and not forcing refresh. Skipping API call.");
      return;
    }

    _isLoading = true;
    if (forceRefresh || _courses.isEmpty) {
      _error = null;
    }
    if (forceRefresh) {
      _courses = []; // Clear existing courses if forcing refresh
    }
    notifyListeners();

    // --- THIS SECTION WOULD BE FOR A REAL API CALL ---
    // final url = Uri.parse('$_apiBaseUrl/course');
    // print("Fetching courses from: $url (Force Refresh: $forceRefresh)");
    // try {
    //   final response = await http.get(url, headers: {
    //     "Accept": "application/json",
    //   }).timeout(const Duration(seconds: 20));
    //   print("Courses API Response Status: ${response.statusCode}");

    //   if (response.statusCode == 200) {
    //     final List<dynamic> extractedData = json.decode(response.body);
    //     if (extractedData is List) {
    //       _courses = extractedData
    //           .map((courseJson) => ApiCourse.fromJson(courseJson as Map<String, dynamic>))
    //           .toList();
    //       _error = null;
    //     } else {
    //       _error = "Failed to load courses: API response was not a list.";
    //       _courses = [];
    //     }
    //   } else {
    //     _handleHttpErrorResponse(response, _failedToLoadCoursesMessage);
    //   }
    // } on TimeoutException catch (e) {
    //   print("TimeoutException fetching courses: $e");
    //   _error = _timeoutErrorMessage;
    //   _courses = [];
    // } on SocketException catch (e) {
    //   print("SocketException fetching courses: $e");
    //   _error = _networkErrorMessage;
    //   _courses = [];
    // } on http.ClientException catch (e) {
    //   print("ClientException fetching courses: $e");
    //   _error = _networkErrorMessage;
    //   _courses = [];
    // } catch (e) {
    //   print("Generic Exception during fetchCourses: $e");
    //   _error = _unexpectedErrorMessage;
    //   _courses = [];
    // } finally {
    //   _isLoading = false;
    //   notifyListeners();
    // }
    // --- END OF REAL API CALL SECTION ---

    // --- For Development with Hardcoded/Delayed Data (if API is not ready) ---
    // This part simulates a fetch if the API section above is commented out.
    // If LibraryContentView directly uses hardcoded data, this provider's fetch might not be called.
    // However, if you intend for LibraryContentView to use this provider eventually,
    // this structure is useful.
    print("ApiCourseProvider: Simulating fetch (Force Refresh: $forceRefresh). API call is commented out.");
    try {
        await Future.delayed(const Duration(milliseconds: 300)); // Simulate delay
        // If you were to populate _courses here from a hardcoded list:
        // if (_courses.isEmpty || forceRefresh) {
        //   _courses = [ /* your hardcoded ApiCourse objects for testing */ ];
        // }
        // Since LibraryContentView has its own hardcoded data, we just simulate success/failure here.
        // To test error state with hardcoded:
        // if (forceRefresh) throw SocketException("Simulated network error on refresh");
        _error = null; // Simulate success
    } catch (e) {
        if (e is SocketException) {
            _error = _networkErrorMessage;
        } else if (e is TimeoutException) {
            _error = _timeoutErrorMessage;
        } else {
            _error = _unexpectedErrorMessage;
        }
        _courses = [];
        print("ApiCourseProvider simulated error: $e");
    } finally {
        _isLoading = false;
        notifyListeners();
    }
  }

  void _handleHttpErrorResponse(http.Response response, String defaultUserMessage) {
    // This would be used if the real API call section was active
    try {
      final errorBody = json.decode(response.body);
      if (errorBody is Map && errorBody.containsKey('message') && errorBody['message'] != null && errorBody['message'].toString().isNotEmpty) {
        _error = errorBody['message'].toString();
      } else {
        _error = "$defaultUserMessage (Status: ${response.statusCode})";
      }
    } catch (e) {
      _error = "$defaultUserMessage (Status: ${response.statusCode}). Response not parsable.";
    }
    _courses = [];
  }

  void clearError() {
    _error = null;
  }
}