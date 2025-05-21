// lib/provider/api_course_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mgw_tutorial/models/api_course.dart';

class ApiCourseProvider with ChangeNotifier {
  List<ApiCourse> _courses = []; // This list will be used for the "semester" dropdown
  bool _isLoading = false;
  String? _error;

  List<ApiCourse> get courses => [..._courses];
  bool get isLoading => _isLoading;
  String? get error => _error;

  // UPDATED API Base URL and endpoint logic
  static const String _apiBaseUrl = "https://mgw-backend.onrender.com/api"; // New base URL

  Future<void> fetchCourses() async { // Renamed from fetchSelectableCoursePackages for clarity
    if (_courses.isNotEmpty && !_isLoading) {
        return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    final url = Uri.parse('$_apiBaseUrl/course'); // New endpoint
    print("Fetching course packages/semesters from: $url");

    try {
      final response = await http.get(url, headers: {
        "Accept": "application/json",
      });

      print("Course Packages/Semesters API Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final List<dynamic> extractedData = json.decode(response.body);
        if (extractedData is List) {
          _courses = extractedData
              .map((courseJson) => ApiCourse.fromJson(courseJson as Map<String, dynamic>))
              .toList();
          _error = null;
        } else {
          _error = 'Failed to load course packages: API response was not a list.';
          _courses = [];
        }
      } else {
        _error = 'Failed to load course packages. Status: ${response.statusCode}, Body: ${response.body}';
      }
    } catch (e) {
      _error = 'An unexpected error occurred: ${e.toString()}';
      print("Exception during fetchCourses: $_error");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
   void clearError() {
    _error = null;
  }
}