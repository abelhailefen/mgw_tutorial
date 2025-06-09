// lib/screens/sidebar/chapter_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/l10n/app_localizations.dart';
import 'package:mgw_tutorial/constants/color.dart'; // Assuming AppColors is defined here
import 'package:mgw_tutorial/provider/chapter_provider.dart';
import 'package:mgw_tutorial/models/chapter.dart';
// Import the screen you navigate to
import 'package:mgw_tutorial/screens/sidebar/exam_list_screen.dart';

class ChapterListScreen extends StatefulWidget {
  static const routeName = '/chapter_list';

  // Screen requires subject ID and name to fetch chapters and pass down
  final int subjectId;
  final String subjectName;

  const ChapterListScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  State<ChapterListScreen> createState() => _ChapterListScreenState();
}

class _ChapterListScreenState extends State<ChapterListScreen> {
  @override
  void initState() {
    super.initState();
     // Use addPostFrameCallback to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
       Provider.of<ChapterProvider>(context, listen: false).fetchChaptersForSubject(widget.subjectId);
    });
  }

  Future<void> _refreshChapters() async {
    await Provider.of<ChapterProvider>(context, listen: false).fetchChaptersForSubject(widget.subjectId, forceRefresh: true);
  }

  // --- Dialog function to show Explanation Preference Choice ---
  void _showExplanationChoiceDialog(BuildContext context, int chapterId, String chapterName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 16,
        // Use theme colors instead of hardcoded AppColors.color3
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        child: Container(
          padding: const EdgeInsets.all(20),
          // height: 250, // Let the column determine height
          child: Column(
            mainAxisSize: MainAxisSize.min, // Use minimum size
            crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch buttons
            children: [
              Text(
                'Explanation Preference', // TODO: Localize
                textAlign: TextAlign.center,
                style: TextStyle(
                  // Use theme colors instead of hardcoded AppColors.color1
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20), // Increased spacing
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Close the dialog
                  // Navigate to ExamListScreen with preference true
                  _navigateToExamList(context, chapterId, chapterName, true);
                },
                icon: const Icon(Icons.visibility),
                label: Text('Show Explanations Before Submit', textAlign: TextAlign.center), // TODO: Localize
                style: ElevatedButton.styleFrom(
                  // Use theme colors instead of hardcoded AppColors.color1
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 15), // Add padding
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 10), // Spacing between buttons
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Close the dialog
                   // Navigate to ExamListScreen with preference false
                  _navigateToExamList(context, chapterId, chapterName, false);
                },
                icon: const Icon(Icons.visibility_off),
                label: Text('Show Explanations After Submit', textAlign: TextAlign.center), // TODO: Localize
                style: ElevatedButton.styleFrom(
                  // Use theme colors instead of hardcoded AppColors.color2
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                   padding: const EdgeInsets.symmetric(vertical: 15), // Add padding
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 10), // Spacing at the bottom
            ],
          ),
        ),
      ),
    );
  }
  // --- End Dialog function ---

  // Helper function for navigation
  void _navigateToExamList(BuildContext context, int chapterId, String chapterName, bool showExplanationsBeforeSubmit) {
     Navigator.pushNamed(
       context,
       ExamListScreen.routeName,
       arguments: {
         'subjectId': widget.subjectId,
         'subjectName': widget.subjectName,
         'chapterId': chapterId,
         'chapterName': chapterName,
         'showExplanationsBeforeSubmit': showExplanationsBeforeSubmit, // Pass the chosen preference
       },
     );
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final chapterProvider = Provider.of<ChapterProvider>(context);

    final isLoading = chapterProvider.isLoading(widget.subjectId);
    final errorMessage = chapterProvider.getErrorMessage(widget.subjectId);
    final chapters = chapterProvider.getChapters(widget.subjectId); // This might be null initially

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.subjectName} Chapters'), // TODO: Localize "Chapters"
        backgroundColor: isDarkMode ? AppColors.appBarBackgroundDark : AppColors.appBarBackgroundLight,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isLoading ? null : _refreshChapters,
          ),
        ],
      ),
      body: Builder( // Use Builder to get a context under the Scaffold
        builder: (context) {
           // Handle null or empty chapters correctly
           final currentChapters = chapters; // Local variable for null safety

           if (isLoading && (currentChapters == null || currentChapters.isEmpty)) {
             return const Center(child: CircularProgressIndicator());
           } else if (errorMessage != null && (currentChapters == null || currentChapters.isEmpty)) {
             return Center(
               child: Padding(
                 padding: const EdgeInsets.all(16.0),
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 40),
                     const SizedBox(height: 16),
                     Text(
                       'Error loading chapters: ${errorMessage!}', // errorMessage is String?
                       textAlign: TextAlign.center,
                       style: TextStyle(
                         fontSize: 16,
                         color: Theme.of(context).colorScheme.error,
                       ),
                     ),
                     const SizedBox(height: 16),
                     ElevatedButton(
                       onPressed: isLoading ? null : _refreshChapters,
                       child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Retry'), // TODO: Localize
                     ),
                   ],
                 ),
               ),
             );
           } else if (currentChapters == null || currentChapters.isEmpty) {
              return Center(
                child: Text(
                  'No chapters available for ${widget.subjectName}.', // TODO: Localize
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              );
           } else {
             // Data is available, display the list
             return Stack(
                children: [
                  ListView.builder(
                    itemCount: currentChapters.length,
                    itemBuilder: (context, index) {
                      final chapter = currentChapters[index];
                      return ListTile(
                        title: Text(chapter.name),
                        subtitle: chapter.description != null && chapter.description!.isNotEmpty
                            ? Text(chapter.description!)
                            : null,
                        leading: CircleAvatar(
                           backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                           foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                           child: Text('${chapter.order + 1}'),
                        ),
                        onTap: () {
                           // Show the explanation choice dialog before navigating
                           _showExplanationChoiceDialog(context, chapter.id, chapter.name);
                        },
                      );
                    },
                  ),
                   // Loading overlay when data is already present but refreshing
                   if (isLoading && currentChapters.isNotEmpty)
                      const Opacity(
                        opacity: 0.6,
                        child: ModalBarrier(dismissible: false, color: Colors.black),
                      ),
                   if (isLoading && currentChapters.isNotEmpty)
                      const Center(child: CircularProgressIndicator()),
                ],
             );
          }
        },
      ),
    );
  }
}