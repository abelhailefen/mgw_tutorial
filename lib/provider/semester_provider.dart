// lib/provider/semester_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mgw_tutorial/models/semester.dart';

class SemesterProvider with ChangeNotifier {
  List<Semester> _semesters = [];
  bool _isLoading = false;
  String? _error;

  List<Semester> get semesters => [..._semesters];
  bool get isLoading => _isLoading;
  String? get error => _error;

  static const String _apiBaseUrl = "https://mgw-backend.onrender.com/api";

  // MODIFIED to accept forceRefresh
  Future<void> fetchSemesters({bool forceRefresh = false}) async {
    // If not forcing refresh, and data exists and not currently loading, return.
    if (!forceRefresh && _semesters.isNotEmpty && !_isLoading) {
      // print("Semesters already loaded. Skipping fetch.");
      // notifyListeners(); // Optionally notify if UI needs to react to "using cached" state
      return;
    }

    _isLoading = true;
    // If forcing refresh, clear existing data and error to ensure a clean fetch
    if (forceRefresh) {
      _semesters = [];
      _error = null;
    }
    // If not forcing but list is empty (initial load or previous error), clear error.
    else if (_semesters.isEmpty) {
        _error = null;
    }
    notifyListeners();

    final url = Uri.parse('$_apiBaseUrl/semesters');

    try {
      print("Fetching semesters from: $url (Force Refresh: $forceRefresh)");
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      );

      print("Semesters API Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final List<dynamic> extractedData = json.decode(response.body);
        if (extractedData is List) {
          _semesters = extractedData
              .map((semesterJson) => Semester.fromJson(semesterJson as Map<String, dynamic>))
              .toList();
          _error = null; // Clear error on success
        } else {
          _error = 'Failed to load semesters: API response was not a list as expected.';
          _semesters = [];
        }
      } else {
        String errorMessage = 'Failed to load semesters. Status Code: ${response.statusCode}';
        // ... (your existing error message parsing logic) ...
        try {
          final errorData = json.decode(response.body);
          if (errorData != null && errorData['message'] != null) {
            errorMessage = errorData['message'];
            if (errorData['code'] != null) {
              errorMessage += ' (Code: ${errorData['code']})';
            }
          } else if (response.body.isNotEmpty) {
            errorMessage += "\nAPI Response: ${response.body}";
          }
        } catch (e) {
          errorMessage += "\nRaw API Response: ${response.body}";
        }
        _error = errorMessage;
      }
    } catch (e) {
      _error = 'An unexpected error occurred while fetching semesters: ${e.toString()}';
      print("Exception during fetchSemesters: $_error");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSemesters() {
    _semesters = [];
    _error = null;
    notifyListeners();
  }
}