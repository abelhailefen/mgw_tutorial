// lib/screens/sidebar/exam_taking_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/l10n/app_localizations.dart';
import 'package:mgw_tutorial/constants/color.dart';
import 'package:mgw_tutorial/provider/question_provider.dart';
import 'package:mgw_tutorial/models/question.dart';
import 'package:mgw_tutorial/widgets/question_card.dart';

class ExamTakingScreen extends StatefulWidget {
  static const routeName = '/exam_taking';

  // Arguments expected from navigation
  final int subjectId;
  final int chapterId;
  final int examId;
  final String examTitle;
  // Note: We are NOT receiving showExplanationsBeforeSubmit here anymore,
  // as the ExamTakingScreen uses the exam's actual isAnswerBefore property.

  const ExamTakingScreen({
    super.key,
    required this.subjectId,
    required this.chapterId,
    required this.examId,
    required this.examTitle,
    // Removed showExplanationsBeforeSubmit from constructor
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
      Provider.of<QuestionProvider>(context, listen: false).fetchQuestions(widget.examId);
    });
  }

  Future<void> _refreshQuestions() async {
    // Trigger a refresh fetch for the current exam
    if (!mounted) return;
    await Provider.of<QuestionProvider>(context, listen: false).fetchQuestions(widget.examId, forceRefresh: true);
     // Reset submission state on refresh
    setState(() {
      _hasSubmitted = false;
    });
    // Clear selected answers when refreshing
    if (!mounted) return;
    Provider.of<QuestionProvider>(context, listen: false).clearSelectedAnswers();
  }

  void _submitExam() {
    // Prevent multiple submissions or submission while loading
    if (_hasSubmitted || Provider.of<QuestionProvider>(context, listen: false).isLoading) return;

    // TODO: Implement actual submission logic (e.g., send answers to API)
    final selectedAnswers = Provider.of<QuestionProvider>(context, listen: false).selectedAnswers;
    debugPrint('Submitting answers for Exam ${widget.examId}: $selectedAnswers'); // Example of accessing answers

    // Show a confirmation dialog if desired before final submission
    // Or just directly submit

    // For now, just toggle the state to show results/correct answers
    setState(() {
      _hasSubmitted = true;
    });

    // TODO: Handle API submission result (success/failure)
    // If submission is successful, you might navigate away or show a result summary.
    // If submission fails, show an error message.
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // Assuming l10n is available
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Watch the QuestionProvider for changes related to this exam ID
    // listen: true is needed here to rebuild the UI when state changes (loading, data changes)
    final questionProvider = Provider.of<QuestionProvider>(context);

    // Get the state for the specific exam
    final isLoading = questionProvider.isLoading;
    final errorMessage = questionProvider.errorMessage;
    final questions = questionProvider.questions;

    // Determine the padding needed at the bottom for the fixed button
    // Adjust the value (e.g., 80.0) based on the height of your submit button
    const double bottomButtonHeight = 80.0; // Approximate height of the button area

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.examTitle), // Use exam title from arguments
        backgroundColor: isDarkMode ? AppColors.appBarBackgroundDark : AppColors.appBarBackgroundLight,
        actions: [
          // Keep the Refresh button in the AppBar
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isLoading ? null : _refreshQuestions, // Disable while loading
          ),
        ],
      ),
      body: Builder( // Use Builder to get a context under the Scaffold
        builder: (context) {
           // Use a local variable for the list to avoid potential null issues
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
                       child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(l10n.retry), // TODO: Localize "Retry"
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
                      'No questions available for ${widget.examTitle}.', // TODO: Localize
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
                          question: question,
                          questionNumber: index + 1, // Display 1-based index
                          hasSubmitted: _hasSubmitted, // Pass submission state
                        );
                      },
                    ),
                  ),

                  // --- Submit Button at the bottom ---
                  // Only show the button if not submitted, not loading, and questions exist
                   if (!_hasSubmitted && !isLoading && currentQuestions.isNotEmpty)
                     Positioned(
                       bottom: 0,
                       left: 0,
                       right: 0,
                       child: Container(
                         padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          color: Theme.of(context).scaffoldBackgroundColor, // Match scaffold background
                          child: ElevatedButton(
                            onPressed: _submitExam, // Call submit function
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15.0),
                              textStyle: const TextStyle(fontSize: 18),
                              // Use theme colors
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            ),
                            child: Text(l10n.submitExam), 
                          ),
                       ),
                     ),
                  // --- End Submit Button ---


                   // Loading overlay (covers the whole Stack)
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