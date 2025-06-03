import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/l10n/app_localizations.dart';
import 'package:mgw_tutorial/constants/color.dart';
import 'package:mgw_tutorial/models/lesson.dart';
import 'package:mgw_tutorial/provider/lesson_provider.dart';
import 'package:mgw_tutorial/screens/exam_viewer_screen.dart';
import 'package:mgw_tutorial/utils/download_status.dart';
import 'package:mgw_tutorial/provider/api_course_provider.dart';
import 'package:mgw_tutorial/provider/section_provider.dart';

class MyExamsScreen extends StatefulWidget {
  static const routeName = '/my-exams';

  const MyExamsScreen({super.key});

  @override
  State<MyExamsScreen> createState() => _MyExamsScreenState();
}

class _MyExamsScreenState extends State<MyExamsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Lesson> _exams = [];

  @override
  void initState() {
    super.initState();
    _fetchExams();
  }

  Future<void> _fetchExams() async {
    final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
    final apiCourseProvider = Provider.of<ApiCourseProvider>(context, listen: false);
    final sectionProvider = Provider.of<SectionProvider>(context, listen: false);
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await apiCourseProvider.fetchCourses(forceRefresh: false);
      final sectionIds = await _getSectionIds(apiCourseProvider, sectionProvider);

      for (final sectionId in sectionIds) {
        await lessonProvider.fetchLessonsForSection(sectionId, forceRefresh: false);
      }

      final allExams = lessonProvider.getAllLessons()
          .where((lesson) => lesson.lessonType == LessonType.quiz)
          .toList();

      setState(() {
        _exams = allExams;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = AppLocalizations.of(context)?.errorLoadingExams ?? 'Failed to load exams';
      });
      print('Error fetching exams: $e');
    }
  }

  Future<List<int>> _getSectionIds(ApiCourseProvider courseProvider, SectionProvider sectionProvider) async {
    try {
      final courses = courseProvider.courses;
      final sectionIds = <int>{};

      for (final course in courses) {
        await sectionProvider.fetchSectionsForCourse(course.id, forceRefresh: false);
        final sections = sectionProvider.sectionsForCourse(course.id);
        final ids = sections.map((section) => section.id).where((id) => id != 0);
        sectionIds.addAll(ids);
      }

      print('Found ${sectionIds.length} section IDs: $sectionIds');
      return sectionIds.toList();
    } catch (e) {
      print('Error fetching section IDs: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myExams, style: TextStyle(color: AppColors.onPrimaryLight)),
        backgroundColor: AppColors.appBarBackgroundLight,
        iconTheme: IconThemeData(color: AppColors.onPrimaryLight),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: AppColors.error, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchExams,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryLight,
                          foregroundColor: AppColors.onPrimaryLight,
                        ),
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                )
              : _exams.isEmpty
                  ? Center(
                      child: Text(
                        l10n.noExamsAvailable,
                        style: TextStyle(color: AppColors.onSurfaceLight, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: _exams.length,
                      itemBuilder: (context, index) {
                        final exam = _exams[index];
                        return _buildExamTile(exam, context);
                      },
                    ),
    );
  }

  Widget _buildExamTile(Lesson exam, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final lessonProvider = Provider.of<LessonProvider>(context);
    final downloadId = lessonProvider.getDownloadId(exam);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: ListTile(
        title: Text(
          exam.title,
          style: TextStyle(
            color: AppColors.textPrimaryDark,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: exam.summary != null
            ? Text(
                exam.summary!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textSecondaryDark),
              )
            : null,
        trailing: downloadId != null
            ? _buildDownloadButton(exam, downloadId, lessonProvider, context)
            : null,
        onTap: () async {
          final filePath = await lessonProvider.getDownloadedFilePath(exam);
          Navigator.pushNamed(
            context,
            ExamViewerScreen.routeName,
            arguments: {
              'url': filePath ?? exam.htmlUrl!,
              'title': exam.title,
            },
          );
        },
      ),
    );
  }

  Widget _buildDownloadButton(
    Lesson exam,
    String downloadId,
    LessonProvider provider,
    BuildContext context,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return ValueListenableBuilder<DownloadStatus>(
      valueListenable: provider.getDownloadStatusNotifier(downloadId),
      builder: (context, status, _) {
        return ValueListenableBuilder<double>(
          valueListenable: provider.getDownloadProgressNotifier(downloadId),
          builder: (context, progress, _) {
            switch (status) {
              case DownloadStatus.notDownloaded:
              case DownloadStatus.failed:
              case DownloadStatus.cancelled:
                return IconButton(
                  icon: Icon(Icons.download, color: AppColors.downloadIconColor),
                  tooltip: l10n.downloadExamTooltip,
                  onPressed: () => provider.startDownload(exam),
                );
              case DownloadStatus.downloading:
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.backgroundLight,
                      color: AppColors.downloadProgressColor,
                    ),
                    IconButton(
                      icon: Icon(Icons.cancel, color: AppColors.error),
                      tooltip: l10n.cancelDownloadTooltip,
                      onPressed: () => provider.cancelDownload(exam),
                    ),
                  ],
                );
              case DownloadStatus.downloaded:
                return IconButton(
                  icon: Icon(Icons.delete, color: AppColors.deleteIconColor),
                  tooltip: l10n.deleteExamTooltip,
                  onPressed: () => provider.deleteDownload(exam, context),
                );
            }
          },
        );
      },
    );
  }
}