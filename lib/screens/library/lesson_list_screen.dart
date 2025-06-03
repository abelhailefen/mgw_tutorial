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

  final String? downloadId = lessonProvider.getDownloadId(lesson);
  final bool hasDownloadSupport = downloadId != null; // Check if a downloadId could be generated

  // --- Handle Downloaded/Online Logic ---
  DownloadStatus downloadStatus = DownloadStatus.notDownloaded;
  if (hasDownloadSupport) {
     downloadStatus = lessonProvider.getDownloadStatusNotifier(downloadId).value;
  }

  String? localFilePath;
  if (hasDownloadSupport && downloadStatus == DownloadStatus.downloaded) {
      localFilePath = await lessonProvider.getDownloadedFilePath(lesson);
      if (localFilePath != null && localFilePath.isEmpty) {
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
      } else if (localFilePath != null) {
         print("Downloaded file path found: $localFilePath for ID $downloadId");
      }
  }


  // --- Launch Content Based on Type and Availability ---
  if (lesson.lessonType == LessonType.video && lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty) {
     final List<Lesson> allLessonsForSection = lessonProvider.lessonsForSection(widget.section.id);
     if (localFilePath != null) {
         // Play downloaded video
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
               backgroundColor: isDarkMode ? AppColors.secondaryContainerDark : AppColors.secondaryContainerLight, // Use conditional color
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
     if (localFilePath != null) {
        // Open downloaded document (assuming PdfReaderScreen can handle local paths)
         if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => PdfReaderScreen(
                  pdfUrl: localFilePath!, // Pass local path
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
                backgroundColor: isDarkMode ? AppColors.secondaryContainerDark : AppColors.secondaryContainerLight, // Use conditional color
               content: Text(l10n.documentIsDownloadingMessage), // Need to add this l10n key
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
     if (localFilePath != null) {
         // Open downloaded HTML quiz file
         print("Attempting to open downloaded HTML file: $localFilePath for quiz ID $downloadId");
         final result = await OpenFilex.open(localFilePath!);
          print("OpenFilex result: ${result.type}, message: ${result.message}");
         if (result.type != ResultType.done) {
             if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                     backgroundColor: AppColors.errorContainer, // Use common error color
                    content: Text("${l10n.couldNotOpenDownloadedFileError}: ${result.message}"), // Need to add this l10n key
                    behavior: SnackBarBehavior.floating,
                  ),
                );
             }
         }
     } else if (downloadStatus == DownloadStatus.downloading) {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
                backgroundColor: isDarkMode ? AppColors.secondaryContainerDark : AppColors.secondaryContainerLight, // Use conditional color
               content: Text(l10n.quizIsDownloadingMessage), // Need to add this l10n key
               behavior: SnackBarBehavior.floating,
             ),
           );
         }
     }
     else {
        // Open online HTML quiz in browser/WebView
         await _launchUrl(context, lesson.htmlUrl, lesson.title);
     }
  } else if (lesson.lessonType == LessonType.text && lesson.summary != null && lesson.summary!.isNotEmpty) {
    // Show text content in dialog (no download/launch needed)
    if (mounted) {
      showDialog(
        context: context,
        builder: (dCtx) => AlertDialog(
           backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight, // Use conditional color
          title: Text(lesson.title, style: theme.textTheme.titleLarge), // text theme should handle color
          content: SingleChildScrollView(child: Text(lesson.summary ?? l10n.noTextContent, style: theme.textTheme.bodyLarge)), // text theme should handle color
          actions: [
            TextButton(
               child: Text(l10n.closeButtonText, style: TextStyle(color: isDarkMode ? AppColors.primaryDark : AppColors.primaryLight)), // Use conditional color
              onPressed: () => Navigator.of(dCtx).pop(),
            ),
          ],
        ),
      );
    }
  }
  else {
    // Content not available or unknown type
     if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
           backgroundColor: isDarkMode ? AppColors.secondaryContainerDark : AppColors.secondaryContainerLight, // Use conditional color
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
  final isQuiz = lesson.lessonType == LessonType.quiz; // New check for Quiz
  final isDarkMode = Theme.of(context).brightness == Brightness.dark; // Get current brightness

  // Only show button for supported downloadable types
  if (!isVideo && !isDocument && !isQuiz) {
    print("No download button: Not a supported downloadable type (${lesson.lessonType})");
     return const SizedBox.shrink();
  }

  // Use the correct download ID based on the lesson type
  final String? downloadId = lessonProv.getDownloadId(lesson);

  if (downloadId == null) {
      // Show unavailable icon if it's a downloadable type but URL is missing/invalid for ID generation
      print("Download button unavailable: Could not generate download ID for lesson: ${lesson.title}, Type: ${lesson.lessonType}");
      return SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: Icon(
            Icons.cloud_off_outlined,
             color: (isDarkMode ? AppColors.iconDark : AppColors.iconLight).withOpacity(0.3), // Use conditional color
            size: 24,
          ),
        ),
      );
  }

  print("Showing download button for ${lesson.title} ($downloadId)");
  return SizedBox(
    width: 40, // Give it a fixed size to prevent layout shifts
    height: 40, // Give it a fixed size
    child: ValueListenableBuilder<DownloadStatus>(
      valueListenable: lessonProv.getDownloadStatusNotifier(downloadId),
      builder: (context, status, child) {
        switch (status) {
          case DownloadStatus.notDownloaded:
          case DownloadStatus.cancelled:
            return IconButton(
               icon: Icon(Icons.download_for_offline_outlined, color: isDarkMode ? AppColors.secondaryDark : AppColors.secondaryLight), // Use conditional color
              tooltip: isVideo ? l10n.downloadVideoTooltip : (isDocument ? l10n.downloadDocumentTooltip : l10n.downloadQuizTooltip), // Conditional tooltip
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
                // Ensure progress is between 0 and 1
                final safeProgress = progress.clamp(0.0, 1.0);
                final progressText = safeProgress > 0 && safeProgress < 1 ? "${(safeProgress * 100).toInt()}%" : "";
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        value: safeProgress > 0 ? safeProgress : null, // Show indeterminate if progress is 0
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
                          color: AppColors.error, // Use common error color
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
               downloadedIcon = Icons.description; // Or Icons.picture_as_pdf
               downloadedTooltip = l10n.openDownloadedDocumentTooltip;
             } else if (isQuiz) {
                downloadedIcon = Icons.launch; // Or Icons.web
                downloadedTooltip = l10n.openDownloadedQuizTooltip; // New tooltip
             } else {
                downloadedIcon = Icons.check_circle_outline; // Fallback icon
                downloadedTooltip = l10n.fileDownloadedTooltip; // New tooltip
             }

            return IconButton(
              icon: Icon(
                downloadedIcon,
                 color: isDarkMode ? AppColors.primaryDark : AppColors.primaryLight // Use conditional color
              ),
              tooltip: downloadedTooltip,
              iconSize: 24,
              padding: EdgeInsets.zero,
              onPressed: () async {
                print("Play/Open button pressed for ID: $downloadId");
                await _playOrLaunchContent(context, lesson);
              },
              // Long press to delete is handled by the separate deleteButton below
            );
          case DownloadStatus.failed:
            return IconButton(
               icon: Icon(Icons.error_outline, color: AppColors.error), // Use common error color
              tooltip: isVideo ? l10n.downloadFailedTooltip : (isDocument ? l10n.downloadFailedTooltip : l10n.downloadFailedTooltip), // Tooltips are the same for failed state
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
      iconColor = AppColors.error; // Consistent color for video icon
      typeDescription = l10n.videoItemType;
      break;
    case LessonType.document:
      lessonIcon = Icons.description_outlined;
      iconColor = isDarkMode ? AppColors.secondaryDark : AppColors.secondaryLight; // Use conditional color
      typeDescription = l10n.documentItemType;
      break;
    case LessonType.quiz:
      lessonIcon = Icons.quiz_outlined;
      iconColor = isDarkMode ? AppColors.secondaryDark : AppColors.secondaryLight; // Use conditional color
      typeDescription = l10n.quizItemType;
      break;
    case LessonType.text:
      lessonIcon = Icons.notes_outlined;
      iconColor = isDarkMode ? AppColors.primaryDark : AppColors.primaryLight; // Use conditional color
      typeDescription = l10n.textItemType;
      break;
    default:
      lessonIcon = Icons.extension_outlined;
      iconColor = (isDarkMode ? AppColors.onSurfaceDark : AppColors.onSurfaceLight).withOpacity(0.5); // Use conditional color
      typeDescription = l10n.unknownItemType;
  }

  // Get the download ID that MediaService *actually* uses
  final String? downloadIdForStatus = lessonProv.getDownloadId(lesson);

  Widget deleteButton = const SizedBox.shrink();
  // Only show delete button logic if a valid download ID exists for a potentially downloadable type
  if (downloadIdForStatus != null && (lesson.lessonType == LessonType.video || lesson.lessonType == LessonType.document || lesson.lessonType == LessonType.quiz)) {
    deleteButton = SizedBox(
      width: 40,
      height: 40,
      child: ValueListenableBuilder<DownloadStatus>(
        valueListenable: lessonProv.getDownloadStatusNotifier(downloadIdForStatus),
        builder: (context, status, child) {
          // Show delete icon ONLY when downloaded
          if (status == DownloadStatus.downloaded) {
            return IconButton(
              icon: Icon(Icons.delete_outline, color: (isDarkMode ? AppColors.iconDark : AppColors.iconLight).withOpacity(0.6)), // Use conditional color
              tooltip: l10n.deleteDownloadedFileTooltip, // Ensure this l10n key exists
              iconSize: 24,
              padding: EdgeInsets.zero,
              onPressed: () {
                print("Delete button pressed for ID: $downloadIdForStatus");
                lessonProv.deleteDownload(lesson, context);
              },
            );
          }
          // Hide delete button for other statuses
          return const SizedBox.shrink();
        },
      ),
    );
  }


  // Determine if download button should be shown for this item
  final bool showDownloadButton = lesson.lessonType == LessonType.video ||
                                   lesson.lessonType == LessonType.document ||
                                   lesson.lessonType == LessonType.quiz;


  return Card(
    margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
    elevation: 2.0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
     color: isDarkMode ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight, // Use conditional color for card background
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      leading: IconButton(
        // Only make the leading icon tappable for video to avoid double taps/confusion
         icon: Icon(lessonIcon, color: iconColor, size: 36),
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
          // Show download button logic if applicable
          if (showDownloadButton)
            _buildDownloadButton(context, lesson, lessonProv),
          // Show delete button if applicable and downloaded
          deleteButton,
        ],
      ),
      // Tapping the list tile handles opening ALL content types (streamed or downloaded)
      onTap: () async => await _playOrLaunchContent(context, lesson),
    ),
  );
}

Widget _buildTabContent(BuildContext context, List<Lesson> lessons, LessonProvider lessonProv, LessonType filterType, String noContentMessage, IconData emptyIcon, {bool isNotesTab = false}) {
  final theme = Theme.of(context);
  final l10n = AppLocalizations.of(context)!;
  final isDarkMode = Theme.of(context).brightness == Brightness.dark; // Get current brightness

  final filteredLessons = isNotesTab
      ? lessons.where((l) => l.lessonType == LessonType.text || l.lessonType == LessonType.document).toList() // Include LessonType.document for Notes tab
      : lessons.where((l) => l.lessonType == filterType).toList();
  final bool isLoadingInitial = lessonProv.isLoadingForSection(widget.section.id);
  final String? errorInitial = lessonProv.errorForSection(widget.section.id);

  if (isLoadingInitial && lessons.isEmpty) {
    return Center(
       child: CircularProgressIndicator(color: isDarkMode ? AppColors.primaryDark : AppColors.primaryLight)); // Use conditional color
  }

  if (errorInitial != null && lessons.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
           Icon(Icons.error_outline, color: AppColors.error, size: 50), // Use common error color
          const SizedBox(height: 16),
          Text(
            l10n.failedToLoadLessonsError(errorInitial),
            textAlign: TextAlign.center,
             style: TextStyle(color: (isDarkMode ? AppColors.onSurfaceDark : AppColors.onSurfaceLight).withOpacity(0.7)), // Use conditional color
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: Text(l10n.refresh),
            onPressed: isLoadingInitial ? null : _refreshLessons,
            style: ElevatedButton.styleFrom(
               backgroundColor: isDarkMode ? AppColors.primaryDark : AppColors.primaryLight, // Use conditional colors
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
           Icon(emptyIcon, size: 60, color: (isDarkMode ? AppColors.iconDark : AppColors.iconLight).withOpacity(0.5)), // Use conditional color
          const SizedBox(height: 16),
          Text(
            noContentMessage,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(color: (isDarkMode ? AppColors.onSurfaceDark : AppColors.onSurfaceLight).withOpacity(0.7)), // Use conditional color, applying to a theme style
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
    labelColor: dynamicPrimaryColor, // Use conditional colors
    unselectedLabelColor: dynamicOnSurfaceColor.withOpacity(0.6),
    indicatorColor: dynamicPrimaryColor,
    tabs: [
      Tab(text: l10n.videoItemType),
      Tab(text: l10n.notesItemType), // Use l10n key
      Tab(text: l10n.examsItemType), // Use l10n key
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