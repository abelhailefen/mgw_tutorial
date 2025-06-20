// lib/screens/sidebar/exam_taking_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/l10n/app_localizations.dart'; // Ensure localization is imported
import 'package:mgw_tutorial/constants/color.dart'; // Assuming AppColors is here
import 'package:mgw_tutorial/provider/question_provider.dart';
import 'package:mgw_tutorial/models/question.dart'; // Import Question model
import 'package:mgw_tutorial/models/exam.dart'; // Import Exam model
import 'package:mgw_tutorial/widgets/question_card.dart';
import 'package:mgw_tutorial/widgets/result_popup.dart'; // Import the ResultPopup widget

class ExamTakingScreen extends StatefulWidget {
  static const routeName = '/exam_taking';

  // Arguments expected from navigation - Receive the full Exam object
  final Exam exam;

  const ExamTakingScreen({
    super.key,
    required this.exam, // Receive the Exam object
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
      
      Provider.of<QuestionProvider>(context, listen: false).fetchQuestions(widget.exam.id);
    });
  }

  void _submitExam() {
    // Prevent multiple submissions or submission while loading
    final questionProvider = Provider.of<QuestionProvider>(context, listen: false);
    if (_hasSubmitted || questionProvider.isLoading) return;

    final currentQuestions = questionProvider.questions;
    final selectedAnswers = questionProvider.selectedAnswers;

    int score = 0;
    List<Question> failedQuestions = [];

    // Calculate score and identify failed questions
    for (final question in currentQuestions) {
      final userSelection = selectedAnswers[question.id];
      // A question is failed if no answer was selected OR if the selected answer is wrong
      if (userSelection == null || userSelection != question.answer) {
         // Add to failed questions only if an explanation exists
         if (question.explanation != null && question.explanation!.isNotEmpty) {
            failedQuestions.add(question);
         }
      } else {
        // Correct answer was selected
        score++;
      }
    }


    // Calculate if passed
    final totalQuestions = currentQuestions.length;
    bool passed = false;
    if (totalQuestions > 0) { // Avoid division by zero
       final percentage = (score / totalQuestions) * 100;
       passed = percentage >= widget.exam.passingScore;
    }

    // Toggle submission state
    setState(() {
      _hasSubmitted = true;
    });


    // --- Show the Result Popup ---
    showDialog(
      context: context,
      barrierDismissible: false, // User must use the buttons in the popup
      builder: (context) {
        return ResultPopup(
          passed: passed,
          score: score,
          totalQuestions: totalQuestions,
          failedQuestions: failedQuestions, // Pass the list of failed questions
          onShowExplanations: () {
            debugPrint("User tapped 'View Explanations' in popup.");
             },
        );
      },
    );

  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Watch the QuestionProvider for changes
    final questionProvider = Provider.of<QuestionProvider>(context);

    final isLoading = questionProvider.isLoading;
    final errorMessage = questionProvider.errorMessage;
    final questions = questionProvider.questions;

    // Determine the padding needed at the bottom for the fixed button
    const double bottomButtonHeight = 80.0; // Approximate height of the button area

    return Scaffold(
      appBar: AppBar(
        // Use exam title from the received Exam object
        title: Text(widget.exam.title),
        backgroundColor: isDarkMode ? AppColors.appBarBackgroundDark : AppColors.appBarBackgroundLight,
        // REMOVED actions list, which contained the Refresh button
        actions: const [],
      ),
      body: Builder( // Use Builder to get a context under the Scaffold
        builder: (context) {
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
                       'Error loading questions: ${errorMessage!}',
                       textAlign: TextAlign.center,
                       style: TextStyle(
                         fontSize: 16,
                         color: Theme.of(context).colorScheme.error,
                       ),
                     ),
                     const SizedBox(height: 16),
                     ElevatedButton(
                       // Use _refreshQuestions if you want the button visible on error, otherwise remove
                       onPressed: isLoading ? null : () => Provider.of<QuestionProvider>(context, listen: false).fetchQuestions(widget.exam.id, forceRefresh: true),
                       child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(l10n.retry), // Use localized "Retry"
                     ),
                   ],
                 ),
               ),
             );
           } else if (currentQuestions.isEmpty) {
              return Center(
                child: Padding(
                   padding: const EdgeInsets.all(16.0),
                   child: Text(
                     'No questions available for ${widget.exam.title}.', // TODO: Localize this message
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                   ),
                ),
              );
           } else {
             // Data is available, display the list of questions using a Stack
             return Stack(
                children: [
                  // The main scrollable list of questions
                  Padding(
                    // Add padding at the bottom equal to the button height + some margin
                    padding: const EdgeInsets.only(bottom: bottomButtonHeight),
                    child: ListView.builder(
                      itemCount: currentQuestions.length,
                      itemBuilder: (context, index) {
                        final question = currentQuestions[index];
                        return QuestionCard(
                          key: ValueKey(question.id), // Add a key for better list performance
                          question: question,
                          questionNumber: index + 1,
                          hasSubmitted: _hasSubmitted,
                          // Pass the exam's isAnswerBefore property to QuestionCard
                          isAnswerBeforeExam: widget.exam.isAnswerBefore,
                        );
                      },
                    ),
                  ),

                   if (!_hasSubmitted && !isLoading && currentQuestions.isNotEmpty)
                     Positioned(
                       bottom: 0,
                       left: 0,
                       right: 0,
                       child: Container(
                         padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          color: Theme.of(context).colorScheme.surface, // Use a suitable theme color
                          child: ElevatedButton(
                            onPressed: _submitExam, // Call submit function
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15.0),
                              textStyle: const TextStyle(fontSize: 18),
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            ),
                            child: Text(l10n.submitExam), // Use localized "Submit"
                          ),
                       ),
                     ),
                   if (isLoading) // Show overlay if isLoading is true
                      const Opacity(
                        opacity: 0.6,
                        child: ModalBarrier(dismissible: false, color: Colors.black),
                      ),
                   if (isLoading) // Show indicator if isLoading is true
                      const Center(child: CircularProgressIndicator()),
                ],
             );
          }
        },
      ),
    );
  }
}