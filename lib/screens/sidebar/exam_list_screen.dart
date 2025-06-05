// lib/screens/sidebar/exam_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:mgw_tutorial/l10n/app_localizations.dart';
import 'package:mgw_tutorial/constants/color.dart';
import 'package:mgw_tutorial/provider/exam_provider.dart'; // Import ExamProvider
import 'package:mgw_tutorial/models/exam.dart'; // Import Exam model

class ExamListScreen extends StatefulWidget {
  static const routeName = '/exam_list';

  // Screen requires chapter ID and name to display correctly
  final int chapterId;
  final String chapterName;

  const ExamListScreen({
    super.key,
    required this.chapterId,
    required this.chapterName,
  });

  @override
  State<ExamListScreen> createState() => _ExamListScreenState();
}

class _ExamListScreenState extends State<ExamListScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch exams for the given chapter when the screen initializes
    Provider.of<ExamProvider>(context, listen: false).fetchExamsForChapter(widget.chapterId);
  }

  Future<void> _refreshExams() async {
    // Trigger a refresh fetch for the current chapter
    await Provider.of<ExamProvider>(context, listen: false).fetchExamsForChapter(widget.chapterId, forceRefresh: true);
  }

  // Helper to format date or show "N/A"
  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    // You might need to set up localization for dates globally or here
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
    final exams = examProvider.getExams(widget.chapterId);

    return Scaffold(
      appBar: AppBar(
        // TODO: Add localization key for "Exams"
        title: Text('${widget.chapterName} Exams'),
        backgroundColor: isDarkMode ? AppColors.appBarBackgroundDark : AppColors.appBarBackgroundLight,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: isLoading ? null : _refreshExams, // Disable button while loading
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (isLoading && (exams == null || exams.isEmpty)) {
            return const Center(child: CircularProgressIndicator());
          } else if (errorMessage != null && (exams == null || exams.isEmpty)) {
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
                      'Error loading exams: $errorMessage',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: isLoading ? null : _refreshExams,
                      // TODO: Add localization key for Retry
                      child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          } else if (exams == null || exams.isEmpty) {
              return Center(
                child: Text(
                  // TODO: Add localization key for this message
                  'No exams available for ${widget.chapterName}.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              );
          } else {
             return Stack(
                children: [
                  ListView.builder(
                    itemCount: exams.length,
                    itemBuilder: (context, index) {
                      final exam = exams[index];
                      return Card( // Wrap ListTile in a Card for better visual separation like SubjectCard
                        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0), // Smaller margin than subject card
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
                                  child: Text(exam.description!, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                                ),
                              const SizedBox(height: 8),
                              Text('Type: ${exam.examType}'),
                              Text('Questions: ${exam.totalQuestions}'),
                              Text('Time Limit: ${exam.timeLimit} minutes'), // Assuming time_limit is in minutes
                              Text('Passing Score: ${exam.passingScore}%'),
                              if (exam.startDate != null) Text('Start Date: ${_formatDate(exam.startDate)}'),
                              if (exam.endDate != null) Text('End Date: ${_formatDate(exam.endDate)}'),
                              // Add more details as needed
                            ],
                          ),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                            child: Text(exam.examType.substring(0, 1).toUpperCase()), // Display first letter of type
                          ),
                          onTap: () {
                            // TODO: Implement navigation to the actual exam taking screen
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Tapped Exam: ${exam.title} (ID: ${exam.id}). (Exam taking not implemented)')),
                            );
                          },
                        ),
                      );
                    },
                  ),
                   if (isLoading && exams.isNotEmpty)
                      const Opacity(
                        opacity: 0.6,
                        child: ModalBarrier(dismissible: false, color: Colors.black),
                      ),
                   if (isLoading && exams.isNotEmpty)
                      const Center(child: CircularProgressIndicator()),
                ],
             );
          }
        },
      ),
    );
  }
}