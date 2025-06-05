// lib/screens/sidebar/chapter_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/l10n/app_localizations.dart';
import 'package:mgw_tutorial/constants/color.dart';
import 'package:mgw_tutorial/provider/chapter_provider.dart';
import 'package:mgw_tutorial/models/chapter.dart';
// Import the new ExamListScreen
import 'package:mgw_tutorial/screens/sidebar/exam_list_screen.dart';

class ChapterListScreen extends StatefulWidget {
  static const routeName = '/chapter_list';

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
    Provider.of<ChapterProvider>(context, listen: false).fetchChaptersForSubject(widget.subjectId);
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
    final chapters = chapterProvider.getChapters(widget.subjectId);

    return Scaffold(
      appBar: AppBar(
        // TODO: Add localization key for "Chapters"
        title: Text('${widget.subjectName} Chapters'),
        backgroundColor: isDarkMode ? AppColors.appBarBackgroundDark : AppColors.appBarBackgroundLight,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: isLoading ? null : _refreshChapters,
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
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
              return Center(
                child: Text(
                  // TODO: Add localization key for this message
                  'No chapters available for ${widget.subjectName}.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              );
          } else {
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
                          // Navigate to the ExamListScreen
                           Navigator.pushNamed(
                             context,
                             ExamListScreen.routeName,
                             arguments: {
                               'chapterId': chapter.id,
                               'chapterName': chapter.name,
                             },
                           );
                        },
                      );
                    },
                  ),
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