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

  final String _questionsApiUrl =
      "https://courseservice.mgwcommunity.com/api/questions"; // Base URL for all questions
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // --- Fetch Questions: API First, then Cache on Failure ---
  Future<void> fetchQuestions(int examId, {bool forceRefresh = false}) async {
    // If already loading the same exam and not forcing refresh, just return.
    // The UI is already showing the loading state.
    if (_isLoading && _currentExamId == examId && !forceRefresh) {
      debugPrint('Fetch already in progress for exam $examId, returning.');
      return;
    }

    debugPrint(
        'Initiating fetch for exam $examId (forceRefresh: $forceRefresh)');

    _currentExamId = examId; // Set the current exam ID
    _isLoading = true;
    _errorMessage = null;
    _questions = []; // Clear previous questions immediately
    _selectedAnswers
        .clear(); // <-- CLEAR SELECTED ANSWERS HERE at the start of any fetch
    notifyListeners(); // Notify immediately to show loading state with empty data

    List<Question> fetchedQuestions = [];
    String? apiAttemptError;
    bool loadedFromApi = false;

    // --- Attempt to fetch from API first ---
    debugPrint('Attempting to fetch questions for exam $examId from API...');
    try {
      // Assuming the API supports filtering by exam_id query parameter
      final url = Uri.parse(_questionsApiUrl)
          .replace(queryParameters: {'exam_id': examId.toString()});
      final response = await http.get(url).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData.containsKey('data') && responseData['data'] is List) {
          List<dynamic> questionsJson = responseData['data'];
          // Client-side filter just in case API didn't filter strictly
          List<Question> apiQuestions = questionsJson
              .map((json) => Question.fromJson(json))
              .where((q) => q.examId == examId)
              .toList();

          if (apiQuestions.isNotEmpty) {
            fetchedQuestions = apiQuestions;
            loadedFromApi = true;
            debugPrint(
                'Successfully fetched ${fetchedQuestions.length} questions for exam $examId from API.');
          } else {
            apiAttemptError = 'API returned empty data for exam $examId.';
            debugPrint(apiAttemptError);
          }
        } else {
          apiAttemptError =
              'API returned invalid data format for exam $examId.';
          debugPrint(apiAttemptError);
        }
      } else {
        apiAttemptError =
            'API responded with status ${response.statusCode} for exam $examId.';
        debugPrint(apiAttemptError);
      }
    } catch (e) {
      // Handle network errors specifically
      if (e is SocketException || e is TimeoutException) {
        apiAttemptError =
            'Network error: Could not reach server to fetch exam $examId questions.';
      } else {
        apiAttemptError = 'Error fetching exam $examId questions from API: $e';
      }
      debugPrint('API Fetch failed for exam $examId: $e');
    }

    // --- If API fetch was successful, update state and cache ---
    if (loadedFromApi) {
      _questions = fetchedQuestions;
      _errorMessage = null; // Clear any previous error
      // Cache in SQLite - Clear old questions for this exam first
      await _dbHelper
          .delete('questions', where: 'examId = ?', whereArgs: [examId]);
      for (var question in _questions) {
        await _dbHelper.upsert('questions', question.toMap());
      }
      debugPrint('Cached ${_questions.length} questions for exam $examId.');
    } else {
      // --- API failed (or returned empty), attempt to load from Cache as fallback ---
      debugPrint(
          'API fetch failed or empty data. Attempting to load questions for exam $examId from cache...');
      final cached = await _dbHelper
          .query('questions', where: 'examId = ?', whereArgs: [examId]);

      if (cached.isNotEmpty) {
        _questions = cached.map((e) => Question.fromJson(e)).toList();
        // If we successfully loaded from cache after an API failure, clear the error message
        _errorMessage = null;
        debugPrint(
            'Successfully loaded ${_questions.length} questions for exam $examId from cache as fallback.');
      } else {
        // API failed AND cache was empty/failed. Set the error message from the API attempt or a generic one.
        _errorMessage = apiAttemptError ??
            'No questions found in API or cache for exam $examId.';
        debugPrint(
            'Cache is also empty for exam $examId. Error: $_errorMessage');
      }
    }

    // Ensure selected answers are cleared if no questions are loaded (Redundant now, but harmless)
    if (_questions.isEmpty) {
      _selectedAnswers.clear();
    }

    _isLoading = false;
    notifyListeners();
  }

  void selectAnswer(int questionId, String choiceLabel) {
    // Check if the selected answer is valid (A, B, C, D) and the question exists
    // Also check if an answer has already been selected for this question.
    // If the exam type is 'before submit', and an answer is already selected,
    // we don't allow changing it after the first selection.
    final question = _questions.firstWhere((q) => q.id == questionId,
        orElse: () => null as Question);

    if (question == null) {
      debugPrint(
          'Attempted to select answer for non-existent question: $questionId');
      return;
    }

    // Check if the exam allows changing answers after the first selection (isAnswerBeforeExam=true means answers are final once chosen)
    // We don't have the Exam object directly here, but the QuestionCard itself should enforce this via its state
    // and only call `selectAnswer` when allowed.
    // The provider just records the selection.

    if (['A', 'B', 'C', 'D'].contains(choiceLabel)) {
      // If the same answer is tapped again, deselect it
      if (_selectedAnswers.containsKey(questionId) &&
          _selectedAnswers[questionId] == choiceLabel) {
        _selectedAnswers.remove(questionId);
        debugPrint('Answer deselected: QID $questionId');
      } else {
        _selectedAnswers[questionId] = choiceLabel;
        debugPrint('Answer selected: QID $questionId, Choice $choiceLabel.');
      }
    } else {
      debugPrint('Invalid choice label: $choiceLabel for question $questionId');
    }

    notifyListeners();
  }

  // This method is now redundant if fetchQuestions always clears _selectedAnswers
  // kept for potential explicit clearing needs elsewhere
  void clearSelectedAnswers() {
    if (_selectedAnswers.isNotEmpty) {
      debugPrint('Clearing selected answers.');
      _selectedAnswers.clear();
      notifyListeners();
    }
  }

  // Clear all questions and state (e.g., when logging out)
  Future<void> clearState() async {
    debugPrint('Clearing all question provider state.');
    _questions = [];
    _isLoading = false;
    _errorMessage = null;
    _currentExamId = null;
    _selectedAnswers.clear();

    notifyListeners();
  }
}
