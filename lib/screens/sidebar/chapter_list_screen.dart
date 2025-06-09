// lib/screens/sidebar/chapter_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/l10n/app_localizations.dart';
import 'package:mgw_tutorial/constants/color.dart';
import 'package:mgw_tutorial/provider/chapter_provider.dart';
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
        // TODO: Add localization key for "Chapters" - using subject name is good
        title: Text('${widget.subjectName} Chapters'),
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
           if (isLoading && (chapters == null || chapters.isEmpty)) {
             return const Center(child: CircularProgressIndicator());
           } else if (errorMessage != null && (chapters == null || chapters.isEmpty)) {
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
                       'Error loading chapters: $errorMessage',
                       textAlign: TextAlign.center,
                       style: TextStyle(
                         fontSize: 16,
                         color: Theme.of(context).colorScheme.error,
                       ),
                     ),
                     const SizedBox(height: 16),
                     ElevatedButton(
                       onPressed: isLoading ? null : _refreshChapters,
                       // TODO: Add localization key for Retry
                       child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Retry'),
                     ),
                   ],
                 ),
               ),
             );
           } else if (chapters == null || chapters.isEmpty) {
               // This case is hit if chapters are loaded but the list is empty
              return Center(
                child: Text(
                  // TODO: Add localization key for this message
                  'No chapters available for ${widget.subjectName}.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              );
           } else {
             // Data is available, display the list
             return Stack(
                children: [
                  ListView.builder(
                    itemCount: chapters.length,
                    itemBuilder: (context, index) {
                      final chapter = chapters[index];
                      return ListTile(
                        title: Text(chapter.name),
                        subtitle: chapter.description != null && chapter.description!.isNotEmpty
                            ? Text(chapter.description!)
                            : null,
                        leading: CircleAvatar(
                          child: Text('${chapter.order + 1}'),
                        ),
                        onTap: () {
                          // Navigate to the ExamListScreen, passing subject and chapter info
                           Navigator.pushNamed(
                             context,
                             ExamListScreen.routeName,
                             arguments: {
                               'subjectId': widget.subjectId,    // Pass subjectId from this screen's args
                               'subjectName': widget.subjectName, // Pass subjectName from this screen's args
                               'chapterId': chapter.id,          // Pass chapterId from the tapped chapter
                               'chapterName': chapter.name,      // Pass chapterName from the tapped chapter
                             },
                           );
                        },
                      );
                    },
                  ),
                   // Loading overlay when data is already present but refreshing
                   if (isLoading && chapters.isNotEmpty)
                      const Opacity(
                        opacity: 0.6,
                        child: ModalBarrier(dismissible: false, color: Colors.black),
                      ),
                   if (isLoading && chapters.isNotEmpty)
                      const Center(child: CircularProgressIndicator()),
                ],
             );
          }
        },
      ),
    );
  }
}