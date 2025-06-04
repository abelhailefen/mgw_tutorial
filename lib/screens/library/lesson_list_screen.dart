import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mgw_tutorial/l10n/app_localizations.dart';

import 'package:mgw_tutorial/models/lesson.dart';
import 'package:mgw_tutorial/models/section.dart';
import 'package:mgw_tutorial/provider/lesson_provider.dart';
import 'package:mgw_tutorial/utils/download_status.dart';
import 'package:mgw_tutorial/screens/video_player_screen.dart';
import 'package:mgw_tutorial/screens/pdf_reader_screen.dart';
import 'package:mgw_tutorial/screens/exam_viewer_screen.dart';
import 'package:mgw_tutorial/constants/color.dart';

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
    _tabController = TabController(length: 3, vsync: this);

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
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final String? downloadId = lessonProvider.getDownloadId(lesson);
    DownloadStatus downloadStatus = DownloadStatus.notDownloaded;
    String? localFilePath;

    if (downloadId != null) {
        downloadStatus = lessonProvider.getDownloadStatusNotifier(downloadId).value;
        if(downloadStatus == DownloadStatus.downloaded) {
            localFilePath = await lessonProvider.getDownloadedFilePath(lesson);
        }
         if (downloadStatus == DownloadStatus.downloaded && (localFilePath == null || localFilePath.isEmpty || !await File(localFilePath).exists())) {
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
              downloadStatus = DownloadStatus.notDownloaded;
         }
    }

    if (lesson.lessonType == LessonType.video && lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty) {
      final List<Lesson> allLessonsForSection = lessonProvider.lessonsForSection(widget.section.id);

      if (localFilePath != null && downloadStatus == DownloadStatus.downloaded) {
          if (mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => VideoPlayerScreen(
                    videoTitle: lesson.title,
                    videoPath: localFilePath!,
                    originalVideoUrl: lesson.videoUrl,
                    lessons: allLessonsForSection,
                    isLocal: true,
                  ),
                ),
              );
          }
      } else if (downloadStatus == DownloadStatus.downloading) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
               backgroundColor: isDarkMode ? AppColors.secondaryContainerDark : AppColors.secondaryContainerLight,
              content: Text(l10n.videoIsDownloadingMessage),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      else {
         if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => VideoPlayerScreen(
                  videoTitle: lesson.title,
                  videoPath: '',
                  originalVideoUrl: lesson.videoUrl,
                  lessons: allLessonsForSection,
                  isLocal: false,
                ),
              ),
            );
         }
      }
    } else if (lesson.lessonType == LessonType.document && lesson.attachmentUrl != null && lesson.attachmentUrl!.isNotEmpty) {
       if (localFilePath != null && downloadStatus == DownloadStatus.downloaded) {
           if (mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => PdfReaderScreen(
                    pdfUrl: localFilePath!,
                    title: lesson.title,
                    isLocal: true,
                  ),
                ),
              );
           }
       } else if (downloadStatus == DownloadStatus.downloading) {
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(
                  backgroundColor: isDarkMode ? AppColors.secondaryContainerDark : AppColors.secondaryContainerLight,
                 content: Text(l10n.documentIsDownloadingMessage),
                 behavior: SnackBarBehavior.floating,
               ),
             );
           }
       }
       else {
          if (mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => PdfReaderScreen(
                    pdfUrl: lesson.attachmentUrl!,
                    title: lesson.title,
                    isLocal: false,
                  ),
                ),
              );
           }
       }
    } else if (lesson.lessonType == LessonType.quiz && lesson.htmlUrl != null && lesson.htmlUrl!.isNotEmpty) {
       if (localFilePath != null && downloadStatus == DownloadStatus.downloaded) {
           if (mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => ExamViewerScreen(
                    url: 'file://$localFilePath',
                    title: lesson.title,
                  ),
                ),
              );
           }
       } else if (downloadStatus == DownloadStatus.downloading) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                   backgroundColor: isDarkMode ? AppColors.secondaryContainerDark : AppColors.secondaryContainerLight,
                  content: Text(l10n.quizIsDownloadingMessage ?? l10n.documentIsDownloadingMessage),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
       }
       else {
          if (mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => ExamViewerScreen(
                    url: lesson.htmlUrl!,
                    title: lesson.title,
                  ),
                ),
              );
           }
       }
    }
     else if (lesson.lessonType == LessonType.text && lesson.summary != null && lesson.summary!.isNotEmpty) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (dCtx) => AlertDialog(
            backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
            title: Text(lesson.title, style: theme.textTheme.titleLarge),
            content: SingleChildScrollView(child: Text(lesson.summary ?? l10n.noTextContent, style: theme.textTheme.bodyLarge)),
            actions: [
              TextButton(
                child: Text(l10n.closeButtonText, style: TextStyle(color: isDarkMode ? AppColors.primaryDark : AppColors.primaryLight)),
                onPressed: () => Navigator.of(dCtx).pop(),
              ),
            ],
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: isDarkMode ? AppColors.secondaryContainerDark : AppColors.secondaryContainerLight,
            content: Text(l10n.noLaunchableContent(lesson.title)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildDownloadButton(BuildContext context, Lesson lesson, LessonProvider lessonProv) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isVideo = lesson.lessonType == LessonType.video;
    final isDocument = lesson.lessonType == LessonType.document;
    final isQuiz = lesson.lessonType == LessonType.quiz;

    if (!isVideo && !isDocument && !isQuiz) {
       return const SizedBox.shrink();
    }

     if ((isVideo && (lesson.videoUrl == null || lesson.videoUrl!.isEmpty)) ||
         (isDocument && (lesson.attachmentUrl == null || lesson.attachmentUrl!.isEmpty)) ||
         (isQuiz && (lesson.htmlUrl == null || lesson.htmlUrl!.isEmpty))) {
         return SizedBox(
           width: 40,
           height: 40,
           child: Center(
             child: Icon(
               Icons.cloud_off_outlined,
                color: (Theme.of(context).brightness == Brightness.dark ? AppColors.iconDark : AppColors.iconLight).withOpacity(0.3),
               size: 24.0, // Corrected typo here
             ),
           ),
         );
      }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final String? downloadId = lessonProv.getDownloadId(lesson);

    if (downloadId == null) {
         return SizedBox(
           width: 40,
           height: 40,
           child: Center(
             child: Icon(
               Icons.cloud_off_outlined,
                color: (isDarkMode ? AppColors.iconDark : AppColors.iconLight).withOpacity(0.3),
               size: 24.0, // Corrected typo here
             ),
           ),
         );
    }

    return SizedBox(
      width: 40,
      height: 40,
      child: ValueListenableBuilder<DownloadStatus>(
        valueListenable: lessonProv.getDownloadStatusNotifier(downloadId),
        builder: (context, status, child) {
          switch (status) {
            case DownloadStatus.notDownloaded:
            case DownloadStatus.failed:
            case DownloadStatus.cancelled:
              IconData icon;
              String tooltip;
              if (isVideo) {
                 icon = Icons.download_for_offline_outlined;
                 tooltip = l10n.downloadVideoTooltip;
              } else if (isDocument) {
                 icon = Icons.download_for_offline_outlined;
                 tooltip = l10n.downloadDocumentTooltip;
              } else { // isQuiz
                 icon = Icons.download_for_offline_outlined;
                 tooltip = l10n.downloadQuizTooltip ?? l10n.downloadDocumentTooltip;
              }
              return IconButton(
                 icon: Icon(icon, color: isDarkMode ? AppColors.secondaryDark : AppColors.secondaryLight),
                tooltip: tooltip,
                iconSize: 24,
                padding: EdgeInsets.zero,
                onPressed: () {
                  lessonProv.startDownload(lesson);
                },
              );
            case DownloadStatus.downloading:
              return ValueListenableBuilder<double>(
                valueListenable: lessonProv.getDownloadProgressNotifier(downloadId),
                builder: (context, progress, _) {
                  final safeProgress = progress.clamp(0.0, 1.0);
                  final progressText = safeProgress > 0 && safeProgress < 1 ? "${(safeProgress * 100).toInt()}%" : "";
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          value: safeProgress > 0 ? safeProgress : null,
                          strokeWidth: 3.0,
                          backgroundColor: (isDarkMode ? AppColors.onSurfaceDark : AppColors.onSurfaceLight).withOpacity(0.1),
                          color: isDarkMode ? AppColors.primaryDark : AppColors.primaryLight,
                        ),
                      ),
                       if (progressText.isNotEmpty)
                        Text(
                          progressText,
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                        ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: GestureDetector(
                          onTap: () {
                            lessonProv.cancelDownload(lesson);
                          },
                          child: Icon(
                            Icons.cancel,
                            size: 16,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            case DownloadStatus.downloaded:
               IconData downloadedIcon;
               String downloadedTooltip;
               if (isVideo) {
                 downloadedIcon = Icons.play_circle_outline_rounded;
                 downloadedTooltip = l10n.playDownloadedVideoTooltip;
               } else if (isDocument) {
                 downloadedIcon = Icons.description;
                 downloadedTooltip = l10n.openDownloadedDocumentTooltip;
               } else { // isQuiz
                  downloadedIcon = Icons.quiz_outlined;
                  downloadedTooltip = l10n.openDownloadedQuizTooltip ?? l10n.openDownloadedDocumentTooltip;
               }

              return IconButton(
                icon: Icon(
                  downloadedIcon,
                   color: isDarkMode ? AppColors.primaryDark : AppColors.primaryLight
                ),
                tooltip: downloadedTooltip,
                iconSize: 24,
                padding: EdgeInsets.zero,
                onPressed: () async {
                  await _playOrLaunchContent(context, lesson);
                },
              );
          }
        },
      ),
    );
  }

  Widget _buildLessonItem(BuildContext context, Lesson lesson, LessonProvider lessonProv) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    IconData lessonIcon;
    Color iconColor;
    String typeDescription;

    switch (lesson.lessonType) {
      case LessonType.video:
        lessonIcon = Icons.play_circle_outline_rounded;
        iconColor = AppColors.error;
        typeDescription = l10n.videoItemType;
        break;
      case LessonType.document:
        lessonIcon = Icons.description_outlined;
        iconColor = isDarkMode ? AppColors.secondaryDark : AppColors.secondaryLight;
        typeDescription = l10n.documentItemType;
        break;
      case LessonType.quiz:
        lessonIcon = Icons.quiz_outlined;
        iconColor = isDarkMode ? AppColors.secondaryDark : AppColors.secondaryLight;
        typeDescription = l10n.quizItemType;
        break;
      case LessonType.text:
        lessonIcon = Icons.notes_outlined;
        iconColor = isDarkMode ? AppColors.primaryDark : AppColors.primaryLight;
        typeDescription = l10n.textItemType;
        break;
      default:
        lessonIcon = Icons.extension_outlined;
        iconColor = (isDarkMode ? AppColors.onSurfaceDark : AppColors.iconLight).withOpacity(0.5);
        typeDescription = l10n.unknownItemType;
    }

    final String? downloadIdForStatus = (lesson.lessonType == LessonType.video || lesson.lessonType == LessonType.document || lesson.lessonType == LessonType.quiz)
        ? lessonProv.getDownloadId(lesson)
        : null;

    Widget deleteButton = const SizedBox.shrink();
    if (downloadIdForStatus != null && (lesson.lessonType == LessonType.video || lesson.lessonType == LessonType.document || lesson.lessonType == LessonType.quiz)) {
      deleteButton = SizedBox(
        width: 40,
        height: 40,
        child: ValueListenableBuilder<DownloadStatus>(
          valueListenable: lessonProv.getDownloadStatusNotifier(downloadIdForStatus),
          builder: (context, status, child) {
            if (status == DownloadStatus.downloaded) {
              return IconButton(
                icon: Icon(Icons.delete_outline, color: (isDarkMode ? AppColors.iconDark : AppColors.iconLight).withOpacity(0.6)),
                tooltip: l10n.deleteDownloadedFileTooltip,
                iconSize: 24,
                padding: EdgeInsets.zero,
                onPressed: () {
                  lessonProv.deleteDownload(lesson, context);
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      );
    }

    final bool showDownloadButton = lesson.lessonType == LessonType.video ||
                                     lesson.lessonType == LessonType.document ||
                                     lesson.lessonType == LessonType.quiz;

    final bool hasDownloadUrl = (lesson.lessonType == LessonType.video && lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty) ||
                                (lesson.lessonType == LessonType.document && lesson.attachmentUrl != null && lesson.attachmentUrl!.isNotEmpty) ||
                                (lesson.lessonType == LessonType.quiz && lesson.htmlUrl != null && lesson.htmlUrl!.isNotEmpty);


    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      color: isDarkMode ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: IconButton(
           icon: Icon(lessonIcon, color: iconColor, size: 36),
           onPressed: lesson.lessonType == LessonType.video && lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty
            ? () {
                final allLessonsForSection = lessonProv.lessonsForSection(widget.section.id);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => VideoPlayerScreen(
                      videoTitle: lesson.title,
                      videoPath: '',
                      originalVideoUrl: lesson.videoUrl!,
                      lessons: allLessonsForSection,
                      isLocal: false,
                    ),
                  ),
                );
              }
            : null,
        ),
        title: Text(lesson.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
        subtitle: lesson.summary != null && lesson.summary!.isNotEmpty
            ? Text(lesson.summary!, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall)
            : Text(typeDescription, style: theme.textTheme.bodySmall),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (lesson.lessonType == LessonType.video && lesson.duration != null && lesson.duration!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(lesson.duration!, style: theme.textTheme.bodySmall),
              ),
            if (showDownloadButton && hasDownloadUrl)
              _buildDownloadButton(context, lesson, lessonProv),
            deleteButton,
          ],
        ),
        onTap: () async => await _playOrLaunchContent(context, lesson),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, List<Lesson> lessons, LessonProvider lessonProv, LessonType filterType, String noContentMessage, IconData emptyIcon, {bool isNotesTab = false}) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final filteredLessons = isNotesTab
        ? lessons.where((l) => l.lessonType == LessonType.text || l.lessonType == LessonType.document).toList()
        : lessons.where((l) => l.lessonType == filterType).toList();
    final bool isLoadingInitial = lessonProv.isLoadingForSection(widget.section.id);
    final String? errorInitial = lessonProv.errorForSection(widget.section.id);

    if (isLoadingInitial && lessons.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: isDarkMode ? AppColors.primaryDark : AppColors.primaryLight));
    }

    if (errorInitial != null && lessons.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: AppColors.error, size: 50),
              const SizedBox(height: 16),
              Text(
                l10n.failedToLoadLessonsError(errorInitial),
                textAlign: TextAlign.center,
                style: TextStyle(color: (isDarkMode ? AppColors.onSurfaceDark : AppColors.iconLight).withOpacity(0.7)),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text(l10n.refresh),
                onPressed: isLoadingInitial ? null : _refreshLessons,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? AppColors.primaryDark : AppColors.primaryLight,
                  foregroundColor: isDarkMode ? AppColors.onPrimaryDark : AppColors.onPrimaryLight,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (filteredLessons.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(emptyIcon, size: 60, color: (isDarkMode ? AppColors.iconDark : AppColors.iconLight).withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                noContentMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(color: (isDarkMode ? AppColors.onSurfaceDark : AppColors.onSurfaceLight).withOpacity(0.7)),
              ),
               if ((lessons.isNotEmpty || errorInitial != null) && !isLoadingInitial)
                 const SizedBox(height: 20),
                 if ((lessons.isNotEmpty || errorInitial != null) && !isLoadingInitial)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.refresh),
                    onPressed: isLoadingInitial ? null : _refreshLessons,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? AppColors.primaryDark : AppColors.primaryLight,
                      foregroundColor: isDarkMode ? AppColors.onPrimaryDark : AppColors.onPrimaryLight,
                    ),
                  ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: filteredLessons.length,
      itemBuilder: (ctx, index) => _buildLessonItem(context, filteredLessons[index], lessonProv),
    );
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
          title: Text(widget.section.title, overflow: TextOverflow.ellipsis),
          backgroundColor: dynamicAppBarBackground,
           titleSpacing: 0,
        ),
        body: Center(
          child: CircularProgressIndicator(color: dynamicPrimaryColor)),
      );
    }

    if (error != null && lessons.isEmpty && !isLoading) {
       return Scaffold(
        backgroundColor: dynamicScaffoldBackground,
        appBar: AppBar(
          title: Text(widget.section.title, overflow: TextOverflow.ellipsis),
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
          title: Text(widget.section.title, overflow: TextOverflow.ellipsis),
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
        title: Text(widget.section.title, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18)),
        backgroundColor: dynamicAppBarBackground,
        titleSpacing: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: dynamicPrimaryColor,
          unselectedLabelColor: dynamicOnSurfaceColor.withOpacity(0.6),
          indicatorColor: dynamicPrimaryColor,
          tabs: [
            Tab(text: l10n.videoItemType),
            Tab(text: l10n.notesItemType),
            Tab(text: l10n.examsItemType),
          ],
        ),
      ),
     body: TabBarView(
      controller: _tabController,
      children: [
        RefreshIndicator(
          onRefresh: _refreshLessons,
          child: _buildTabContent(
            context,
            lessons,
            lessonProvider,
            LessonType.video,
            l10n.noVideosAvailable,
            Icons.video_library_outlined,
          ),
        ),
        RefreshIndicator(
          onRefresh: _refreshLessons,
          child: _buildTabContent(
            context,
            lessons,
            lessonProvider,
            LessonType.text,
            l10n.noNotesAvailable,
            Icons.notes_outlined,
            isNotesTab: true,
          ),
        ),
        RefreshIndicator(
          onRefresh: _refreshLessons,
          child: _buildTabContent(
            context,
            lessons,
            lessonProvider,
            LessonType.quiz,
            l10n.noExamsAvailable,
            Icons.quiz_outlined,
          ),
        ),
      ],
    ),
    );
  }
}