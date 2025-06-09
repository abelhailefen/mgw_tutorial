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
    // If already loading the same exam and not forcing refresh, just return.
    // The UI is already showing the loading state.
     if (_isLoading && _currentExamId == examId && !forceRefresh) {
        debugPrint('Fetch already in progress for exam $examId, returning.');
        return;
     }

    debugPrint('Initiating fetch for exam $examId (forceRefresh: $forceRefresh)');

    _currentExamId = examId; // Set the current exam ID
    _isLoading = true;
    _errorMessage = null;
    _questions = []; // Clear previous questions immediately
    _selectedAnswers.clear(); // <-- CLEAR SELECTED ANSWERS HERE at the start of any fetch
    notifyListeners(); // Notify immediately to show loading state with empty data


    // Check SQLite cache first for the specific examId
    final cached = await _dbHelper.query('questions', where: 'examId = ?', whereArgs: [examId]);

    if (cached.isNotEmpty && !forceRefresh) {
      debugPrint('Loading questions for exam $examId from cache.');
      _questions = cached.map((e) => Question.fromJson(e)).toList();
      _isLoading = false;
      _errorMessage = null;
      // _selectedAnswers is already cleared above.
      notifyListeners();
      return; // Cache hit, we're done.
    }

    debugPrint('Fetching questions for exam $examId from API (forceRefresh: $forceRefresh, cache empty: ${cached.isEmpty}).');

    // If forceRefresh or no cache, try API
    try {
        // Assuming the API supports filtering by exam_id query parameter
        final url = Uri.parse(_questionsApiUrl).replace(queryParameters: {'exam_id': examId.toString()});
        final response = await http.get(url).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = json.decode(response.body);

          if (responseData.containsKey('data') && responseData['data'] is List) {
            List<dynamic> questionsJson = responseData['data'];
             // Client-side filter just in case API didn't filter strictly
             List<Question> fetchedQuestions = questionsJson
                 .map((json) => Question.fromJson(json))
                 .where((q) => q.examId == examId)
                 .toList();


            _questions = fetchedQuestions;

            // Cache in SQLite - Clear old questions for this exam first
            await _dbHelper.delete('questions', where: 'examId = ?', whereArgs: [examId]);
            for (var question in _questions) {
              await _dbHelper.upsert('questions', question.toMap());
            }

             // _selectedAnswers is already cleared at the start.

          } else {
            _errorMessage = 'Unable to load questions. Invalid data format.';
             // If API fails but cache exists (unlikely with forceRefresh=true, but possible on initial fetch),
             // we already cleared questions/selectedAnswers/questions list.
             // We could potentially re-load from cached here if API failed and cache was initially NOT empty.
             // But for this use case (always clear on entering exam), leaving it empty is fine.
          }
        } else {
          _errorMessage = 'Server responded with status ${response.statusCode}. Unable to load questions.';
        }
      } catch (e) {
        // Handle network errors specifically
        if (e is SocketException || e is TimeoutException) {
          _errorMessage = 'No internet connection. Please connect and try again.';
        } else {
          _errorMessage = 'Error fetching questions: $e';
        }
        debugPrint('Error during question fetch: $e');
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
     final question = _questions.firstWhere((q) => q.id == questionId, orElse: () => null as Question);

     if (question == null) {
        debugPrint('Attempted to select answer for non-existent question: $questionId');
        return;
     }

     final bool hasAnswered = _selectedAnswers.containsKey(questionId);

     // Assume exam.isAnswerBefore is available via the Exam object somehow if needed here,
     // but for now, the ChoiceCard handles tapability based on isAnswerBeforeExam and selectedAnswer state.
     // The provider's selectAnswer method should just record the selection if called.

     // If the same answer is tapped again, deselect it - Removed this feature based on ChoiceCard onTap logic change
     // If (_selectedAnswers[questionId] == choiceLabel) {
     //   _selectedAnswers.remove(questionId);
     // } else {
        // Allow selecting/changing answer if not submitted and rules allow
         // The ChoiceCard onTap logic handles the "static" part when isAnswerBefore=true
        if (['A', 'B', 'C', 'D'].contains(choiceLabel)) {
             _selectedAnswers[questionId] = choiceLabel;
        } else {
             debugPrint('Invalid choice label: $choiceLabel for question $questionId');
        }
     // }

     notifyListeners();
     debugPrint('Answer selected: QID $questionId, Choice $choiceLabel. Selected state: ${_selectedAnswers[questionId]}');
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
    // Decide if you want to clear DB cache on logout
    // await _dbHelper.delete('questions'); // Clear questions from DB cache
    notifyListeners();
  }
}