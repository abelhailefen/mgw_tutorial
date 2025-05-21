// lib/provider/lesson_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mgw_tutorial/models/lesson.dart';

class LessonProvider with ChangeNotifier {
  Map<int, List<Lesson>> _lessonsBySectionId = {};
  Map<int, bool> _isLoadingForSectionId = {};
  Map<int, String?> _errorForSectionId = {};

  List<Lesson> lessonsForSection(int sectionId) => _lessonsBySectionId[sectionId] ?? [];
  bool isLoadingForSection(int sectionId) => _isLoadingForSectionId[sectionId] ?? false;
  String? errorForSection(int sectionId) => _errorForSectionId[sectionId];

  // <<< UPDATED BASE URL >>>
  static const String _apiBaseUrl = "https://lessonservice.amtprinting19.com/api";

  Future<void> fetchLessonsForSection(int sectionId, {bool forceRefresh = false}) async {
    if (!forceRefresh && _lessonsBySectionId.containsKey(sectionId) && !(_isLoadingForSectionId[sectionId] ?? false)) {
      return;
    }

    _isLoadingForSectionId[sectionId] = true;
    _errorForSectionId[sectionId] = null;
    if (forceRefresh) { // Clear existing if forcing
      _lessonsBySectionId.remove(sectionId);
    }
    notifyListeners();

    final url = Uri.parse('$_apiBaseUrl/lessons/section/$sectionId');
    print("Fetching lessons for section $sectionId from: $url");

    try {
      final response = await http.get(url, headers: {"Accept": "application/json"});
      print("Lessons API Response for section $sectionId Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final List<dynamic> extractedData = json.decode(response.body);
        if (extractedData is List) {
          _lessonsBySectionId[sectionId] = extractedData
              .map((lessonJson) => Lesson.fromJson(lessonJson as Map<String, dynamic>))
              .toList();
          _lessonsBySectionId[sectionId]?.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
          _errorForSectionId[sectionId] = null;
        } else {
          _errorForSectionId[sectionId] = 'Failed to load lessons for section $sectionId: API response was not a list.';
          _lessonsBySectionId[sectionId] = [];
        }
      } else {
        _errorForSectionId[sectionId] = 'Failed to load lessons for section $sectionId. Status: ${response.statusCode}, Body: ${response.body}';
      }
    } catch (e) {
      _errorForSectionId[sectionId] = 'An error occurred fetching lessons for section $sectionId: ${e.toString()}';
    } finally {
      _isLoadingForSectionId[sectionId] = false;
      notifyListeners();
    }
  }
  
  void clearErrorForSection(int sectionId) {
    _errorForSectionId[sectionId] = null;
  }
}