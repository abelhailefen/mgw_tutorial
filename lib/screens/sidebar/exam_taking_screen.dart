// lib/screens/sidebar/exam_taking_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/l10n/app_localizations.dart';
import 'package:mgw_tutorial/constants/color.dart';
import 'package:mgw_tutorial/provider/question_provider.dart';
import 'package:mgw_tutorial/models/question.dart';
import 'package:mgw_tutorial/widgets/question_card.dart'; // Use your project's widget

class ExamTakingScreen extends StatefulWidget {
  static const routeName = '/exam_taking';

  // Arguments expected from navigation
  final int subjectId;
  final int chapterId;
  final int examId;
  final String examTitle;

  const ExamTakingScreen({
    super.key,
    required this.subjectId,
    required this.chapterId,
    required this.examId,
    required this.examTitle,
  });

  @override
  State<ExamTakingScreen> createState() => _ExamTakingScreenState();
}

class _ExamTakingScreenState extends State<ExamTakingScreen> {
  bool _hasSubmitted = false; // State to track if the user has submitted

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure context is available after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Fetch questions for the specific exam when the screen initializes
      // We listen: false here as we are just triggering the fetch in initState
      Provider.of<QuestionProvider>(context, listen: false).fetchQuestions(widget.examId);
    });
  }

  Future<void> _refreshQuestions() async {
    // Trigger a refresh fetch for the current exam
    // Ensure context is valid before using it
    if (!mounted) return;
    await Provider.of<QuestionProvider>(context, listen: false).fetchQuestions(widget.examId, forceRefresh: true);
     // Reset submission state on refresh
    setState(() {
      _hasSubmitted = false;
    });
    // Clear selected answers when refreshing a submitted exam
    if (!mounted) return;
    Provider.of<QuestionProvider>(context, listen: false).clearSelectedAnswers();
  }

  void _submitExam() {
    // TODO: Implement actual submission logic (e.g., send answers to API)
    // Access selected answers using Provider.of<QuestionProvider>(context, listen: false).selectedAnswers
    final selectedAnswers = Provider.of<QuestionProvider>(context, listen: false).selectedAnswers;
    debugPrint('Submitting answers: $selectedAnswers'); // Example of accessing answers


    // For now, just toggle the state to show results/correct answers
    setState(() {
      _hasSubmitted = true;
    });
    // TODO: Optionally disable further selection changes after submission
    // The ChoiceCard already handles this based on hasSubmitted state.
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // Assuming l10n is available
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Watch the QuestionProvider for changes related to this exam ID
    // listen: true is needed here to rebuild the UI when state changes
    final questionProvider = Provider.of<QuestionProvider>(context);

    // Get the state for the specific exam (assuming the provider now manages a single exam)
    final isLoading = questionProvider.isLoading;
    final errorMessage = questionProvider.errorMessage;
    final questions = questionProvider.questions; // Provider now gives the list for the current exam
    // final selectedAnswers = questionProvider.selectedAnswers; // Selected answers are accessed within QuestionCard/ChoiceCard via Consumer or getter


    return Scaffold(
      appBar: AppBar(
        // TODO: Add localization key for "Exams" - using exam title is better
        title: Text(widget.examTitle),
        backgroundColor: isDarkMode ? AppColors.appBarBackgroundDark : AppColors.appBarBackgroundLight,
        actions: [
          // Add a Submit button visible before submission and when not loading
          if (!_hasSubmitted && !isLoading && questions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: ElevatedButton(
                onPressed: isLoading ? null : _submitExam, // Disable while loading
                child: Text(l10n.submitButton), // TODO: Localize "Submit"
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isLoading ? null : _refreshQuestions, // Disable while loading
          ),
        ],
      ),
      body: Builder( // Use Builder to get a context under the Scaffold
        builder: (context) {
          // Use a local variable for the list to avoid potential null issues if provider provides null
          final currentQuestions = questions;

           if (isLoading && currentQuestions.isEmpty) {
             return const Center(child: CircularProgressIndicator());
           } else if (errorMessage != null && currentQuestions.isEmpty) {
             return Center(
               child: Padding(
                 padding: const EdgeInsets.all(16.0),
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 40),
                     const SizedBox(height: 16),
                     Text(
                       // TODO: Add localization key
                      'Error loading questions: ${errorMessage!}', // errorMessage is String?
                       textAlign: TextAlign.center,
                       style: TextStyle(
                         fontSize: 16,
                         color: Theme.of(context).colorScheme.error,
                       ),
                     ),
                     const SizedBox(height: 16),
                     ElevatedButton(
                       onPressed: isLoading ? null : _refreshQuestions,
                       // Corrected SizedBox usage <-- FIX IS HERE
                       child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(l10n.retry), 
                     ),
                   ],
                 ),
               ),
             );
           } else if (currentQuestions.isEmpty) {
              return Center(
                child: Text(
                   // TODO: Add localization key
                  'No questions available for ${widget.examTitle}.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              );
           } else {
             // Data is available, display the list of questions
             return Stack(
                children: [
                  ListView.builder(
                    itemCount: currentQuestions.length,
                    itemBuilder: (context, index) {
                      final question = currentQuestions[index];
                      return QuestionCard(
                        question: question,
                        questionNumber: index + 1, // Display 1-based index
                        hasSubmitted: _hasSubmitted, // Pass submission state
                      );
                    },
                  ),

                   // Loading overlay when data is already present but refreshing
                   if (isLoading && currentQuestions.isNotEmpty)
                      const Opacity(
                        opacity: 0.6,
                        child: ModalBarrier(dismissible: false, color: Colors.black),
                      ),
                   if (isLoading && currentQuestions.isNotEmpty)
                      const Center(child: CircularProgressIndicator()),
                ],
             );
          }
        },
      ),
    );
  }
}