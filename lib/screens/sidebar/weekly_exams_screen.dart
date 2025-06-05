// lib/screens/sidebar/weekly_exams_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/l10n/app_localizations.dart';
import 'package:mgw_tutorial/constants/color.dart';
import 'package:mgw_tutorial/widgets/subject_card.dart';
import 'package:mgw_tutorial/provider/subject_provider.dart';

class WeeklyExamsScreen extends StatefulWidget {
  static const routeName = '/weekly_exams';

  const WeeklyExamsScreen({super.key});

  @override
  State<WeeklyExamsScreen> createState() => _WeeklyExamsScreenState();
}

class _WeeklyExamsScreenState extends State<WeeklyExamsScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<SubjectProvider>(context, listen: false).fetchSubjects();
  }

  Future<void> _refreshSubjects(BuildContext context) async {
    await Provider.of<SubjectProvider>(context, listen: false).fetchSubjects(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final subjectProvider = Provider.of<SubjectProvider>(context);

    final isLoading = subjectProvider.isLoading; // Use provider's loading state
    final errorMessage = subjectProvider.errorMessage; // Use provider's error state
    final subjects = subjectProvider.subjects; // Use provider's data

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.weeklyexam),
        backgroundColor: isDarkMode ? AppColors.appBarBackgroundDark : AppColors.appBarBackgroundLight,
        actions: [
           IconButton(
             icon: Icon(Icons.refresh),
             onPressed: isLoading ? null : () => _refreshSubjects(context),
           ),
        ],
      ),
      body: Builder(
        builder: (BuildContext context) {
           if (isLoading && subjects.isEmpty) {
             return const Center(child: CircularProgressIndicator());
           } else if (errorMessage != null && subjects.isEmpty) {
             return Center(
               child: Padding(
                 padding: const EdgeInsets.all(16.0),
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 40),
                     const SizedBox(height: 16),
                     Text(
                       'Error: $errorMessage',
                       textAlign: TextAlign.center,
                       style: TextStyle(
                         fontSize: 16,
                         color: Theme.of(context).colorScheme.error,
                       ),
                     ),
                     const SizedBox(height: 16),
                     ElevatedButton(
                       onPressed: isLoading ? null : () => _refreshSubjects(context),
                       child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Retry'),
                     ),
                   ],
                 ),
               ),
             );
           } else if (subjects.isEmpty) {
              return Center(
                child: Text(
                  'No subjects available.',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              );
           } else {
             return Stack(
               children: [
                 ListView.builder(
                   itemCount: subjects.length,
                   itemBuilder: (context, index) {
                     final subject = subjects[index];
                     return SubjectCard(
                       id: subject.id,
                       name: subject.name,
                       category: subject.category,
                       year: subject.year,
                       imageUrl: subject.imageUrl,
                       // REMOVED onTap parameter here as SubjectCard handles navigation internally
                     );
                   },
                 ),
                 if (isLoading && subjects.isNotEmpty)
                    const Opacity(
                      opacity: 0.6,
                      child: ModalBarrier(dismissible: false, color: Colors.black),
                    ),
                 if (isLoading && subjects.isNotEmpty)
                    const Center(child: CircularProgressIndicator()),
               ],
             );
           }
        },
      ),
    );
  }
}