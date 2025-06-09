// lib/provider/question_provider.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:mgw_tutorial/models/question.dart';
import 'package:mgw_tutorial/services/database_helper.dart';

class QuestionProvider with ChangeNotifier {
  List<Question> _questions = [];
  bool _isLoading = false;
  String? _errorMessage;
  int? _currentExamId; // Track which exam's questions are currently loaded

  // Map to store selected answers: {questionId: selectedChoiceLabel}
  final Map<int, String> _selectedAnswers = {};

  List<Question> get questions => _questions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<int, String> get selectedAnswers => _selectedAnswers;

  String? getSelectedAnswer(int questionId) => _selectedAnswers[questionId];

  final String _questionsApiUrl = "https://courseservice.anbesgames.com/api/questions"; // Base URL for all questions
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> fetchQuestions(int examId, {bool forceRefresh = false}) async {
    // If loading the same exam and not forcing refresh, do nothing
    if (_isLoading && _currentExamId == examId && !forceRefresh) return;

    _currentExamId = examId; // Set the current exam ID
    _isLoading = true;
    _errorMessage = null;
    // Clear previous data ONLY if fetching a different exam or force refreshing
    if (_currentExamId != examId || forceRefresh) {
       _questions = [];
       _selectedAnswers.clear();
    }
    notifyListeners(); // Notify before starting fetch to show loading state

    // Check SQLite cache first for the specific examId
    final cached = await _dbHelper.query('questions', where: 'examId = ?', whereArgs: [examId]);

    if (cached.isNotEmpty && !forceRefresh) {
      _questions = cached.map((e) => Question.fromJson(e)).toList();
      _isLoading = false;
      _errorMessage = null;
      // Do NOT clear selectedAnswers here if it's a return to the same exam
      notifyListeners();
      return;
    }

    // If forceRefresh or no cache, try API
    if (forceRefresh || cached.isEmpty) {
      try {
        // The API endpoint is /api/questions, need to filter by exam_id if possible,
        // or fetch all and filter locally. The provided API GET /api/questions
        // *does* return a list with `exam_id`. Let's assume we can filter server-side
        // if the API supports it, or filter client-side.
        // Looking at the example API response, it returns ALL questions, but includes
        // `exam_id`. This suggests filtering by examId might need to happen client-side
        // or require a different API endpoint like /api/exams/{examId}/questions.
        // Let's assume for now we fetch all and filter, OR the API will eventually support filtering.
        // A safer approach: assume API needs *all* questions first, then filter by examId.
        // Or, hope the API provides '/api/questions?exam_id={examId}'
        // Let's try fetching all and filtering, but also try adding exam_id as a query param in case the backend supports it.
        final url = Uri.parse(_questionsApiUrl).replace(queryParameters: {'exam_id': examId.toString()});

        final response = await http.get(url).timeout(Duration(seconds: 30));

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = json.decode(response.body);

          if (responseData.containsKey('data') && responseData['data'] is List) {
            List<dynamic> questionsJson = responseData['data'];
            // Filter questions client-side by examId if needed (or if API didn't filter)
             List<Question> fetchedQuestions = questionsJson
                 .map((json) => Question.fromJson(json))
                 .where((q) => q.examId == examId) // Filter by the target examId
                 .toList();


            _questions = fetchedQuestions;

            // Cache in SQLite - Clear old questions for this exam first
            await _dbHelper.delete('questions', where: 'examId = ?', whereArgs: [examId]);
            for (var question in _questions) {
               // Ensure foreign key constraints are met or remove FOREIGN KEY if not strictly enforced/managed
               // For simple caching, storing directly is fine as long as subjectId, chapterId, examId exist in their tables.
               // Upsert handles replacement if fetching same questions again.
              await _dbHelper.upsert('questions', question.toMap());
            }

             // Clear selected answers if new questions are loaded
             _selectedAnswers.clear();

          } else {
            _errorMessage = 'Unable to load questions. Invalid data format.';
             // Revert to cached data if available and API failed
            _questions = cached.isNotEmpty ? cached.map((e) => Question.fromJson(e)).toList() : [];
          }
        } else {
          _errorMessage = 'Server responded with status ${response.statusCode}. Unable to load questions.';
           // Revert to cached data if available and API failed
          _questions = cached.isNotEmpty ? cached.map((e) => Question.fromJson(e)).toList() : [];
        }
      } catch (e) {
        // Handle network errors specifically
        if (e is SocketException || e is TimeoutException) {
          _errorMessage = cached.isNotEmpty ? null : 'No internet connection. Please connect and try again.';
          // Revert to cached data if available and API failed
          _questions = cached.isNotEmpty ? cached.map((e) => Question.fromJson(e)).toList() : [];
        } else {
          _errorMessage = 'Error fetching questions: $e';
           // Revert to cached data if available and API failed
          _questions = cached.isNotEmpty ? cached.map((e) => Question.fromJson(e)).toList() : [];
        }
      }
    }

    _isLoading = false;
    // Ensure selected answers are cleared if no questions are loaded
    if (_questions.isEmpty) {
      _selectedAnswers.clear();
    }
    notifyListeners();
  }

  void selectAnswer(int questionId, String choiceLabel) {
    // Check if the selected answer is valid (A, B, C, D) and the question exists
    if (['A', 'B', 'C', 'D'].contains(choiceLabel) && _questions.any((q) => q.id == questionId)) {
       // If the same answer is tapped again, deselect it
       if (_selectedAnswers[questionId] == choiceLabel) {
         _selectedAnswers.remove(questionId);
       } else {
         _selectedAnswers[questionId] = choiceLabel;
       }
       notifyListeners();
    } else {
       // Optional: Log an error or show a message
       print('Invalid selection: questionId=$questionId, choiceLabel=$choiceLabel');
    }
  }

  // Method to clear selected answers for the current exam
  void clearSelectedAnswers() {
    _selectedAnswers.clear();
    notifyListeners();
  }

  // Clear all questions and state (e.g., when logging out)
  Future<void> clearState() async {
    _questions = [];
    _isLoading = false;
    _errorMessage = null;
    _currentExamId = null;
    _selectedAnswers.clear();
    await _dbHelper.delete('questions'); // Clear questions from DB cache
    notifyListeners();
  }
}