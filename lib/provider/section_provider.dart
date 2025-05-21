// lib/provider/section_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mgw_tutorial/models/section.dart';

class SectionProvider with ChangeNotifier {
  Map<int, List<Section>> _sectionsByCourseId = {};
  Map<int, bool> _isLoadingForCourseId = {};
  Map<int, String?> _errorForCourseId = {};

  List<Section> sectionsForCourse(int courseId) => _sectionsByCourseId[courseId] ?? [];
  bool isLoadingForCourse(int courseId) => _isLoadingForCourseId[courseId] ?? false;
  String? errorForCourse(int courseId) => _errorForCourseId[courseId];

  // <<< UPDATED BASE URL >>>
  static const String _apiBaseUrl = "https://sectionservicefx.amtprinting19.com/api";

  Future<void> fetchSectionsForCourse(int courseId, {bool forceRefresh = false}) async {
    if (!forceRefresh && _sectionsByCourseId.containsKey(courseId) && !(_isLoadingForCourseId[courseId] ?? false)) {
      return;
    }

    _isLoadingForCourseId[courseId] = true;
    _errorForCourseId[courseId] = null;
     if (forceRefresh) { // Clear existing if forcing
      _sectionsByCourseId.remove(courseId);
    }
    notifyListeners();

    final url = Uri.parse('$_apiBaseUrl/sections/course/$courseId');
    print("Fetching sections for course $courseId from: $url");

    try {
      final response = await http.get(url, headers: {"Accept": "application/json"});
      print("Sections API Response for course $courseId Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final List<dynamic> extractedData = json.decode(response.body);
        if (extractedData is List) {
          _sectionsByCourseId[courseId] = extractedData
              .map((sectionJson) => Section.fromJson(sectionJson as Map<String, dynamic>))
              .toList();
          _sectionsByCourseId[courseId]?.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
          _errorForCourseId[courseId] = null;
        } else {
          _errorForCourseId[courseId] = 'Failed to load sections for course $courseId: API response was not a list.';
          _sectionsByCourseId[courseId] = [];
        }
      } else {
        _errorForCourseId[courseId] = 'Failed to load sections for course $courseId. Status: ${response.statusCode}, Body: ${response.body}';
      }
    } catch (e) {
      _errorForCourseId[courseId] = 'An error occurred fetching sections for course $courseId: ${e.toString()}';
    } finally {
      _isLoadingForCourseId[courseId] = false;
      notifyListeners();
    }
  }

  void clearErrorForCourse(int courseId) {
    _errorForCourseId[courseId] = null;
  }
}