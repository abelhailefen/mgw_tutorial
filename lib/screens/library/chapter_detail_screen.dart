import 'package:flutter/material.dart';

// Mock data for chapter content - extend _allSubjectChaptersData or fetch separately
// For simplicity, we'll access parts of the chapter map passed as argument.
// Example structure within a chapter map from _allSubjectChaptersData:
// 'videos': [{'title': 'Video 1.1', 'url': '...'}, {'title': 'Video 1.2', 'url': '...'}],
// 'notes': 'These are the detailed notes for the chapter...',
// 'pdfs': [{'title': 'Chapter PDF', 'url': '...'}, {'title': 'Worksheet', 'url': '...'}],
// 'exams': [{'title': 'Quiz 1', 'questionCount': 10}, {'title': 'Midterm Practice', 'questionCount': 25}]

class ChapterDetailScreen extends StatelessWidget {
  static const routeName = '/chapter-detail';

  final String subjectTitle;
  final Map<String, dynamic> chapter; // Contains chapter id, title, and potentially content links/data

  const ChapterDetailScreen({
    super.key,
    required this.subjectTitle,
    required this.chapter,
  });

  @override
  Widget build(BuildContext context) {
    // Example: Accessing mock content (you'd populate this in _allSubjectChaptersData)
    final List<Map<String, String>> videos = List<Map<String, String>>.from(chapter['videos'] ?? [
      {'title': 'Basics of Algebra - Part 1', 'description': 'Introduction to variables and expressions'},
      {'title': 'Basics of Algebra - Part 2', 'description': 'More on expressions'},
    ]);
    final String notesContent = chapter['notes'] ?? 'No notes available for this chapter yet.';
    final List<Map<String, String>> pdfs = List<Map<String, String>>.from(chapter['pdfs'] ?? [
      {'title': 'Chapter Summary PDF', 'url': '...'},
    ]);
    final List<Map<String, dynamic>> exams = List<Map<String, dynamic>>.from(chapter['exams'] ?? [
      {'title': 'Practice Quiz', 'questionCount': 5},
    ]);


    return DefaultTabController(
      length: 4, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: Text('${subjectTitle} - ${chapter['title']}'),
          bottom: const TabBar(
            isScrollable: false, // Set to true if you have many tabs
            tabs: [
              Tab(text: 'Videos'),
              Tab(text: 'Notes'),
              Tab(text: 'PDF'),
              Tab(text: 'Exams'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Videos Tab Content
            _buildVideoList(videos),

            // Notes Tab Content
            _buildNotesView(notesContent),

            // PDF Tab Content
            _buildPdfList(pdfs),

            // Exams Tab Content
            _buildExamList(exams),
          ],
        ),
      ),
    );
  }

  // Placeholder widget builders for tab content
  Widget _buildVideoList(List<Map<String, String>> videos) {
    if (videos.isEmpty) return const Center(child: Text('No videos available yet.'));
    return ListView.builder(
      itemCount: videos.length,
      itemBuilder: (ctx, index) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: const Icon(Icons.play_circle_fill_rounded, color: Colors.red, size: 36),
            title: Text(videos[index]['title']!),
            subtitle: Text(videos[index]['description'] ?? ''),
            onTap: () { /* TODO: Implement video player or navigation */ },
          ),
        );
      },
    );
  }

  Widget _buildNotesView(String notes) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Text(notes, style: const TextStyle(fontSize: 16, height: 1.5)),
    );
  }

  Widget _buildPdfList(List<Map<String, String>> pdfs) {
     if (pdfs.isEmpty) return const Center(child: Text('No PDFs available yet.'));
    return ListView.builder(
      itemCount: pdfs.length,
      itemBuilder: (ctx, index) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.green, size: 36),
            title: Text(pdfs[index]['title']!),
            onTap: () { /* TODO: Implement PDF viewer or download */ },
          ),
        );
      },
    );
  }

  Widget _buildExamList(List<Map<String, dynamic>> exams) {
    if (exams.isEmpty) return const Center(child: Text('No exams available yet.'));
    return ListView.builder(
      itemCount: exams.length,
      itemBuilder: (ctx, index) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: const Icon(Icons.assignment, color: Colors.blue, size: 36),
            title: Text(exams[index]['title']!),
            subtitle: Text('Questions: ${exams[index]['questionCount'] ?? 'N/A'}'),
            onTap: () { /* TODO: Implement exam taking screen */ },
          ),
        );
      },
    );
  }
}