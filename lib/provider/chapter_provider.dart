// lib/provider/chapter_provider.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mgw_tutorial/models/chapter.dart';

class ChapterProvider with ChangeNotifier {
  final Map<int, List<Chapter>> _chaptersCache = {};
  final Map<int, bool> _loadingStatus = {};
  final Map<int, String?> _errorMessages = {};

  bool isLoading(int subjectId) => _loadingStatus[subjectId] ?? false;
  String? getErrorMessage(int subjectId) => _errorMessages[subjectId];
  List<Chapter>? getChapters(int subjectId) => _chaptersCache[subjectId];

  final String _baseApiUrl = "https://mgw-backend.onrender.com/api/chapters/subject/";

  Future<void> fetchChaptersForSubject(int subjectId, {bool forceRefresh = false}) async {
    if (_chaptersCache.containsKey(subjectId) && !forceRefresh && !(_loadingStatus[subjectId] ?? false)) {
      return;
    }

    _loadingStatus[subjectId] = true;
    _errorMessages[subjectId] = null;
    notifyListeners();

    try {
      final url = '$_baseApiUrl$subjectId';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData.containsKey('data') && responseData['data'] is List) {
          List<dynamic> chaptersJson = responseData['data'];
          List<Chapter> fetchedChapters = chaptersJson.map((json) => Chapter.fromJson(json)).toList();

          fetchedChapters.sort((a, b) => a.order.compareTo(b.order));

          _chaptersCache[subjectId] = fetchedChapters;
        } else {
          _errorMessages[subjectId] = 'Invalid API response format for subject $subjectId: Missing or invalid "data" field.';
          _chaptersCache[subjectId] = [];
        }
      } else {
        _errorMessages[subjectId] = 'Failed to load chapters for subject $subjectId. Status: ${response.statusCode}';
        _chaptersCache[subjectId] = [];
      }
    } catch (e) {
      _errorMessages[subjectId] = 'Error fetching chapters for subject $subjectId: $e';
      _chaptersCache[subjectId] = [];
    } finally {
      _loadingStatus[subjectId] = false;
      notifyListeners();
    }
  }

  void clearChapters() {
    _chaptersCache.clear();
    _loadingStatus.clear();
    _errorMessages.clear();
    notifyListeners();
  }
}