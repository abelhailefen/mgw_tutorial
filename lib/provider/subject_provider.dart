import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:mgw_tutorial/models/subject.dart';
import 'package:mgw_tutorial/services/database_helper.dart';

class SubjectProvider with ChangeNotifier {
  List<Subject> _subjects = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Subject> get subjects => _subjects;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final String _subjectsApiUrl = "https://courseservice.anbesgames.com/api/subjects";
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> fetchSubjects({bool forceRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Always check SQLite cache first
    final cached = await _dbHelper.query('subjects');
    if (cached.isNotEmpty && !forceRefresh) {
      _subjects = cached.map((e) => Subject.fromJson(e)).toList();
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    // If forceRefresh or no cache, try API
    if (forceRefresh || cached.isEmpty) {
      try {
        final response = await http.get(Uri.parse(_subjectsApiUrl)).timeout(Duration(seconds: 30));

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = json.decode(response.body);

          if (responseData.containsKey('data') && responseData['data'] is List) {
            List<dynamic> subjectsJson = responseData['data'];
            _subjects = subjectsJson.map((json) => Subject.fromJson(json)).toList();

            // Cache in SQLite
            for (var subject in _subjects) {
              await _dbHelper.upsert('subjects', {
                'id': subject.id,
                'name': subject.name,
                'category': subject.category,
                'year': subject.year,
                'imageUrl': subject.imageUrl,
              });
            }
          } else {
            _errorMessage = 'Unable to load subjects. Please try again later.';
            _subjects = cached.isNotEmpty ? cached.map((e) => Subject.fromJson(e)).toList() : [];
          }
        } else {
          _errorMessage = 'Unable to load subjects. Please check your connection.';
          _subjects = cached.isNotEmpty ? cached.map((e) => Subject.fromJson(e)).toList() : [];
        }
      } catch (e) {
        // Handle network errors specifically
        if (e is SocketException || e is TimeoutException) {
          _errorMessage = cached.isNotEmpty ? null : 'No internet connection. Please connect and try again.';
          _subjects = cached.isNotEmpty ? cached.map((e) => Subject.fromJson(e)).toList() : [];
        } else {
          _errorMessage = 'Error fetching subjects: $e';
          _subjects = cached.isNotEmpty ? cached.map((e) => Subject.fromJson(e)).toList() : [];
        }
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> clearSubjects() async {
    _subjects = [];
    _errorMessage = null;
    _isLoading = false;
    await _dbHelper.delete('subjects');
    notifyListeners();
  }
}