import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mgw_tutorial/screens/library/image_viwer_screen.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/lesson.dart';
import '../../models/section.dart';
import '../../provider/lesson_provider.dart';
import '../../utils/download_status.dart';
import '../video_player_screen.dart';
import '../pdf_reader_screen.dart';
import '../html_viewer.dart';
import '../../constants/color.dart';
import '../../services/media_service.dart';
import 'lesson_tab_content.dart';

class LessonListScreen extends StatefulWidget {
  static const routeName = '/lesson-list';
  final Section section;

  const LessonListScreen({
    super.key,
    required this.section,
  });

  @override
  State<LessonListScreen> createState() => _LessonListScreenState();
}

class _LessonListScreenState extends State<LessonListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LessonProvider>(context, listen: false)
          .fetchLessonsForSection(widget.section.id);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshLessons() async {
    await Provider.of<LessonProvider>(context, listen: false)
        .fetchLessonsForSection(widget.section.id, forceRefresh: true);
  }

  Future<void> _playOrLaunchContent(BuildContext context, Lesson lesson) async {
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final String? downloadId = lessonProvider.getDownloadId(lesson);
    DownloadStatus downloadStatus = DownloadStatus.notDownloaded;
    String? localFilePath;

    if (downloadId != null) {
      downloadStatus = lessonProvider.getDownloadStatusNotifier(downloadId).value;
      if (downloadStatus == DownloadStatus.downloaded) {
        localFilePath = await lessonProvider.getDownloadedFilePath(lesson);

        if (localFilePath == null || localFilePath.isEmpty || !await File(localFilePath).exists()) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.errorContainer,
                content: Text(l10n.couldNotFindDownloadedFileError),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          localFilePath = null;
          MediaService.getDownloadStatus(downloadId).value = DownloadStatus.notDownloaded;
          MediaService.getDownloadProgress(downloadId).value = 0.0;
          downloadStatus = DownloadStatus.notDownloaded;
        }
      }
    }

    String? contentUrl;
    bool isLocal = false;

    if (downloadStatus == DownloadStatus.downloaded && localFilePath != null) {
      contentUrl = localFilePath;
      isLocal = true;
    } else if (downloadStatus == DownloadStatus.downloading) {
      String message = l10n.documentIsDownloadingMessage;
      if (lesson.lessonType == LessonType.video || (lesson.lessonType == LessonType.exam && lesson.examType == ExamType.video_exam)) {
        message = l10n.videoIsDownloadingMessage;
      } else if (lesson.lessonType == LessonType.note || (lesson.lessonType == LessonType.exam && lesson.examType == ExamType.note_exam)) {
        message = l10n.documentIsDownloadingMessage;
      } else if (lesson.lessonType == LessonType.attachment || (lesson.lessonType == LessonType.exam && lesson.examType == ExamType.attachment)) {
        message = l10n.documentIsDownloadingMessage;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: isDarkMode ? AppColors.secondaryContainerDark : AppColors.secondaryContainerLight,
            content: Text(message),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    } else {
      if ((lesson.lessonType == LessonType.video || (lesson.lessonType == LessonType.exam && lesson.examType == ExamType.video_exam)) &&
          lesson.videoUrl != null &&
          lesson.videoUrl!.isNotEmpty) {
        contentUrl = lesson.videoUrl;
      } else if ((lesson.lessonType == LessonType.attachment || (lesson.lessonType == LessonType.exam && lesson.examType == ExamType.attachment)) &&
          lesson.attachmentUrl != null &&
          lesson.attachmentUrl!.isNotEmpty) {
        contentUrl = lesson.attachmentUrl;
      } else if ((lesson.lessonType == LessonType.note || (lesson.lessonType == LessonType.exam && lesson.examType == ExamType.note_exam)) &&
          lesson.richText != null &&
          lesson.richText!.isNotEmpty) {
        contentUrl = lesson.richText;
      } else if (lesson.lessonType == LessonType.exam && lesson.examType == ExamType.image && lesson.attachmentUrl != null && lesson.attachmentUrl!.isNotEmpty) {
        contentUrl = lesson.attachmentUrl;
      }
    }

    const String baseUrl = "https://lessonservice.mgwcommunity.com";
    if (!isLocal && contentUrl != null && contentUrl.isNotEmpty && !contentUrl.startsWith("http")) {
      contentUrl = "$baseUrl$contentUrl";
    }

    if (contentUrl == null || contentUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.errorContainer,
            content: Text(l10n.itemNotAvailable(lesson.title)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    final allLessonsForSection = lessonProvider.lessonsForSection(widget.section.id);

    if (lesson.lessonType == LessonType.video || (lesson.lessonType == LessonType.exam && lesson.examType == ExamType.video_exam)) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => VideoPlayerScreen(
            videoTitle: lesson.title,
            videoPath: isLocal ? contentUrl! : '',
            originalVideoUrl: isLocal ? lesson.videoUrl : contentUrl,
            lessons: allLessonsForSection,
            isLocal: isLocal,
          ),
        ),
      );
    } else if (lesson.lessonType == LessonType.attachment || (lesson.lessonType == LessonType.exam && lesson.examType == ExamType.attachment)) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => PdfReaderScreen(
            pdfUrl: contentUrl!,
            title: lesson.title,
            isLocal: isLocal,
          ),
        ),
      );
    } else if (lesson.lessonType == LessonType.note || (lesson.lessonType == LessonType.exam && lesson.examType == ExamType.note_exam)) {
      final String viewerUrl = isLocal ? Uri.file(contentUrl!).toString() : contentUrl!;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => HtmlViewer(
            url: viewerUrl,
            title: lesson.title,
            // isLocal: isLocal,
          ),
        ),
      );
    } else if (lesson.lessonType == LessonType.exam && lesson.examType == ExamType.image) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => ImageViewerScreen(
            imageUrl: contentUrl!,
            title: lesson.title,
            isLocal: isLocal,
          ),
        ),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.errorContainer,
            content: Text('${l10n.itemNotAvailable(lesson.title)}: Unsupported type'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final lessonProvider = Provider.of<LessonProvider>(context);
    final List<Lesson> lessons = lessonProvider.lessonsForSection(widget.section.id);
    final bool isLoading = lessonProvider.isLoadingForSection(widget.section.id);
    final String? error = lessonProvider.errorForSection(widget.section.id);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final dynamicAppBarBackground = isDarkMode ? AppColors.appBarBackgroundDark : AppColors.appBarBackgroundLight;
    final dynamicScaffoldBackground = isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight;
    final dynamicPrimaryColor = isDarkMode ? AppColors.primaryDark : AppColors.primaryLight;
    final dynamicOnPrimaryColor = isDarkMode ? AppColors.onPrimaryDark : AppColors.onPrimaryLight;
    final dynamicOnSurfaceColor = isDarkMode ? AppColors.onSurfaceDark : AppColors.onSurfaceLight;

    if (isLoading && lessons.isEmpty && error == null) {
      return Scaffold(
        backgroundColor: dynamicScaffoldBackground,
        appBar: AppBar(
          title: Text(widget.section.title, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleLarge?.copyWith(fontSize: 18)),
          backgroundColor: dynamicAppBarBackground,
          titleSpacing: 0,
        ),
        body: Center(
          child: CircularProgressIndicator(color: dynamicPrimaryColor),
        ),
      );
    }

    if (error != null && lessons.isEmpty && !isLoading) {
      return Scaffold(
        backgroundColor: dynamicScaffoldBackground,
        appBar: AppBar(
          title: Text(widget.section.title, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleLarge?.copyWith(fontSize: 18)),
          backgroundColor: dynamicAppBarBackground,
          titleSpacing: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: AppColors.error, size: 50),
                const SizedBox(height: 16),
                Text(
                  l10n.failedToLoadLessonsError(error),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: dynamicOnSurfaceColor.withOpacity(0.7)),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.refresh),
                  onPressed: isLoading ? null : _refreshLessons,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dynamicPrimaryColor,
                    foregroundColor: dynamicOnPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (lessons.isEmpty && !isLoading && error == null) {
      return Scaffold(
        backgroundColor: dynamicScaffoldBackground,
        appBar: AppBar(
          title: Text(widget.section.title, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleLarge?.copyWith(fontSize: 18)),
          backgroundColor: dynamicAppBarBackground,
          titleSpacing: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hourglass_empty_outlined, size: 60, color: (isDarkMode ? AppColors.iconDark : AppColors.iconLight).withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  l10n.noLessonsInChapter,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(color: dynamicOnSurfaceColor),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.refresh),
                  onPressed: isLoading ? null : _refreshLessons,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dynamicPrimaryColor,
                    foregroundColor: dynamicOnPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: dynamicScaffoldBackground,
      appBar: AppBar(
        title: Text(widget.section.title, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleLarge?.copyWith(fontSize: 18)),
        backgroundColor: dynamicAppBarBackground,
        titleSpacing: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: dynamicPrimaryColor,
          unselectedLabelColor: dynamicOnSurfaceColor.withOpacity(0.6),
          indicatorColor: dynamicPrimaryColor,
          labelStyle: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          unselectedLabelStyle: theme.textTheme.titleSmall,
          tabs: [
            Tab(text: l10n.videoItemType),
            Tab(text: l10n.notesItemType),
            Tab(text: "l10n.attachmentItemType"),
            Tab(text: l10n.examsItemType),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          RefreshIndicator(
            onRefresh: _refreshLessons,
            child: LessonTabContent(
              sectionId: widget.section.id,
              lessons: lessons,
              lessonProvider: lessonProvider,
              filterType: LessonType.video,
              noContentMessage: l10n.noVideosAvailable,
              emptyIcon: Icons.video_library_outlined,
              isNotesTab: false,
              primaryColor: dynamicPrimaryColor,
              playOrLaunchContentCallback: _playOrLaunchContent,
            ),
          ),
          RefreshIndicator(
            onRefresh: _refreshLessons,
            child: LessonTabContent(
              sectionId: widget.section.id,
              lessons: lessons,
              lessonProvider: lessonProvider,
              filterType: LessonType.note,
              noContentMessage: l10n.noNotesAvailable,
              emptyIcon: Icons.notes_outlined,
              isNotesTab: true,
              primaryColor: dynamicPrimaryColor,
              playOrLaunchContentCallback: _playOrLaunchContent,
            ),
          ),
          RefreshIndicator(
            onRefresh: _refreshLessons,
            child: LessonTabContent(
              sectionId: widget.section.id,
              lessons: lessons,
              lessonProvider: lessonProvider,
              filterType: LessonType.attachment,
              noContentMessage: "l10n.noAttachmentsAvailable",
              emptyIcon: Icons.description_outlined,
              isNotesTab: false,
              primaryColor: dynamicPrimaryColor,
              playOrLaunchContentCallback: _playOrLaunchContent,
            ),
          ),
          RefreshIndicator(
            onRefresh: _refreshLessons,
            child: LessonTabContent(
              sectionId: widget.section.id,
              lessons: lessons,
              lessonProvider: lessonProvider,
              filterType: LessonType.exam,
              noContentMessage: l10n.noExamsAvailable,
              emptyIcon: Icons.quiz_outlined,
              isNotesTab: false,
              primaryColor: dynamicPrimaryColor,
              playOrLaunchContentCallback: _playOrLaunchContent,
            ),
          ),
        ],
      ),
    );
  }
}