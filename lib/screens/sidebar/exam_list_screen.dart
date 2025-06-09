// lib/screens/sidebar/exam_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mgw_tutorial/l10n/app_localizations.dart';
import 'package:mgw_tutorial/constants/color.dart';
import 'package:mgw_tutorial/provider/exam_provider.dart';
import 'package:mgw_tutorial/models/exam.dart'; // Import Exam model
// Import the screen you navigate to
import 'package:mgw_tutorial/screens/sidebar/exam_taking_screen.dart';


class ExamListScreen extends StatefulWidget {
  static const routeName = '/exam_list';

  // Screen requires subject, chapter ID and name to fetch exams and pass down
  final int subjectId;
  final String subjectName;
  final int chapterId;
  final String chapterName;
  // This preference is used ONLY for filtering the LIST displayed here
  final bool showExplanationsBeforeSubmit;

  const ExamListScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.chapterId,
    required this.chapterName,
    required this.showExplanationsBeforeSubmit,
  });

  @override
  State<ExamListScreen> createState() => _ExamListScreenState();
}

class _ExamListScreenState extends State<ExamListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ExamProvider>(context, listen: false).fetchExamsForChapter(widget.chapterId);
    });
  }

  Future<void> _refreshExams() async {
    if (!mounted) return;
    await Provider.of<ExamProvider>(context, listen: false).fetchExamsForChapter(widget.chapterId, forceRefresh: true);
  }

  // Helper to format date or show "N/A"
  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('yyyy-MM-dd hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final examProvider = Provider.of<ExamProvider>(context);

    final isLoading = examProvider.isLoading(widget.chapterId);
    final errorMessage = examProvider.getErrorMessage(widget.chapterId);
    final allExamsForChapter = examProvider.getExams(widget.chapterId);

    // Filter the exams based on the received preference
    final List<Exam> filteredExams = allExamsForChapter?.where((exam) {
      return exam.isAnswerBefore == widget.showExplanationsBeforeSubmit;
    }).toList() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.chapterName} Exams'), // TODO: Localize "Exams"
        backgroundColor: isDarkMode ? AppColors.appBarBackgroundDark : AppColors.appBarBackgroundLight,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isLoading ? null : _refreshExams,
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
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
                       'Error loading exams: ${errorMessage!}',
                       textAlign: TextAlign.center,
                       style: TextStyle(
                         fontSize: 16,
                         color: Theme.of(context).colorScheme.error,
                       ),
                     ),
                     const SizedBox(height: 16),
                     ElevatedButton(
                       onPressed: isLoading ? null : _refreshExams,
                       child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Retry'),
                     ),
                   ],
                 ),
               ),
             );
           } else if (filteredExams.isEmpty) {
                String message = 'No exams available for ${widget.chapterName}';
                if (widget.showExplanationsBeforeSubmit) {
                   message += ' with explanations shown before submit.';
                } else {
                   message += ' with explanations shown after submit.';
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
             return Stack(
                children: [
                  ListView.builder(
                    itemCount: filteredExams.length,
                    itemBuilder: (context, index) {
                      final exam = filteredExams[index];
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
                                  child: Text(exam.description!, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                                ),
                              const SizedBox(height: 8),
                              Text('Type: ${exam.examType}'),
                              Text('Questions: ${exam.totalQuestions}'),
                              Text('Time Limit: ${exam.timeLimit} minutes'),
                              Text('Passing Score: ${exam.passingScore}%'),
                               Text('Explanation: ${exam.isAnswerBefore ? 'Before Submit' : 'After Submit'}'), // Show the exam's actual setting
                              if (exam.startDate != null) Text('Start Date: ${_formatDate(exam.startDate)}'),
                              if (exam.endDate != null) Text('End Date: ${_formatDate(exam.endDate)}'),
                            ],
                          ),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                             child: Text(exam.examType.isNotEmpty ? exam.examType.substring(0, 1).toUpperCase() : 'E'),
                          ),
                          onTap: () {
                            // Navigate to the ExamTakingScreen, passing the full Exam object
                             Navigator.pushNamed(
                               context,
                               ExamTakingScreen.routeName,
                               arguments: {
                                 'exam': exam, // <-- Pass the full Exam object
                                 // subjectId, chapterId are contained within the Exam object
                                 // examTitle is contained within the Exam object
                               },
                             );
                          },
                        ),
                      );
                    },
                  ),
                   if (isLoading && filteredExams.isNotEmpty)
                      const Opacity(
                        opacity: 0.6,
                        child: ModalBarrier(dismissible: false, color: Colors.black),
                      ),
                   if (isLoading && filteredExams.isNotEmpty)
                      const Center(child: CircularProgressIndicator()),
                ],
             );
          }
        },
      ),
    );
  }
}