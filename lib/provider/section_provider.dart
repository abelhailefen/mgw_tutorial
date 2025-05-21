// lib/provider/section_provider.dart
import 'dart:convert';
import 'dart:async'; // For TimeoutException
import 'dart:io';    // For SocketException
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

  // User-friendly error messages
  static const String _networkErrorMessage = "Sorry, there seems to be a network error. Please check your connection and try again.";
  static const String _timeoutErrorMessage = "The request timed out. Please check your connection or try again later.";
  static const String _unexpectedErrorMessage = "An unexpected error occurred while fetching chapters. Please try again later.";
  static const String _failedToLoadSectionsMessage = "Failed to load chapters for this course. Please try again.";


  static const String _apiBaseUrl = "https://sectionservicefx.amtprinting19.com/api";

  Future<void> fetchSectionsForCourse(int courseId, {bool forceRefresh = false}) async {
    if (!forceRefresh && _sectionsByCourseId.containsKey(courseId) && !(_isLoadingForCourseId[courseId] ?? false)) {
      return;
    }

    _isLoadingForCourseId[courseId] = true;
    if (forceRefresh || !_sectionsByCourseId.containsKey(courseId)) {
      _errorForCourseId[courseId] = null; // Clear error if refreshing or initial load for this courseId
    }
    if (forceRefresh) {
      _sectionsByCourseId.remove(courseId);
    }
    notifyListeners();

    final url = Uri.parse('$_apiBaseUrl/sections/course/$courseId');
    print("Fetching sections for course $courseId from: $url");

    try {
      final response = await http.get(url, headers: {"Accept": "application/json"})
                                .timeout(const Duration(seconds: 20));
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
          _errorForCourseId[courseId] = 'Failed to load chapters: Unexpected API response format.';
          _sectionsByCourseId[courseId] = [];
        }
      } else {
        _handleHttpErrorResponse(response, courseId, _failedToLoadSectionsMessage);
      }
    } on TimeoutException catch (e) {
      print("TimeoutException fetching sections for course $courseId: $e");
      _errorForCourseId[courseId] = _timeoutErrorMessage;
      _sectionsByCourseId[courseId] = [];
    } on SocketException catch (e) {
      print("SocketException fetching sections for course $courseId: $e");
      _errorForCourseId[courseId] = _networkErrorMessage;
      _sectionsByCourseId[courseId] = [];
    } on http.ClientException catch (e) {
      print("ClientException fetching sections for course $courseId: $e");
      _errorForCourseId[courseId] = _networkErrorMessage;
      _sectionsByCourseId[courseId] = [];
    }
    catch (e) {
      print("Generic Exception fetching sections for course $courseId: $e");
      _errorForCourseId[courseId] = _unexpectedErrorMessage;
      _sectionsByCourseId[courseId] = [];
    } finally {
      _isLoadingForCourseId[courseId] = false;
      notifyListeners();
    }
  }

  void _handleHttpErrorResponse(http.Response response, int courseId, String defaultUserMessage) {
    try {
      final errorBody = json.decode(response.body);
      if (errorBody is Map && errorBody.containsKey('message') && errorBody['message'] != null && errorBody['message'].toString().isNotEmpty) {
        _errorForCourseId[courseId] = errorBody['message'].toString();
      } else {
         _errorForCourseId[courseId] = "$defaultUserMessage (Status: ${response.statusCode})";
      }
    } catch (e) {
       _errorForCourseId[courseId] = "$defaultUserMessage (Status: ${response.statusCode}). Response not parsable.";
    }
    _sectionsByCourseId[courseId] = [];
  }

  void clearErrorForCourse(int courseId) {
    _errorForCourseId[courseId] = null;
    // notifyListeners(); // Optional, depends on usage
  }
}