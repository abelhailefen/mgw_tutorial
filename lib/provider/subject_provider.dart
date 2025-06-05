// lib/provider/subject_provider.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mgw_tutorial/models/subject.dart'; // Import the Subject model

class SubjectProvider with ChangeNotifier {
  List<Subject> _subjects = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Subject> get subjects => _subjects;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final String _subjectsApiUrl = "https://mgw-backend.onrender.com/api/subjects";

  // Method to fetch subjects from the API
  Future<void> fetchSubjects({bool forceRefresh = false}) async {
    // Avoid refetching if data already exists and not forcing a refresh
    if (_subjects.isNotEmpty && !forceRefresh && !_isLoading) {
      print('Subjects already loaded, skipping fetch.');
      return;
    }

    _isLoading = true;
    _errorMessage = null; // Clear previous errors
    notifyListeners();

    try {
      print('Fetching subjects from $_subjectsApiUrl');
      final response = await http.get(Uri.parse(_subjectsApiUrl));
      print('Received response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Parse the response body
        final Map<String, dynamic> responseData = json.decode(response.body);

        // Access the 'data' array
        if (responseData.containsKey('data') && responseData['data'] is List) {
          List<dynamic> subjectsJson = responseData['data'];

          // Map the JSON objects to Subject models
          _subjects = subjectsJson.map((json) => Subject.fromJson(json)).toList();
          print('Successfully parsed ${_subjects.length} subjects.');
        } else {
           // Handle unexpected response structure
          _errorMessage = 'Invalid API response format: Missing or invalid "data" field.';
           print('API Error: $_errorMessage');
           _subjects = []; // Clear data on error
        }

      } else {
        // If the server did not return a 200 OK response
        _errorMessage = 'Failed to load subjects. Status: ${response.statusCode}';
        print('HTTP Error: $_errorMessage');
        _subjects = []; // Clear data on error
      }

    } catch (e) {
      // Catch any network or parsing errors
      _errorMessage = 'Error fetching subjects: $e';
      print('Network/Parsing Error: $e');
      _subjects = []; // Clear data on error
    } finally {
      _isLoading = false;
      notifyListeners(); // Notify listeners regardless of success or failure
    }
  }

  // Method to clear subjects, useful on logout
  void clearSubjects() {
    _subjects = [];
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}