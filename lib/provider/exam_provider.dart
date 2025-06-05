import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mgw_tutorial/models/exam.dart';
import 'package:mgw_tutorial/services/database_helper.dart';

class ExamProvider with ChangeNotifier {
  final Map<int, List<Exam>> _examsCache = {};
  final Map<int, bool> _loadingStatus = {};
  final Map<int, String?> _errorMessages = {};

  bool isLoading(int chapterId) => _loadingStatus[chapterId] ?? false;
  String? getErrorMessage(int chapterId) => _errorMessages[chapterId];
  List<Exam>? getExams(int chapterId) => _examsCache[chapterId];

  final String _baseApiUrl = "https://mgw-backend.onrender.com/api/exams/chapter/";
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> fetchExamsForChapter(int chapterId, {bool forceRefresh = false}) async {
    if (_examsCache.containsKey(chapterId) && !forceRefresh && !(_loadingStatus[chapterId] ?? false)) {
      final cached = await _dbHelper.query('exams', where: 'chapterId = ?', whereArgs: [chapterId]);
      if (cached.isNotEmpty) {
        _examsCache[chapterId] = cached.map((e) => Exam.fromJson(e)).toList();
        _loadingStatus[chapterId] = false;
        _errorMessages[chapterId] = null;
        notifyListeners();
        return;
      }
    }

    _loadingStatus[chapterId] = true;
    _errorMessages[chapterId] = null;
    notifyListeners();

    try {
      final url = '$_baseApiUrl$chapterId';
      final response = await http.get(Uri.parse(url)).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData.containsKey('data') && responseData['data'] is List) {
          List<dynamic> examsJson = responseData['data'];
          List<Exam> fetchedExams = examsJson.map((json) => Exam.fromJson(json)).toList();

          _examsCache[chapterId] = fetchedExams;

          // Cache in SQLite
          for (var exam in fetchedExams) {
            await _dbHelper.upsert('exams', {
              'id': exam.id,
              'title': exam.title,
              'description': exam.description,
              'chapterId': exam.chapterId,
              'totalQuestions': exam.totalQuestions,
              'timeLimit': exam.timeLimit,
              'status': exam.status,
              'isAnswerBefore': exam.isAnswerBefore ? 1 : 0,
              'passingScore': exam.passingScore,
              'examType': exam.examType,
              'examYear': exam.examYear,
              'maxAttempts': exam.maxAttempts,
              'shuffleQuestions': exam.shuffleQuestions ? 1 : 0,
              'showResultsImmediately': exam.showResultsImmediately ? 1 : 0,
              'startDate': exam.startDate?.toIso8601String(),
              'endDate': exam.endDate?.toIso8601String(),
              'instructions': exam.instructions,
            });
          }
        } else {
          _errorMessages[chapterId] = 'Unable to load exams. Please try again later.';
          _examsCache[chapterId] = [];
        }
      } else {
        _errorMessages[chapterId] = 'Unable to load exams. Please check your connection.';
        _examsCache[chapterId] = [];
      }
    } catch (e) {
      _errorMessages[chapterId] = 'Error fetching exams: $e';
      _examsCache[chapterId] = [];
    } finally {
      _loadingStatus[chapterId] = false;
      notifyListeners();
    }
  }

  Future<void> clearExams() async {
    _examsCache.clear();
    _loadingStatus.clear();
    _errorMessages.clear();
    await _dbHelper.delete('exams');
    notifyListeners();
  }
}