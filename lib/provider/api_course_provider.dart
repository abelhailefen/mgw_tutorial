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

  static const String _apiBaseUrl = "https://mgw-backend.onrender.com/api";

  Future<void> fetchCourses({bool forceRefresh = false}) async {
    if (!forceRefresh && _courses.isNotEmpty && !_isLoading) {
      return;
    }

    _isLoading = true;
    if (forceRefresh || _courses.isEmpty) {
      _error = null;
    }
    if (forceRefresh) {
      _courses = [];
    }
    notifyListeners();

    final url = Uri.parse('$_apiBaseUrl/course');
    print("Fetching courses from: $url (Force Refresh: $forceRefresh)");
    try {
      final response = await http.get(url, headers: {
        "Accept": "application/json",
      }).timeout(const Duration(seconds: 30));
      print("Courses API Response Status: ${response.statusCode}");
      

      if (response.statusCode == 200) {
        final dynamic decodedBody = json.decode(response.body);

        if (decodedBody is List) { 
          final List<dynamic> extractedData = decodedBody;
          _courses = extractedData
              .map((courseJson) {
                try {
                  return ApiCourse.fromJson(courseJson as Map<String, dynamic>);
                } catch (e) {
                  print("Error parsing individual course JSON (from list): $e");
                  print("Problematic course JSON (from list): $courseJson");
                  return null;
                }
              })
              .whereType<ApiCourse>()
              .toList();
          _error = null;
        } else if (decodedBody is Map<String, dynamic> && decodedBody.containsKey('courses') && decodedBody['courses'] is List) {
          // This handles the case where it might be an object with a 'courses' key
          final List<dynamic> extractedData = decodedBody['courses'];
          _courses = extractedData
              .map((courseJson) {
                try {
                  return ApiCourse.fromJson(courseJson as Map<String, dynamic>);
                } catch (e) {
                  print("Error parsing individual course JSON (from map): $e");
                  print("Problematic course JSON (from map): $courseJson");
                  return null;
                }
              })
              .whereType<ApiCourse>()
              .toList();
          _error = null;
        }
        else {
          _error = "Failed to load courses: API response format is not a recognized list or object with a 'courses' key.";
          _courses = [];
        }
      } else {
        _handleHttpErrorResponse(response, _failedToLoadCoursesMessage);
      }
    } on TimeoutException catch (e) {
      print("TimeoutException fetching courses: $e");
      _error = _timeoutErrorMessage;
      _courses = [];
    } on SocketException catch (e) {
      print("SocketException fetching courses: $e");
      _error = _networkErrorMessage;
      _courses = [];
    } on http.ClientException catch (e) {
      print("ClientException fetching courses: $e");
      _error = _networkErrorMessage;
      _courses = [];
    } catch (e, s) {
      print("Generic Exception during fetchCourses: $e");
      print("Stacktrace: $s");
      if (e is FormatException && e.source is List && e.message.contains("is not a subtype of type 'Map<String, dynamic>'")) {
         _error = "Failed to parse courses: API returned a list, but items inside were not valid course objects. $e";
      } else {
        _error = _unexpectedErrorMessage;
      }
      _courses = [];
    } finally {
      _isLoading = false;
      notifyListeners();
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
    _courses = [];
  }

  void clearError() {
    _error = null;
  }
}