// lib/screens/sidebar/weekly_exams_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/l10n/app_localizations.dart';
import 'package:mgw_tutorial/constants/color.dart';
import 'package:mgw_tutorial/widgets/subject_card.dart'; // Import SubjectCard
import 'package:mgw_tutorial/provider/subject_provider.dart'; // Import the SubjectProvider

class WeeklyExamsScreen extends StatefulWidget {
  static const routeName = '/weekly_exams'; // Define a route name

  const WeeklyExamsScreen({super.key});

  @override
  State<WeeklyExamsScreen> createState() => _WeeklyExamsScreenState();
}

class _WeeklyExamsScreenState extends State<WeeklyExamsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch subjects when the screen is initialized
    // Using listen: false because we only need to trigger the fetch here,
    // not rebuild the state based on it immediately.
    Provider.of<SubjectProvider>(context, listen: false).fetchSubjects();
  }

  Future<void> _refreshSubjects(BuildContext context) async {
     // Trigger a refresh fetch
    await Provider.of<SubjectProvider>(context, listen: false).fetchSubjects(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Watch the SubjectProvider for changes in state (loading, error, subjects list)
    final subjectProvider = Provider.of<SubjectProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.weeklyexam), // Use localization key for app bar title
        backgroundColor: isDarkMode ? AppColors.appBarBackgroundDark : AppColors.appBarBackgroundLight,
        actions: [
           // Optional: Add a refresh button
           IconButton(
             icon: Icon(Icons.refresh),
             onPressed: subjectProvider.isLoading ? null : () => _refreshSubjects(context),
           ),
        ],
      ),
      body: Builder( // Use Builder to get a context for the SnackBar
        builder: (BuildContext context) {
           if (subjectProvider.isLoading && subjectProvider.subjects.isEmpty) {
             // Show a loading indicator only if no data is currently available
             return const Center(child: CircularProgressIndicator());
           } else if (subjectProvider.errorMessage != null && subjectProvider.subjects.isEmpty) {
             // Show an error message if there's an error and no data
             return Center(
               child: Padding(
                 padding: const EdgeInsets.all(16.0),
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 40),
                     const SizedBox(height: 16),
                     Text(
                       // TODO: Add a localization key for this error message
                       'Error: ${subjectProvider.errorMessage}',
                       textAlign: TextAlign.center,
                       style: TextStyle(
                         fontSize: 16,
                         color: Theme.of(context).colorScheme.error,
                       ),
                     ),
                     const SizedBox(height: 16),
                     ElevatedButton(
                       onPressed: subjectProvider.isLoading ? null : () => _refreshSubjects(context),
                       // TODO: Add a localization key for Retry
                       child: subjectProvider.isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Retry'),
                     ),
                   ],
                 ),
               ),
             );
           } else if (subjectProvider.subjects.isEmpty) {
             // Show a message if data loading is complete but the list is empty
              return Center(
                child: Text(
                  // TODO: Add a localization key for this message
                  'No subjects available.',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              );
           } else {
             // If data is available (either initially loaded or after refresh/retry), display the list
             // Use a Stack to potentially overlay a loading indicator on top of the list
             return Stack(
               children: [
                 ListView.builder(
                   itemCount: subjectProvider.subjects.length,
                   itemBuilder: (context, index) {
                     final subject = subjectProvider.subjects[index];
                     return SubjectCard(
                       id: subject.id,
                       name: subject.name,
                       category: subject.category,
                       year: subject.year,
                       imageUrl: subject.imageUrl,
                       onTap: () {
                         // TODO: Implement navigation to a screen showing weekly exams for this specific subject
                         ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(content: Text('Tapped ${subject.name} (ID: ${subject.id}). (Navigation to exams for this subject not implemented)')),
                         );
                       },
                     );
                   },
                 ),
                 // Show a loading indicator on top if refreshing data while list is visible
                 if (subjectProvider.isLoading && subjectProvider.subjects.isNotEmpty)
                    const Opacity(
                      opacity: 0.6,
                      child: ModalBarrier(dismissible: false, color: Colors.black),
                    ),
                 if (subjectProvider.isLoading && subjectProvider.subjects.isNotEmpty)
                    const Center(child: CircularProgressIndicator()),
               ],
             );
           }
        },
      ),
    );
  }
}