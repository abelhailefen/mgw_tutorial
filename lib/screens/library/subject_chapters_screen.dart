import 'package:flutter/material.dart';
import 'package:mgw_tutorial/screens/library/chapter_detail_screen.dart'; 

// Mock data for chapters - In a real app, this would come from a database/API
// Structure: Subject -> List of Chapters -> Chapter details
final Map<String, List<Map<String, dynamic>>> _allSubjectChaptersData = {
  'Maths': [
    {'id': 'math_ch1', 'title': 'Chapter 1 - Introduction to Algebra', 'videoCount': 5, 'noteSummary': 'Basics of variables...'},
    {'id': 'math_ch2', 'title': 'Chapter 2 - Limits', 'videoCount': 3, 'noteSummary': 'Understanding limits...'},
    {'id': 'math_ch3', 'title': 'Chapter 3 - Differential Equations', 'videoCount': 7, 'noteSummary': 'Solving DEs...'},
    {'id': 'math_ch4', 'title': 'Chapter 4 - Applications of Differential Eq...', 'videoCount': 4, 'noteSummary': 'Real-world uses...'},
  ],
  'Physics': [
    {'id': 'phy_ch1', 'title': 'Chapter 1 - Kinematics', 'videoCount': 6},
    {'id': 'phy_ch2', 'title': 'Chapter 2 - Dynamics', 'videoCount': 8},
  ],
  // Add more subjects and their chapters
};


class SubjectChaptersScreen extends StatelessWidget {
  static const routeName = '/subject-chapters';

  final String subjectTitle;

  const SubjectChaptersScreen({super.key, required this.subjectTitle});

  @override
  Widget build(BuildContext context) {
    // Get chapters for the current subject, or an empty list if not found
    final List<Map<String, dynamic>> chapters = _allSubjectChaptersData[subjectTitle] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(subjectTitle), // Display subject name in AppBar
      ),
      body: chapters.isEmpty
          ? Center(child: Text('No chapters available for $subjectTitle yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: chapters.length,
              itemBuilder: (ctx, index) {
                final chapter = chapters[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                  elevation: 3,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                    leading: CircleAvatar( // Or an Icon
                      child: Text('${index + 1}'),
                      backgroundColor: Theme.of(context).primaryColorLight,
                      foregroundColor: Theme.of(context).primaryColorDark,
                    ),
                    title: Text(
                      chapter['title'],
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 17),
                    ),
                    // subtitle: Text('Videos: ${chapter['videoCount'] ?? 0}'), // Example subtitle
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        ChapterDetailScreen.routeName,
                        arguments: {
                          'subjectTitle': subjectTitle,
                          'chapter': chapter, // Pass the whole chapter map
                        },
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}