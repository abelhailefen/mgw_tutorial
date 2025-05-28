// lib/provider/section_provider.dart
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mgw_tutorial/models/section.dart'; // Import from models
import 'package:mgw_tutorial/services/database_helper.dart'; // Import DatabaseHelper


class SectionProvider with ChangeNotifier {
  Map<int, List<Section>> _sectionsByCourseId = {};
  Map<int, bool> _isLoadingForCourseId = {};
  Map<int, String?> _errorForCourseId = {};

  List<Section> sectionsForCourse(int courseId) => _sectionsByCourseId[courseId] ?? [];
  bool isLoadingForCourse(int courseId) => _isLoadingForCourseId[courseId] ?? false;
  String? errorForCourse(int courseId) => _errorForCourseId[courseId];

  final DatabaseHelper _dbHelper = DatabaseHelper();


  static const String _networkErrorMessage = "Sorry, there seems to be a network error. Please check your connection and try again.";
  static const String _timeoutErrorMessage = "The request timed out. Please check your connection or try again later.";
  static const String _unexpectedErrorMessage = "An unexpected error occurred while fetching chapters. Please try again later.";
  static const String _failedToLoadSectionsMessage = "Failed to load chapters for this course. Please try again.";


  static const String _apiBaseUrl = "https://sectionservicefx.amtprinting19.com/api";

  Future<void> fetchSectionsForCourse(int courseId, {bool forceRefresh = false}) async {
     // First, try to load from DB immediately for this course
    if (!_sectionsByCourseId.containsKey(courseId) || (_sectionsByCourseId[courseId]?.isEmpty ?? true)) {
       print("Attempting to load sections for course $courseId from DB...");
       await _loadSectionsFromDb(courseId);
       if (_sectionsByCourseId.containsKey(courseId) && _sectionsByCourseId[courseId]!.isNotEmpty) {
         print("Loaded ${_sectionsByCourseId[courseId]!.length} sections for course $courseId from DB.");
         notifyListeners();
       } else {
          print("No sections found in DB for course $courseId.");
       }
    }


    // Check if we should SKIP the network fetch
    if (!forceRefresh && (_sectionsByCourseId[courseId]?.isNotEmpty ?? false)) {
      print("Skipping network fetch for course $courseId as non-empty data is available and not forcing refresh.");
      _isLoadingForCourseId[courseId] = false;
      return;
    }

    _isLoadingForCourseId[courseId] = true;
    if (forceRefresh || (_sectionsByCourseId[courseId]?.isEmpty ?? true)) {
      _errorForCourseId[courseId] = null;
    }
    notifyListeners();


    final url = Uri.parse('$_apiBaseUrl/sections/course/$courseId');
    print("Fetching sections for course $courseId from network: $url (Force Refresh: $forceRefresh)");

    try {
      final response = await http.get(url, headers: {"Accept": "application/json"})
                                .timeout(const Duration(seconds: 20));
      print("Sections API Response for course $courseId Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final List<dynamic> extractedData = json.decode(response.body);
        if (extractedData is List) {
           final List<Section> fetchedSections = extractedData
              .map((sectionJson) => Section.fromJson(sectionJson as Map<String, dynamic>))
              .toList();

           await _saveSectionsToDb(courseId, fetchedSections);

           fetchedSections.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
           _sectionsByCourseId[courseId] = fetchedSections;
           _errorForCourseId[courseId] = null;

        } else {
          _errorForCourseId[courseId] = 'Failed to load chapters: Unexpected API response format.';
           print(_errorForCourseId[courseId]);
        }
      } else {
        _handleHttpErrorResponse(response, courseId, _failedToLoadSectionsMessage);
      }
    } on TimeoutException catch (e) {
      print("TimeoutException fetching sections for course $courseId: $e");
      _errorForCourseId[courseId] = _timeoutErrorMessage;
    } on SocketException catch (e) {
      print("SocketException fetching sections for course $courseId: $e");
      _errorForCourseId[courseId] = _networkErrorMessage;
    } on http.ClientException catch (e) {
      print("ClientException fetching sections for course $courseId: $e");
      _errorForCourseId[courseId] = _networkErrorMessage;
    }
    catch (e) {
      print("Generic Exception fetching sections for course $courseId: $e");
      _errorForCourseId[courseId] = _unexpectedErrorMessage;
    } finally {
      _isLoadingForCourseId[courseId] = false;
      notifyListeners();
    }
  }

   Future<void> _loadSectionsFromDb(int courseId) async {
    try {
      final List<Map<String, dynamic>> sectionMaps = await _dbHelper.query(
        'sections',
        where: 'courseId = ?',
        whereArgs: [courseId],
        orderBy: "'order' ASC",
      );
      final loadedSections = sectionMaps.map((map) => Section.fromMap(map)).toList();
      _sectionsByCourseId[courseId] = loadedSections;
    } catch (e) {
      print("Error loading sections for course $courseId from DB: $e");
    }
  }

   Future<void> _saveSectionsToDb(int courseId, List<Section> sectionsToSave) async {
      if (sectionsToSave.isEmpty) {
        print("No sections to save to DB for course $courseId.");
        // Optionally clear sections for this course in DB if the API returned empty
        // await _dbHelper.deleteSectionsForCourse(courseId);
        return;
     }
     try {
       print("Clearing existing sections for course $courseId from DB...");
       await _dbHelper.deleteSectionsForCourse(courseId);
       print("Saving ${sectionsToSave.length} sections for course $courseId to DB...");
       for (final section in sectionsToSave) {
         await _dbHelper.upsert('sections', section.toMap());
       }
       print("Sections for course $courseId saved to DB successfully.");
     } catch (e) {
       print("Error saving sections for course $courseId to DB: $e");
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
  }

  void clearErrorForCourse(int courseId) {
    _errorForCourseId[courseId] = null;
    notifyListeners();
  }
}