// lib/provider/subject_provider.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mgw_tutorial/models/subject.dart';

class SubjectProvider with ChangeNotifier {
  List<Subject> _subjects = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Subject> get subjects => _subjects;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final String _subjectsApiUrl = "https://mgw-backend.onrender.com/api/subjects";

  Future<void> fetchSubjects({bool forceRefresh = false}) async {
    if (_subjects.isNotEmpty && !forceRefresh && !_isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse(_subjectsApiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData.containsKey('data') && responseData['data'] is List) {
          List<dynamic> subjectsJson = responseData['data'];
          _subjects = subjectsJson.map((json) => Subject.fromJson(json)).toList();
        } else {
          _errorMessage = 'Invalid API response format: Missing or invalid "data" field.';
          _subjects = [];
        }
      } else {
        _errorMessage = 'Failed to load subjects. Status: ${response.statusCode}';
        _subjects = [];
      }
    } catch (e) {
      _errorMessage = 'Error fetching subjects: $e';
      _subjects = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSubjects() {
    _subjects = [];
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}