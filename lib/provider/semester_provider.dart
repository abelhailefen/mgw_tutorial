// lib/provider/semester_provider.dart
import 'dart:convert';
// import 'dart:io'; // Not strictly needed if base URL is static for all platforms
                       // and you are not doing platform-specific logic here.
import 'package:flutter/foundation.dart'; // For ChangeNotifier
import 'package:http/http.dart' as http;
import 'package:mgw_tutorial/models/semester.dart'; // Ensure this path is correct

class SemesterProvider with ChangeNotifier {
  List<Semester> _semesters = [];
  bool _isLoading = false;
  String? _error;

  // Public getters to access the state
  List<Semester> get semesters => [..._semesters]; // Return a copy to prevent direct modification
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Base URL for your API.
  // It's good practice to keep this configurable or in a central constants file for larger apps.
  static const String _apiBaseUrl = "https://mgw-backend-1.onrender.com/api";

  // Method to fetch semesters from the API
  Future<void> fetchSemesters() async {
    // Optional: Implement logic to prevent re-fetching if data is already present and considered fresh.
    // For example, you could add a timestamp and only refetch if data is older than X minutes.
    // if (_semesters.isNotEmpty && !_isLoading) {
    //   print("Semesters already loaded. Skipping fetch.");
    //   return;
    // }

    _isLoading = true;
    _error = null;
    notifyListeners(); // Notify UI that loading has started and error is cleared

    final url = Uri.parse('$_apiBaseUrl/semesters');

    try {
      print("Fetching semesters from: $url");
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json", // Good practice to specify what kind of response you accept
          // Add any other necessary headers, e.g., Authorization token if required
          // "Authorization": "Bearer YOUR_ACCESS_TOKEN",
        },
      );

      print("Semesters API Response Status: ${response.statusCode}");
      // For debugging, you might want to print the full body, but be careful with large responses.
      // print("Semesters API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        // Decode the response body into a List of dynamic objects
        final List<dynamic> extractedData = json.decode(response.body);

        // It's good practice to check if the decoded data is indeed a list
        if (extractedData is List) {
          // Map each item in the list to a Semester object using Semester.fromJson
          _semesters = extractedData
              .map((semesterJson) => Semester.fromJson(semesterJson as Map<String, dynamic>))
              .toList();
        } else {
          // This case should ideally not occur if the API contract is to return a list on success
          _error = 'Failed to load semesters: API response was not a list as expected.';
          print(_error);
          _semesters = []; // Ensure semesters list is empty if parsing fails
        }
      } else {
        // Handle HTTP errors (e.g., 404, 500)
        String errorMessage = 'Failed to load semesters. Status Code: ${response.statusCode}';
        try {
          // Try to parse a more specific error message from the API response body
          final errorData = json.decode(response.body);
          if (errorData != null && errorData['message'] != null) {
            errorMessage = errorData['message'];
            if (errorData['code'] != null) {
              errorMessage += ' (Code: ${errorData['code']})';
            }
          } else if (response.body.isNotEmpty) {
            // If no 'message' field, append the raw body for more context
            errorMessage += "\nAPI Response: ${response.body}";
          }
        } catch (e) {
          // If decoding the error body fails, just use the raw response body
          errorMessage += "\nRaw API Response: ${response.body}";
        }
        _error = errorMessage;
        print("Error fetching semesters: $_error");
      }
    } catch (e) {
      // Handle network errors or other exceptions during the HTTP request or JSON parsing
      _error = 'An unexpected error occurred while fetching semesters: ${e.toString()}';
      print("Exception during fetchSemesters: $_error");
    } finally {
      // This block always executes, whether there was an error or not
      _isLoading = false;
      notifyListeners(); // Notify UI that loading is complete and state has changed
    }
  }

  // Optional: Method to clear semesters if needed (e.g., on logout)
  void clearSemesters() {
    _semesters = [];
    _error = null;
    // _isLoading should ideally be false here or handled by the calling context
    notifyListeners();
  }
}