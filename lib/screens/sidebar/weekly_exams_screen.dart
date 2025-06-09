// lib/screens/sidebar/weekly_exams_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/l10n/app_localizations.dart';
import 'package:mgw_tutorial/constants/color.dart'; // Assuming AppColors is here
import 'package:mgw_tutorial/widgets/subject_card.dart';
import 'package:mgw_tutorial/provider/subject_provider.dart';
// Import the screen you navigate to
import 'package:mgw_tutorial/screens/sidebar/chapter_list_screen.dart';


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
    // Use addPostFrameCallback to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<SubjectProvider>(context, listen: false).fetchSubjects();
    });
  }

  Future<void> _refreshSubjects(BuildContext context) async {
    await Provider.of<SubjectProvider>(context, listen: false).fetchSubjects(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final subjectProvider = Provider.of<SubjectProvider>(context);

    final isLoading = subjectProvider.isLoading;
    final errorMessage = subjectProvider.errorMessage;
    final subjects = subjectProvider.subjects;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.weeklyexam),
        backgroundColor: isDarkMode ? AppColors.appBarBackgroundDark : AppColors.appBarBackgroundLight,
        actions: [
           IconButton(
             icon: const Icon(Icons.refresh),
             onPressed: isLoading ? null : () => _refreshSubjects(context),
           ),
        ],
      ),
      body: Builder( // Use Builder to get a context under the Scaffold
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
                       'Error: $errorMessage', // TODO: Localize
                       textAlign: TextAlign.center,
                       style: TextStyle(
                         fontSize: 16,
                         color: Theme.of(context).colorScheme.error,
                       ),
                     ),
                     const SizedBox(height: 16),
                     ElevatedButton(
                       onPressed: isLoading ? null : () => _refreshSubjects(context),
                       child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Retry'), // TODO: Localize
                     ),
                   ],
                 ),
               ),
             );
           } else if (subjects.isEmpty) {
              return Center(
                child: Text(
                  'No subjects available.', // TODO: Localize
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
                       // Provide the onTap logic here
                       onTap: () {
                         Navigator.pushNamed(
                           context,
                           ChapterListScreen.routeName,
                           arguments: {
                             'subjectId': subject.id,
                             'subjectName': subject.name,
                           },
                         );
                       },
                     );
                   },
                 ),
                 // Loading overlay when data is already present but refreshing
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