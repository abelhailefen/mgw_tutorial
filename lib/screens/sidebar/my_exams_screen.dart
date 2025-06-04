import 'package:flutter/material.dart';
import 'package:mgw_tutorial/l10n/app_localizations.dart';
import 'package:mgw_tutorial/constants/color.dart';
import 'package:mgw_tutorial/screens/html_viewer.dart';

class MyExamsScreen extends StatefulWidget {
  static const routeName = '/my_exams';

  const MyExamsScreen({super.key});

  @override
  State<MyExamsScreen> createState() => _MyExamsScreenState();
}

class _MyExamsScreenState extends State<MyExamsScreen> {
  // Placeholder exam data (replace with your actual data)
  final List<Map<String, dynamic>> _exams = [
    {'title': 'Sample Exam 1', 'url': 'https://example.com/exam1.html'},
    {'title': 'Sample Exam 2', 'url': '/path/to/local/exam2.html'},
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myExams),
        backgroundColor: isDarkMode ? AppColors.appBarBackgroundDark : AppColors.appBarBackgroundLight,
      ),
      body: ListView.builder(
        itemCount: _exams.length,
        itemBuilder: (context, index) {
          final exam = _exams[index];
          return ListTile(
            title: Text(exam['title']),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => HtmlViewer(
                    url: exam['url'],
                    title: exam['title'],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}