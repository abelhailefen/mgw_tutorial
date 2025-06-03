import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:mgw_tutorial/models/lesson.dart';
import 'package:mgw_tutorial/models/section.dart';
import 'package:mgw_tutorial/provider/lesson_provider.dart';
import 'package:mgw_tutorial/utils/download_status.dart';
import 'package:mgw_tutorial/screens/video_player_screen.dart';
import 'package:mgw_tutorial/screens/pdf_reader_screen.dart';
import 'package:mgw_tutorial/constants/color.dart'; // Ensure this imports the corrected AppColors

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

  Future<void> _playOrLaunchContent(BuildContext context, Lesson lesson) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
     final isDarkMode = Theme.of(context).brightness == Brightness.dark; // Get current brightness

    if (lesson.lessonType == LessonType.video && lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty) {
      final String? downloadId = lessonProvider.getDownloadId(lesson);

      if (downloadId != null) {
        final statusNotifier = lessonProvider.getDownloadStatusNotifier(downloadId);
        final status = statusNotifier.value;

        if (status == DownloadStatus.downloaded) {
          final filePath = await lessonProvider.getDownloadedFilePath(lesson);
          if (filePath != null && filePath.isNotEmpty) {
            print("Attempting to open downloaded file using internal player: $filePath for video ID $downloadId");

            final List<Lesson> allLessonsForSection = lessonProvider.lessonsForSection(widget.section.id);

            if (mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => VideoPlayerScreen(
                    videoTitle: lesson.title,
                    videoPath: filePath,
                    originalVideoUrl: lesson.videoUrl,
                    lessons: allLessonsForSection,
                    isLocal: true,
                  ),
                ),
              );
            }
            return;
          } else {
            print("Download status was downloaded ($downloadId), but file path not found/invalid.");
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                   // Use common error color
                  backgroundColor: AppColors.errorContainer,
                  content: Text(l10n.couldNotFindDownloadedFileError),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            // Fallback to online streaming
            final allLessonsForSection = lessonProvider.lessonsForSection(widget.section.id);
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
        } else if (status == DownloadStatus.downloading) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                 // Use conditional color
                backgroundColor: isDarkMode ? AppColors.secondaryContainerDark : AppColors.secondaryContainerLight,
                content: Text(l10n.videoIsDownloadingMessage),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        } else {
          // For other statuses, stream online
          final allLessonsForSection = lessonProvider.lessonsForSection(widget.section.id);
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
      } else {
        // Stream online if no download
        final allLessonsForSection = lessonProvider.lessonsForSection(widget.section.id);
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
      final String? downloadId = lessonProvider.getDownloadId(lesson);
      if (downloadId != null) {
        final statusNotifier = lessonProvider.getDownloadStatusNotifier(downloadId);
        if (statusNotifier.value == DownloadStatus.downloaded) {
          final filePath = await lessonProvider.getDownloadedFilePath(lesson);
          if (filePath != null && filePath.isNotEmpty) {
            if (mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => PdfReaderScreen(
                    pdfUrl: filePath,
                    title: lesson.title,
                    isLocal: true,
                  ),
                ),
              );
            }
            return;
          } else {
            print("Download status was downloaded ($downloadId), but file path not found/invalid.");
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                   // Use common error color
                  backgroundColor: AppColors.errorContainer,
                  content: Text(l10n.couldNotFindDownloadedFileError),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        }
      }
      // Fallback to online PDF
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => PdfReaderScreen(
              pdfUrl: lesson.attachmentUrl!,
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
             // Use conditional color
            backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
            title: Text(lesson.title, style: theme.textTheme.titleLarge), // text theme should handle color
            content: SingleChildScrollView(child: Text(lesson.summary ?? l10n.noTextContent, style: theme.textTheme.bodyLarge)), // text theme should handle color
            actions: [
              TextButton(
                 // Use conditional color
                child: Text(l10n.closeButtonText, style: TextStyle(color: isDarkMode ? AppColors.primaryDark : AppColors.primaryLight)),
                onPressed: () => Navigator.of(dCtx).pop(),
              ),
            ],
          ),
        );
      }
    } else if (lesson.lessonType == LessonType.quiz) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
             // Use conditional color
            backgroundColor: isDarkMode ? AppColors.secondaryContainerDark : AppColors.secondaryContainerLight,
            content: Text("${l10n.quizItemType}: ${lesson.title} (${l10n.notImplementedMessage})"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
             // Use conditional color
            backgroundColor: isDarkMode ? AppColors.secondaryContainerDark : AppColors.secondaryContainerLight,
            content: Text(l10n.noLaunchableContent(lesson.title)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _launchUrl(BuildContext context, String? urlString, String itemName) async {
    final l10n = AppLocalizations.of(context)!;
     final isDarkMode = Theme.of(context).brightness == Brightness.dark; // Get current brightness

    if (urlString == null || urlString.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
             // Use conditional color
            backgroundColor: isDarkMode ? AppColors.secondaryContainerDark : AppColors.secondaryContainerLight,
            content: Text(l10n.itemNotAvailable(itemName)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final Uri uri = Uri.parse(urlString);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        print("Cannot launch URL $urlString externally, trying in-app.");
        if (!await launchUrl(uri, mode: LaunchMode.inAppWebView)) {
          print("Cannot launch URL $urlString with any method.");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                 // Use common error color
                backgroundColor: AppColors.errorContainer,
                content: Text(l10n.couldNotLaunchItem(urlString)),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          print("Launched URL $urlString in-app.");
        }
      } else {
        print("Launched URL $urlString externally.");
      }
    } catch (e) {
      print("Error launching URL $urlString: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
             // Use common error color
            backgroundColor: AppColors.errorContainer,
            content: Text("${l10n.couldNotLaunchItem(urlString)}: ${e.toString()}"),
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
  final isDarkMode = Theme.of(context).brightness == Brightness.dark; // Get current brightness
  print("Building download button for lesson: ${lesson.title}, Type: ${lesson.lessonType}, Video URL: ${lesson.videoUrl}, Attachment URL: ${lesson.attachmentUrl}");

  // Use the correct download ID based on the lesson type if available
  final String? downloadId = lessonProv.getDownloadId(lesson);

  if (downloadId == null) {
    // Only show the "unavailable" icon if it's a type that *should* have a download option
    if (isVideo || isDocument) {
      return SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: Icon(
            Icons.cloud_off_outlined,
             // Use conditional color
            color: (isDarkMode ? AppColors.iconDark : AppColors.iconLight).withOpacity(0.3),
            size: 24,
          ),
        ),
      );
    }
    print("No download button: Not a supported downloadable type or missing/invalid URL.");
    return const SizedBox.shrink(); // Don't show anything for non-downloadable types
  }

  print("Showing download button for ${isVideo ? 'video' : 'document'} ID: $downloadId");
  return SizedBox(
    width: 40,
    height: 40,
    child: ValueListenableBuilder<DownloadStatus>(
      valueListenable: lessonProv.getDownloadStatusNotifier(downloadId),
      builder: (context, status, child) {
        switch (status) {
          case DownloadStatus.notDownloaded:
          case DownloadStatus.cancelled:
            return IconButton(
               // Use conditional color
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
                final progressText = progress > 0 && progress < 1 ? "${(progress * 100).toInt()}%" : "";
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        value: progress > 0 ? progress : null,
                        strokeWidth: 3.0,
                        // Use conditional color for background
                        backgroundColor: (isDarkMode ? AppColors.onSurfaceDark : AppColors.onSurfaceLight).withOpacity(0.1),
                        // Use conditional color for progress
                        color: isDarkMode ? AppColors.primaryDark : AppColors.primaryLight,
                      ),
                    ),
                    if (progressText.isNotEmpty)
                      Text(
                        progressText,
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 10), // Text color should inherit from theme
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
                           // Use common error color
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          case DownloadStatus.downloaded:
            return IconButton(
              icon: Icon(
                // Check if it's a video to show play icon
                isVideo ? Icons.play_circle_outline_rounded : Icons.description,
                 // Use conditional color
                color: isDarkMode ? AppColors.primaryDark : AppColors.primaryLight // Or secondary(context), or icon(context)
              ),
              // Update tooltip for clarity
              tooltip: isVideo ? l10n.playDownloadedVideoTooltip : l10n.openDownloadedDocumentTooltip,
              iconSize: 24,
              padding: EdgeInsets.zero,
              onPressed: () async {
                print("Play/Open button pressed for ID: $downloadId");
                await _playOrLaunchContent(context, lesson);
              },
              onLongPress: () {
                print("Delete button long pressed for ID: $downloadId");
                lessonProv.deleteDownload(lesson, context);
              },
            );
          case DownloadStatus.failed:
            return IconButton(
               // Use common error color
              icon: Icon(Icons.error_outline, color: AppColors.error),
              tooltip: isVideo ? l10n.downloadFailedTooltip : l10n.downloadFailedTooltip, // Tooltips are the same for failed state
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark; // Get current brightness

    IconData lessonIcon;
    Color iconColor;
    String typeDescription;

    switch (lesson.lessonType) {
      case LessonType.video:
        lessonIcon = Icons.play_circle_outline_rounded;
        // Use common error color
        iconColor = AppColors.error;
        typeDescription = l10n.videoItemType;
        break;
      case LessonType.document:
        lessonIcon = Icons.description_outlined;
        // Use conditional color
        iconColor = isDarkMode ? AppColors.secondaryDark : AppColors.secondaryLight;
        typeDescription = l10n.documentItemType;
        break;
      case LessonType.quiz:
        lessonIcon = Icons.quiz_outlined;
        // Use conditional color
        iconColor = isDarkMode ? AppColors.secondaryDark : AppColors.secondaryLight;
        typeDescription = l10n.quizItemType;
        break;
      case LessonType.text:
        lessonIcon = Icons.notes_outlined;
        // Use conditional color
        iconColor = isDarkMode ? AppColors.primaryDark : AppColors.primaryLight;
        typeDescription = l10n.textItemType;
        break;
      default:
        lessonIcon = Icons.extension_outlined;
        // Use conditional color
        iconColor = (isDarkMode ? AppColors.onSurfaceDark : AppColors.onSurfaceLight).withOpacity(0.5);
        typeDescription = l10n.unknownItemType;
    }

    final String? downloadIdForStatus = (lesson.lessonType == LessonType.video || lesson.lessonType == LessonType.document)
        ? lessonProv.getDownloadId(lesson) ?? lesson.id.toString() // Fallback ID might be problematic if not managed by provider
        : null;

    Widget deleteButton = const SizedBox.shrink();
    if (downloadIdForStatus != null) {
      deleteButton = SizedBox(
        width: 40,
        height: 40,
        child: ValueListenableBuilder<DownloadStatus>(
          valueListenable: lessonProv.getDownloadStatusNotifier(downloadIdForStatus),
          builder: (context, status, child) {
            if (status == DownloadStatus.downloaded) {
              return IconButton(
                // Use conditional color
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

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
       // Use conditional color for card background
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
        // Text colors should ideally come from theme.textTheme which respects the surface color
        title: Text(lesson.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
        subtitle: lesson.summary != null && lesson.summary!.isNotEmpty
            ? Text(lesson.summary!, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall)
            : Text(typeDescription, style: theme.textTheme.bodySmall),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (lesson.lessonType == LessonType.video && lesson.duration != null && lesson.duration!.isNotEmpty)
               // Text colors should ideally come from theme.textTheme
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(lesson.duration!, style: theme.textTheme.bodySmall),
              ),
            if (lesson.lessonType == LessonType.video || lesson.lessonType == LessonType.document)
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark; // Get current brightness

    final filteredLessons = isNotesTab
        ? lessons.where((l) => l.lessonType == LessonType.text || l.lessonType == LessonType.document).toList()
        : lessons.where((l) => l.lessonType == filterType).toList();
    final bool isLoadingInitial = lessonProv.isLoadingForSection(widget.section.id);
    final String? errorInitial = lessonProv.errorForSection(widget.section.id);

    if (isLoadingInitial && lessons.isEmpty) {
      return Center(
         // Use conditional color
        child: CircularProgressIndicator(color: isDarkMode ? AppColors.primaryDark : AppColors.primaryLight));
    }

    if (errorInitial != null && lessons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             // Use common error color
            Icon(Icons.error_outline, color: AppColors.error, size: 50),
            const SizedBox(height: 16),
            Text(
              l10n.failedToLoadLessonsError(errorInitial),
              textAlign: TextAlign.center,
               // Use conditional color
              style: TextStyle(color: (isDarkMode ? AppColors.onSurfaceDark : AppColors.onSurfaceLight).withOpacity(0.7)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text(l10n.refresh),
              onPressed: isLoadingInitial ? null : _refreshLessons,
              style: ElevatedButton.styleFrom(
                 // Use conditional colors
                backgroundColor: isDarkMode ? AppColors.primaryDark : AppColors.primaryLight,
                foregroundColor: isDarkMode ? AppColors.onPrimaryDark : AppColors.onPrimaryLight,
              ),
            ),
          ],
        ),
      );
    }

    if (filteredLessons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             // Use conditional color
            Icon(emptyIcon, size: 60, color: (isDarkMode ? AppColors.iconDark : AppColors.iconLight).withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              noContentMessage,
              textAlign: TextAlign.center,
              // Use conditional color, applying to a theme style
              style: theme.textTheme.titleMedium?.copyWith(color: (isDarkMode ? AppColors.onSurfaceDark : AppColors.onSurfaceLight).withOpacity(0.7)),
            ),
          ],
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
     final isDarkMode = Theme.of(context).brightness == Brightness.dark; // Get current brightness

    // Use conditional background color for the main Scaffold and AppBar in various states
    final dynamicAppBarBackground = isDarkMode ? AppColors.appBarBackgroundDark : AppColors.appBarBackgroundLight;
    final dynamicScaffoldBackground = isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight;
    final dynamicPrimaryColor = isDarkMode ? AppColors.primaryDark : AppColors.primaryLight;
    final dynamicOnPrimaryColor = isDarkMode ? AppColors.onPrimaryDark : AppColors.onPrimaryLight;
    final dynamicOnSurfaceColor = isDarkMode ? AppColors.onSurfaceDark : AppColors.onSurfaceLight;


    if (isLoading && lessons.isEmpty) {
      return Scaffold(
         // Use conditional color
        backgroundColor: dynamicScaffoldBackground,
        appBar: AppBar(
          title: Text(widget.section.title, overflow: TextOverflow.ellipsis), // Text color inherits from AppBar theme
           // Use conditional color
          backgroundColor: dynamicAppBarBackground,
        ),
        body: Center(
           // Use conditional color
          child: CircularProgressIndicator(color: dynamicPrimaryColor)),
      );
    }

    if (error != null && lessons.isEmpty) {
      return Scaffold(
         // Use conditional color
        backgroundColor: dynamicScaffoldBackground,
        appBar: AppBar(
          title: Text(widget.section.title, overflow: TextOverflow.ellipsis), // Text color inherits from AppBar theme
           // Use conditional color
          backgroundColor: dynamicAppBarBackground,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 // Use common error color
                Icon(Icons.error_outline, color: AppColors.error, size: 50),
                const SizedBox(height: 16),
                Text(
                  l10n.failedToLoadLessonsError(error),
                  textAlign: TextAlign.center,
                  // Use conditional color
                  style: TextStyle(color: dynamicOnSurfaceColor.withOpacity(0.7)),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.refresh),
                  onPressed: isLoading ? null : _refreshLessons,
                  style: ElevatedButton.styleFrom(
                     // Use conditional colors
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
         // Use conditional color
        backgroundColor: dynamicScaffoldBackground,
        appBar: AppBar(
          title: Text(widget.section.title, overflow: TextOverflow.ellipsis), // Text color inherits from AppBar theme
           // Use conditional color
          backgroundColor: dynamicAppBarBackground,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 // Use conditional color for icon
                Icon(Icons.hourglass_empty_outlined, size: 60, color: (isDarkMode ? AppColors.iconDark : AppColors.iconLight).withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  l10n.noLessonsInChapter,
                  textAlign: TextAlign.center,
                   // Use conditional color for text, applying to a theme style
                  style: theme.textTheme.titleMedium?.copyWith(color: dynamicOnSurfaceColor),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.refresh),
                  onPressed: isLoading ? null : _refreshLessons,
                  style: ElevatedButton.styleFrom(
                     // Use conditional colors
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
       // Use conditional color for main Scaffold background
      backgroundColor: dynamicScaffoldBackground,
      appBar: AppBar(
        title: Text(widget.section.title, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18)), // Text color inherits from AppBar theme
        // Use conditional color for AppBar background
        backgroundColor: dynamicAppBarBackground,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          // Use conditional colors for TabBar
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
      body: RefreshIndicator(
        onRefresh: lessonProvider.isLoadingForSection(widget.section.id) ? () async {} : _refreshLessons,
        // Use conditional colors for RefreshIndicator
        color: dynamicPrimaryColor,
        backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight, // Use conditional surface color
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildTabContent(context, lessons, lessonProvider, LessonType.video, l10n.noVideosAvailable, Icons.video_library_outlined),
            _buildTabContent(context, lessons, lessonProvider, LessonType.text, l10n.noNotesAvailable, Icons.notes_outlined, isNotesTab: true),
            _buildTabContent(context, lessons, lessonProvider, LessonType.quiz, l10n.noExamsAvailable, Icons.quiz_outlined),
          ],
        ),
      ),
    );
  }
}