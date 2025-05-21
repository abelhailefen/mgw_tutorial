// lib/provider/semester_provider.dart
import 'dart:convert';
import 'dart:async'; // For TimeoutException
import 'dart:io';    // For SocketException
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

  static const String _networkErrorMessage = "Sorry, there seems to be a network error. Please check your connection and try again.";
  static const String _timeoutErrorMessage = "The request timed out. Please check your connection or try again later.";
  static const String _unexpectedErrorMessage = "An unexpected error occurred while fetching semesters. Please try again later.";
  static const String _failedToLoadSemestersMessage = "Failed to load semesters. Please try again.";

  static const String _apiBaseUrl = "https://mgw-backend.onrender.com/api";

  Future<void> fetchSemesters({bool forceRefresh = false}) async {
    if (!forceRefresh && _semesters.isNotEmpty && !_isLoading) {
      // print("Semesters already loaded and not forcing refresh. Skipping fetch.");
      return;
    }

    _isLoading = true;
    // Clear error if refreshing OR if it's an initial load (semesters list is empty)
    if (forceRefresh || _semesters.isEmpty) {
      _error = null;
    }
    // If forcing refresh, also clear existing data to show loading indicator properly
    if (forceRefresh) {
      _semesters = [];
    }
    notifyListeners(); // Notify for loading state and potential data clearing

    final url = Uri.parse('$_apiBaseUrl/semesters');
    print("Fetching semesters from: $url (Force Refresh: $forceRefresh)");

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      ).timeout(const Duration(seconds: 20));

      print("Semesters API Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final List<dynamic> extractedData = json.decode(response.body);
        if (extractedData is List) {
          _semesters = extractedData
              .map((semesterJson) => Semester.fromJson(semesterJson as Map<String, dynamic>))
              .toList();
          _error = null;
        } else {
          _error = "Failed to load semesters: Unexpected API response format.";
          _semesters = [];
        }
      } else {
        _handleHttpErrorResponse(response, _failedToLoadSemestersMessage);
      }
    } on TimeoutException catch (e) {
      print("TimeoutException fetching semesters: $e");
      _error = _timeoutErrorMessage;
      _semesters = []; // Ensure data is cleared on timeout
    } on SocketException catch (e) {
      print("SocketException fetching semesters: $e");
      _error = _networkErrorMessage;
      _semesters = []; // Ensure data is cleared on socket error
    } on http.ClientException catch (e) {
      print("ClientException fetching semesters: $e");
      _error = _networkErrorMessage;
      _semesters = []; // Ensure data is cleared on client error
    } catch (e) {
      print("Generic Exception during fetchSemesters: $e");
      _error = _unexpectedErrorMessage;
      _semesters = []; // Ensure data is cleared on generic error
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
      } else {
        _error = "$defaultUserMessage (Status: ${response.statusCode})";
      }
    } catch (e) {
      _error = "$defaultUserMessage (Status: ${response.statusCode}). Response not parsable.";
    }
    _semesters = [];
  }

  void clearError() {
    _error = null;
  }

  void clearSemesters() {
    _semesters = [];
    _error = null;
    notifyListeners();
  }
}