// lib/screens/sidebar/exam_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mgw_tutorial/l10n/app_localizations.dart';
import 'package:mgw_tutorial/constants/color.dart';
import 'package:mgw_tutorial/provider/exam_provider.dart';
import 'package:mgw_tutorial/models/exam.dart';
// Import the screen you navigate to
import 'package:mgw_tutorial/screens/sidebar/exam_taking_screen.dart';


class ExamListScreen extends StatefulWidget {
  static const routeName = '/exam_list';

  // Screen requires subject, chapter ID and name to fetch exams and pass down
  final int subjectId;
  final String subjectName;
  final int chapterId;
  final String chapterName;
  // Add the new argument for explanation preference
  final bool showExplanationsBeforeSubmit;

  const ExamListScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.chapterId,
    required this.chapterName,
    required this.showExplanationsBeforeSubmit, // <-- Receive the preference
  });

  @override
  State<ExamListScreen> createState() => _ExamListScreenState();
}

class _ExamListScreenState extends State<ExamListScreen> {
  @override
  void initState() {
    super.initState();
     // Use addPostFrameCallback to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Fetch exams for the given chapter when the screen initializes
      // The provider fetches all exams for the chapter; filtering happens in build
      Provider.of<ExamProvider>(context, listen: false).fetchExamsForChapter(widget.chapterId);
    });
  }

  Future<void> _refreshExams() async {
    // Trigger a refresh fetch for the current chapter
    if (!mounted) return;
    await Provider.of<ExamProvider>(context, listen: false).fetchExamsForChapter(widget.chapterId, forceRefresh: true);
  }

  // Helper to format date or show "N/A"
  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    // Consider using locale-specific formatting if necessary
    return DateFormat('yyyy-MM-dd hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Watch the ExamProvider for changes related to this chapter ID
    final examProvider = Provider.of<ExamProvider>(context);

    // Get the state for the specific chapter
    final isLoading = examProvider.isLoading(widget.chapterId);
    final errorMessage = examProvider.getErrorMessage(widget.chapterId);
    final allExamsForChapter = examProvider.getExams(widget.chapterId); // Get all exams for the chapter

    // --- Filter the exams based on the received preference ---
    final List<Exam> filteredExams = allExamsForChapter?.where((exam) {
      // Keep exams where isAnswerBefore matches the user's preference
      return exam.isAnswerBefore == widget.showExplanationsBeforeSubmit;
    }).toList() ?? []; // Use an empty list if allExamsForChapter is null or empty after filtering
    // --- End Filtering ---


    return Scaffold(
      appBar: AppBar(
        // TODO: Add localization key for "Exams" - using chapter name is good
        title: Text('${widget.chapterName} Exams'),
        backgroundColor: isDarkMode ? AppColors.appBarBackgroundDark : AppColors.appBarBackgroundLight,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isLoading ? null : _refreshExams, // Disable button while loading
          ),
        ],
      ),
      body: Builder( // Use Builder to get a context under the Scaffold
        builder: (context) {
           // Adjust loading/error states to consider the *initial* fetch status
           // The filtered list might be empty even if the full list isn't.
           // We should show loading if the provider is loading *and* the full list is empty.
           // Show error if there's an error message *and* the full list is empty.

           if (isLoading && (allExamsForChapter == null || allExamsForChapter.isEmpty)) {
             return const Center(child: CircularProgressIndicator());
           } else if (errorMessage != null && (allExamsForChapter == null || allExamsForChapter.isEmpty)) {
             return Center(
               child: Padding(
                 padding: const EdgeInsets.all(16.0),
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 40),
                     const SizedBox(height: 16),
                     Text(
                       // TODO: Add localization key for error message
                       'Error loading exams: ${errorMessage!}', // errorMessage is String?
                       textAlign: TextAlign.center,
                       style: TextStyle(
                         fontSize: 16,
                         color: Theme.of(context).colorScheme.error,
                       ),
                     ),
                     const SizedBox(height: 16),
                     ElevatedButton(
                       onPressed: isLoading ? null : _refreshExams,
                       child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Retry'), // TODO: Localize
                     ),
                   ],
                 ),
               ),
             );
           } else if (filteredExams.isEmpty) {
               // This case is hit if exams are loaded but the filtered list is empty
                String message = 'No exams available for ${widget.chapterName}'; // TODO: Localize
                if (widget.showExplanationsBeforeSubmit) {
                   message += ' with explanations shown before submit.'; // TODO: Localize
                } else {
                   message += ' with explanations shown after submit.'; // TODO: Localize
                }
              return Center(
                child: Padding(
                   padding: const EdgeInsets.all(16.0),
                   child: Text(
                     message,
                     textAlign: TextAlign.center,
                     style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                   ),
                ),
              );
           } else {
             // Filtered data is available, display the list
             return Stack(
                children: [
                  ListView.builder(
                    itemCount: filteredExams.length, // Use the filtered list count
                    itemBuilder: (context, index) {
                      final exam = filteredExams[index]; // Use the filtered list item
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        elevation: 1.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          title: Text(
                             exam.title,
                             style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (exam.description != null && exam.description!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(exam.description!, style: TextStyle(color: Colors.grey[700], fontSize: 13)), // Consider Theme
                                ),
                              const SizedBox(height: 8),
                              // TODO: Localize these labels
                              Text('Type: ${exam.examType}'),
                              Text('Questions: ${exam.totalQuestions}'),
                              Text('Time Limit: ${exam.timeLimit} minutes'),
                              Text('Passing Score: ${exam.passingScore}%'),
                               Text('Explanation: ${exam.isAnswerBefore ? 'Before Submit' : 'After Submit'}'), // Show the exam's actual setting
                              if (exam.startDate != null) Text('Start Date: ${_formatDate(exam.startDate)}'),
                              if (exam.endDate != null) Text('End Date: ${_formatDate(exam.endDate)}'),
                              // Add more details as needed
                            ],
                          ),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                             child: Text(exam.examType.isNotEmpty ? exam.examType.substring(0, 1).toUpperCase() : 'E'),
                          ),
                          onTap: () {
                            // Navigate to the ExamTakingScreen, passing all relevant IDs and title
                             Navigator.pushNamed(
                               context,
                               ExamTakingScreen.routeName,
                               arguments: {
                                 'subjectId': widget.subjectId,
                                 'chapterId': widget.chapterId,
                                 'examId': exam.id,
                                 'examTitle': exam.title,
                                 // Note: We DON'T pass 'showExplanationsBeforeSubmit' to ExamTakingScreen
                                 // because the ExamTakingScreen operates on a single exam which
                                 // has its own fixed isAnswerBefore property (exam.isAnswerBefore).
                                 // The preference was only for filtering the *list* of exams here.
                               },
                             );
                          },
                        ),
                      );
                    },
                  ),
                   // Loading overlay when data is already present but refreshing
                   if (isLoading && filteredExams.isNotEmpty) // Show overlay only if filtered data is present
                      const Opacity(
                        opacity: 0.6,
                        child: ModalBarrier(dismissible: false, color: Colors.black),
                      ),
                   if (isLoading && filteredExams.isNotEmpty) // Show indicator only if filtered data is present
                      const Center(child: CircularProgressIndicator()),
                ],
             );
          }
        },
      ),
    );
  }
}