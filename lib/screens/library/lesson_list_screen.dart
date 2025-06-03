import 'dart:io'; // Keep if needed elsewhere, otherwise remove
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
// Remove this import: import 'package:open_filex/open_filex.dart'; // REMOVE THIS IMPORT
import 'package:mgw_tutorial/l10n/app_localizations.dart';

import 'package:mgw_tutorial/models/lesson.dart';
import 'package:mgw_tutorial/models/section.dart';
import 'package:mgw_tutorial/provider/lesson_provider.dart';
import 'package:mgw_tutorial/utils/download_status.dart';
import 'package:mgw_tutorial/screens/video_player_screen.dart';
import 'package:mgw_tutorial/screens/pdf_reader_screen.dart';
import 'package:mgw_tutorial/screens/exam_viewer_screen.dart'; // IMPORT ExamViewerScreen
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
    _tabController = TabController(length: 3, vsync: this); // Reduced to 3 tabs

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LessonProvider>(context, listen: false)
          .fetchLessonsForSection(widget.section.id);
    });
    print("LessonListScreen init for section: ${widget.section.title} (ID: ${widget.section.id})");
  }

  @override
  void dispose() {
    _tabController.dispose();
    print("LessonListScreen dispose for section: ${widget.section.title}");
    super.dispose();
  }

  Future<void> _refreshLessons() async {
    await Provider.of<LessonProvider>(context, listen: false)
        .fetchLessonsForSection(widget.section.id, forceRefresh: true);
  }

  // Simplified _playOrLaunchContent - quizzes always go to ExamViewerScreen
  Future<void> _playOrLaunchContent(BuildContext context, Lesson lesson) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Handle download status for Video and Document to decide local vs online
    final String? downloadId = lessonProvider.getDownloadId(lesson);
    DownloadStatus downloadStatus = DownloadStatus.notDownloaded;
     String? localFilePath;
    if (downloadId != null) {
        // Get the latest status *before* checking file path
        downloadStatus = lessonProvider.getDownloadStatusNotifier(downloadId).value;
        if(downloadStatus == DownloadStatus.downloaded) {
            localFilePath = await lessonProvider.getDownloadedFilePath(lesson);
        }
         // If status is downloaded but file isn't found, reset status for fallback
         if (downloadStatus == DownloadStatus.downloaded && (localFilePath == null || localFilePath.isEmpty)) {
              print("Download status was downloaded ($downloadId), but file path found empty/invalid.");
               if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                     backgroundColor: AppColors.errorContainer, // Use common error color
                    content: Text(l10n.couldNotFindDownloadedFileError),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
              // Treat as not downloaded for fallback
              localFilePath = null;
              downloadStatus = DownloadStatus.notDownloaded; // Reset status for fallback logic
         }
    }


    // --- Launch Content Based on Type and Availability ---
    if (lesson.lessonType == LessonType.video && lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty) {
      final List<Lesson> allLessonsForSection = lessonProvider.lessonsForSection(widget.section.id);

      if (localFilePath != null && downloadStatus == DownloadStatus.downloaded) { // Ensure status is also downloaded
         // Play downloaded video
          if (mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => VideoPlayerScreen(
                    videoTitle: lesson.title,
                    videoPath: localFilePath!, // Use null assertion !
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
         // Stream online video
         if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => VideoPlayerScreen(
                  videoTitle: lesson.title,
                  videoPath: '', // Use originalUrl for streaming
                  originalVideoUrl: lesson.videoUrl,
                  lessons: allLessonsForSection,
                  isLocal: false,
                ),
              ),
            );
         }
      }
    } else if (lesson.lessonType == LessonType.document && lesson.attachmentUrl != null && lesson.attachmentUrl!.isNotEmpty) {
       if (localFilePath != null && downloadStatus == DownloadStatus.downloaded) { // Ensure status is also downloaded
          // Open downloaded document (assuming PdfReaderScreen can handle local paths)
           if (mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => PdfReaderScreen(
                    pdfUrl: localFilePath!, // Use null assertion !
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
          // Open online document (assuming PdfReaderScreen can handle URLs)
          if (mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => PdfReaderScreen(
                    pdfUrl: lesson.attachmentUrl!, // Pass online URL
                    title: lesson.title,
                    isLocal: false,
                  ),
                ),
              );
           }
       }
    } else if (lesson.lessonType == LessonType.quiz && lesson.htmlUrl != null && lesson.htmlUrl!.isNotEmpty) {
      // Always navigate to ExamViewerScreen for quizzes
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => ExamViewerScreen(
              url: lesson.htmlUrl!, // Pass the original URL (ExamViewer will figure out if it's downloaded)
              title: lesson.title,
            ),
          ),
        );
      }
    } else if (lesson.lessonType == LessonType.text && lesson.summary != null && lesson.summary!.isNotEmpty) {
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

  // This button is now only for Video and Document in the LessonListScreen
  Widget _buildDownloadButton(BuildContext context, Lesson lesson, LessonProvider lessonProv) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isVideo = lesson.lessonType == LessonType.video;
    final isDocument = lesson.lessonType == LessonType.document;
    // Quiz download button is now handled within ExamViewerScreen

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Only show button for supported downloadable types handled by THIS screen
    if (!isVideo && !isDocument) {
       return const SizedBox.shrink();
    }

    final String? downloadId = lessonProv.getDownloadId(lesson);

    if (downloadId == null) {
       print("Download button unavailable: Could not generate download ID for lesson: ${lesson.title}, Type: ${lesson.lessonType}");
        return SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Icon(
              Icons.cloud_off_outlined,
               color: (isDarkMode ? AppColors.iconDark : AppColors.iconLight).withOpacity(0.3),
              size: 24,
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
              return IconButton(
                 icon: Icon(Icons.download_for_offline_outlined, color: isDarkMode ? AppColors.secondaryDark : AppColors.secondaryLight),
                tooltip: isVideo ? l10n.downloadVideoTooltip : l10n.downloadDocumentTooltip,
                iconSize: 24,
                padding: EdgeInsets.zero,
                onPressed: () {
                  print("Download button pressed for ID: $downloadId");
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
                            print("Cancel download pressed for ID: $downloadId");
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
               } else { // Should not happen with the check above
                  downloadedIcon = Icons.check_circle_outline;
                  downloadedTooltip = l10n.fileDownloadedTooltip;
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
                  print("Play/Open button pressed for ID: $downloadId");
                  await _playOrLaunchContent(context, lesson); // Use the existing logic
                },
              );
            case DownloadStatus.failed:
              return IconButton(
                 icon: Icon(Icons.error_outline, color: AppColors.error),
                tooltip: l10n.downloadFailedTooltip,
                iconSize: 24,
                padding: EdgeInsets.zero,
                onPressed: () {
                  print("Retry button pressed for ID: $downloadId");
                  lessonProv.startDownload(lesson);
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
        iconColor = (isDarkMode ? AppColors.onSurfaceDark : AppColors.onSurfaceLight).withOpacity(0.5);
        typeDescription = l10n.unknownItemType;
    }

    // Get the download ID that MediaService uses, only for types handled by buttons here
    final String? downloadIdForStatus = (lesson.lessonType == LessonType.video || lesson.lessonType == LessonType.document)
        ? lessonProv.getDownloadId(lesson)
        : null;

    Widget deleteButton = const SizedBox.shrink();
    // Only show delete button logic if a valid download ID exists for a potentially downloadable type
    if (downloadIdForStatus != null && (lesson.lessonType == LessonType.video || lesson.lessonType == LessonType.document)) {
      deleteButton = SizedBox(
        width: 40,
        height: 40,
        child: ValueListenableBuilder<DownloadStatus>(
          valueListenable: lessonProv.getDownloadStatusNotifier(downloadIdForStatus),
          builder: (context, status, child) {
            // Show delete icon ONLY when downloaded
            if (status == DownloadStatus.downloaded) {
              return IconButton(
                icon: Icon(Icons.delete_outline, color: (isDarkMode ? AppColors.iconDark : AppColors.iconLight).withOpacity(0.6)),
                tooltip: l10n.deleteDownloadedFileTooltip,
                iconSize: 24,
                padding: EdgeInsets.zero,
                onPressed: () {
                  print("Delete button pressed for ID: $downloadIdForStatus");
                  lessonProv.deleteDownload(lesson, context);
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      );
    }


    // Determine if download button should be shown for this item in THIS list view
    // Only show download button for Video and Document in LessonListScreen
    final bool showDownloadButton = lesson.lessonType == LessonType.video ||
                                     lesson.lessonType == LessonType.document;


    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      color: isDarkMode ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: IconButton(
           icon: Icon(lessonIcon, color: iconColor, size: 36),
           // Leading icon is tappable ONLY for video to stream directly
           onPressed: lesson.lessonType == LessonType.video && lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty
            ? () {
                final allLessonsForSection = lessonProv.lessonsForSection(widget.section.id);
                // Launch video stream directly if leading icon is pressed
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => VideoPlayerScreen(
                      videoTitle: lesson.title,
                      videoPath: '',
                      originalVideoUrl: lesson.videoUrl!,
                      lessons: allLessonsForSection,
                      isLocal: false, // Always stream if leading icon pressed
                    ),
                  ),
                );
              }
            : null, // Disable button for non-video types
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
            // Show download button logic for Video/Document
            if (showDownloadButton)
              _buildDownloadButton(context, lesson, lessonProv),
            // Show delete button if applicable and downloaded for Video/Document
            deleteButton,
          ],
        ),
        // Tapping the list tile handles opening ALL content types (streamed, downloaded, or navigating to viewer)
        onTap: () async => await _playOrLaunchContent(context, lesson),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, List<Lesson> lessons, LessonProvider lessonProv, LessonType filterType, String noContentMessage, IconData emptyIcon, {bool isNotesTab = false}) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Notes tab includes Text and Document
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
                style: TextStyle(color: (isDarkMode ? AppColors.onSurfaceDark : AppColors.onSurfaceLight).withOpacity(0.7)),
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


    if (isLoading && lessons.isEmpty) {
      return Scaffold(
        backgroundColor: dynamicScaffoldBackground,
        appBar: AppBar(
          title: Text(widget.section.title, overflow: TextOverflow.ellipsis),
          backgroundColor: dynamicAppBarBackground,
        ),
        body: Center(
          child: CircularProgressIndicator(color: dynamicPrimaryColor)),
      );
    }

    if (error != null && lessons.isEmpty) {
      return Scaffold(
        backgroundColor: dynamicScaffoldBackground,
        appBar: AppBar(
          title: Text(widget.section.title, overflow: TextOverflow.ellipsis),
          backgroundColor: dynamicAppBarBackground,
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
        LessonType.text, // Use LessonType.text here, filter includes document in _buildTabContent
        l10n.noNotesAvailable,
        Icons.notes_outlined,
        isNotesTab: true, // Explicitly mark as Notes tab for combined filtering
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