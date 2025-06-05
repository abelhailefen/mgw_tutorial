// lib/provider/exam_provider.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mgw_tutorial/models/exam.dart';

class ExamProvider with ChangeNotifier {
  final Map<int, List<Exam>> _examsCache = {};
  final Map<int, bool> _loadingStatus = {};
  final Map<int, String?> _errorMessages = {};

  bool isLoading(int chapterId) => _loadingStatus[chapterId] ?? false;
  String? getErrorMessage(int chapterId) => _errorMessages[chapterId];
  List<Exam>? getExams(int chapterId) => _examsCache[chapterId];

  final String _baseApiUrl = "https://mgw-backend.onrender.com/api/exams/chapter/"; 

  Future<void> fetchExamsForChapter(int chapterId, {bool forceRefresh = false}) async {
    if (_examsCache.containsKey(chapterId) && !forceRefresh && !(_loadingStatus[chapterId] ?? false)) {
      return;
    }

    _loadingStatus[chapterId] = true;
    _errorMessages[chapterId] = null;
    notifyListeners();

    try {
      final url = '$_baseApiUrl$chapterId';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        // The API response has a 'data' field which is a list of exams
        if (responseData.containsKey('data') && responseData['data'] is List) {
          List<dynamic> examsJson = responseData['data'];

          // Map the JSON objects to Exam models
          List<Exam> fetchedExams = examsJson.map((json) => Exam.fromJson(json)).toList();

          _examsCache[chapterId] = fetchedExams; // Cache the fetched list
        } else {
           // Handle unexpected response structure
          _errorMessages[chapterId] = 'Invalid API response format for chapter $chapterId: Missing or invalid "data" field.';
           _examsCache[chapterId] = []; // Store empty list on format error
        }
      } else {
        // If the server did not return a 200 OK response
        _errorMessages[chapterId] = 'Failed to load exams for chapter $chapterId. Status: ${response.statusCode}';
        _examsCache[chapterId] = []; // Store empty list on HTTP error
      }
    } catch (e) {
      // Catch any network or parsing errors
      _errorMessages[chapterId] = 'Error fetching exams for chapter $chapterId: $e';
      _examsCache[chapterId] = []; // Store empty list on generic error
    } finally {
      _loadingStatus[chapterId] = false; // Set loading to false for this chapter
      notifyListeners(); // Notify listeners regardless of success or failure
    }
  }

  // Method to clear all cached exams
  void clearExams() {
    _examsCache.clear();
    _loadingStatus.clear();
    _errorMessages.clear();
    notifyListeners(); // Notify listeners that data is cleared
  }
}