import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';
import 'package:mgw_tutorial/l10n/app_localizations.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;


// Corrected imports using package: syntax assuming standard lib structure
import 'package:mgw_tutorial/models/lesson.dart'; // Assuming Lesson and LessonType are here
import 'package:mgw_tutorial/models/section.dart'; // Assuming Section is here
import 'package:mgw_tutorial/provider/lesson_provider.dart'; // Import the updated provider
import 'package:mgw_tutorial/utils/download_status.dart'; // Import the DownloadStatus enum


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
      // Fetch lessons when the screen is first built
      // Use section.id as int as per LessonProvider
      Provider.of<LessonProvider>(context, listen: false)
          .fetchLessonsForSection(widget.section.id, forceRefresh: true);
    });
     print("LessonListScreen init for section: ${widget.section.title} (ID: ${widget.section.id})");
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
     print("LessonListScreen dispose for section: ${widget.section.title}");
  }

  Future<void> _refreshLessons() async {
    // Fetch lessons, which also triggers download status check within the provider
    // Use section.id as int
    await Provider.of<LessonProvider>(context, listen: false)
        .fetchLessonsForSection(widget.section.id, forceRefresh: true);
  }

  // Handles playing content (local file or external URL)
  Future<void> _playOrLaunchContent(BuildContext context, Lesson lesson) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    // Use listen: false when just calling methods
    final lessonProvider = Provider.of<LessonProvider>(context, listen: false);

    if (lesson.lessonType == LessonType.video && lesson.videoUrl != null) {
      // Get the video ID consistently
      final String? videoId = yt.VideoId.parseVideoId(lesson.videoUrl!)?.value; // Get the string value

      if (videoId != null) {
        // Get the current download status from the provider's ValueNotifier
        // We need to *read* the current value synchronously here
        final status = lessonProvider.getDownloadStatusNotifier(videoId).value;

        if (status == DownloadStatus.downloaded) {
          // File is downloaded, try to open it
          final filePath = await lessonProvider.getDownloadedFilePath(lesson);
          if (filePath != null && filePath.isNotEmpty) {
            print("Attempting to open downloaded file: $filePath for video ID $videoId");

            // Check if it was downloaded as video-only (based on provider's info)
            // Await this async call
            bool wasVideoOnly = await lessonProvider.isVideoDownloadedAsVideoOnly(lesson);
            if (wasVideoOnly && mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.appTitle.contains("መጂወ") ? "ይህ ቪዲዮ ድምፅ ላይኖረው ይችላል።" : "This video may have no audio (downloaded as video-only)."),
                  backgroundColor: theme.colorScheme.secondaryContainer.withOpacity(0.9),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 5),
                ),
              );
            }

            // Use open_filex to open the file
            final result = await OpenFilex.open(filePath);
            print("OpenFile result for $filePath: ${result.type}, ${result.message}");

            if (result.type != ResultType.done && mounted) {
               // Show error if opening failed
               ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text("${l10n.appTitle.contains("መጂወ") ? "ፋይሉን መክፈት አልተቻለም፡ " : "Could not open file: "}${result.message}"),
                    backgroundColor: theme.colorScheme.errorContainer,
                    behavior: SnackBarBehavior.floating,
                ),
              );
            }
            return; // Stop here if we successfully opened the local file or showed an error trying

          } else {
             // Fallback or error if status was downloaded but file path is null/empty
             print("Download status was downloaded ($videoId), but file path not found/invalid.");
             if(mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(l10n.appTitle.contains("መጂወ") ? "የወረደውን ፋይል ማግኘት አልተቻለም።" : "Could not find the downloaded file."),
                        backgroundColor: theme.colorScheme.errorContainer,
                        behavior: SnackBarBehavior.floating,
                    ),
                );
             }
             // Optionally, reset the download status in the provider if file is missing unexpectedly
             // lessonProvider.getDownloadStatusNotifier(videoId).value = DownloadStatus.notDownloaded;
             // Proceed to launching URL as a fallback? Depends on desired UX. Let's try launching URL.
          }
        } else if (status == DownloadStatus.downloading) {
             // User tapped while downloading, inform them
             if(mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(l10n.appTitle.contains("መጂወ") ? "ቪዲዮው እየወረደ ነው። እባክዎ ይጠብቁ።" : "Video is currently downloading. Please wait."),
                        backgroundColor: theme.colorScheme.secondaryContainer,
                        behavior: SnackBarBehavior.floating,
                    ),
                );
             }
             return; // Don't launch URL while downloading
         } else if (status == DownloadStatus.failed) {
             // User tapped while download failed, inform them or offer retry?
              if(mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(l10n.appTitle.contains("መጂወ") ? "የቪዲዮ ውርደት አልተሳካም። ዳግም ይሞክሩ።" : "Video download failed. Tap download button to retry."),
                        backgroundColor: theme.colorScheme.errorContainer,
                        behavior: SnackBarBehavior.floating,
                    ),
                );
             }
             // You could potentially attempt to launch the URL here as a fallback
             // or do nothing and let the user tap the retry icon. Let's not launch URL here.
             return;
         }
      }
       // If not downloaded, not downloading, not failed, or file not found after status check, launch URL
       // This covers NotDownloaded, Cancelled, and cases where videoId is null.
       if (lesson.videoUrl != null) {
            _launchUrl(context, lesson.videoUrl, lesson.title);
       } else {
           if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                       content: Text(l10n.itemNotAvailable(lesson.title)), // Use itemNotAvailable for missing URL
                       backgroundColor: theme.colorScheme.secondaryContainer,
                       behavior: SnackBarBehavior.floating,
                   ),
               );
           }
       }


    } else if (lesson.lessonType == LessonType.document && lesson.attachmentUrl != null) {
      _launchUrl(context, lesson.attachmentUrl, lesson.title);
    } else if (lesson.lessonType == LessonType.quiz) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Quiz: ${lesson.title} (Not implemented)"),
                backgroundColor: theme.colorScheme.secondaryContainer,
                behavior: SnackBarBehavior.floating,
            )
        );
      }
    } else if (lesson.lessonType == LessonType.text && lesson.summary != null && lesson.summary!.isNotEmpty){
       if (mounted) {
        showDialog(
            context: context,
            builder: (dCtx) => AlertDialog(
                backgroundColor: theme.dialogBackgroundColor,
                title: Text(lesson.title, style: theme.textTheme.titleLarge),
                content: SingleChildScrollView(child: Text(lesson.summary ?? l10n.noTextContent, style: theme.textTheme.bodyLarge)), // Use l10n for "No text content."
                actions: [TextButton(child: Text(l10n.closeButtonText, style: TextStyle(color: theme.colorScheme.primary)), onPressed: ()=>Navigator.of(dCtx).pop())], // Use l10n for "Close"
        ));
       }
    }
    else {
      // Handle cases like video lesson with null videoUrl, or other types with null URLs
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(l10n.noLaunchableContent(lesson.title)),
                backgroundColor: theme.colorScheme.secondaryContainer,
                behavior: SnackBarBehavior.floating,
            )
        );
      }
    }
  }

  Future<void> _launchUrl(BuildContext context, String? urlString, String itemName) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    if (urlString == null || urlString.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l10n.itemNotAvailable(itemName)),
              backgroundColor: theme.colorScheme.secondaryContainer,
              behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final Uri uri = Uri.parse(urlString);
    try {
       if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
                 content: Text(l10n.couldNotLaunchItem(urlString)),
                 backgroundColor: theme.colorScheme.errorContainer,
                 behavior: SnackBarBehavior.floating,
             ),
           );
         }
       }
    } catch (e) {
       // Handle potential exceptions during launchUrl (e.g., malformed URL not caught by Uri.parse)
        print("Error launching URL $urlString: $e");
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
                 content: Text("${l10n.couldNotLaunchItem(urlString)}: ${e.toString()}"),
                 backgroundColor: theme.colorScheme.errorContainer,
                 behavior: SnackBarBehavior.floating,
             ),
           );
         }
    }
  }

  // Builds the download button/indicator based on download status
  Widget _buildDownloadButton(BuildContext context, Lesson lesson, LessonProvider lessonProv) {
    final theme = Theme.of(context);
    // Only show download button for video lessons with a valid URL
    if (lesson.lessonType != LessonType.video || lesson.videoUrl == null) {
      return const SizedBox.shrink(); // Hide button for non-video lessons
    }

    // Get the video ID string
    final String? videoId = yt.VideoId.parseVideoId(lesson.videoUrl!)?.value;

    if (videoId == null) {
       // If video ID can't be parsed, show a broken link icon
       return SizedBox(
         width: 40, height: 40,
         child: Center( // Center the icon
           child: Icon(
               Icons.link_off,
               color: theme.colorScheme.error.withOpacity(0.7),
               size: 24 // Match other icon sizes
           ),
         ),
       );
    }

    // Use ValueListenableBuilder to react to status changes for this specific video ID
    return SizedBox( // Wrap with SizedBox to maintain consistent size
       width: 40, height: 40,
       child: ValueListenableBuilder<DownloadStatus>(
         valueListenable: lessonProv.getDownloadStatusNotifier(videoId),
         builder: (context, status, child) {
           switch (status) {
             case DownloadStatus.notDownloaded:
             case DownloadStatus.cancelled: // Treat cancelled like not downloaded for retry
               return IconButton(
                 icon: Icon(Icons.download_for_offline_outlined, color: theme.colorScheme.secondary),
                 tooltip: "Download Video",
                 iconSize: 24,
                 padding: EdgeInsets.zero,
                 onPressed: () {
                     print("Download button pressed for ID: $videoId");
                     lessonProv.startDownload(lesson); // Start download
                 },
               );
             case DownloadStatus.downloading:
               // Show progress while downloading
                return ValueListenableBuilder<double>(
                   valueListenable: lessonProv.getDownloadProgressNotifier(videoId),
                   builder: (context, progress, _) {
                      // Display progress percentage only if progress > 0
                      final progressText = progress > 0 && progress < 1 ? "${(progress * 100).toInt()}%" : "";
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox( // Wrap CircularProgressIndicator in a sized box for consistent size
                               width: 28, // Adjust size as needed
                               height: 28,
                              child: CircularProgressIndicator(
                                value: progress > 0 ? progress : null, // Use null for indeterminate when 0
                                strokeWidth: 3.0,
                                backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
                                color: theme.colorScheme.primary,
                              ),
                          ),
                          if (progressText.isNotEmpty)
                            Text(
                              progressText,
                              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                            ),
                        ],
                      );
                   },
                 );
             case DownloadStatus.downloaded:
               // File is downloaded, tapping opens it. Long press deletes.
                return IconButton(
                  // Icon might change based on video-only status?
                  // Checking isVideoDownloadedAsVideoOnly here requires FutureBuilder,
                  // which complicates the button. Simpler to just use a downloaded icon
                  // and show the warning snackbar when the user *plays* it in _playOrLaunchContent.
                  icon: Icon(Icons.check_circle, color: theme.colorScheme.primary),
                  tooltip: "Downloaded. Tap to play.",
                  iconSize: 24,
                  padding: EdgeInsets.zero,
                  onPressed: () async {
                    print("Play button pressed for ID: $videoId");
                    // Tapping a downloaded item should play it
                    await _playOrLaunchContent(context, lesson);
                  },
                  // Add long press to delete
                  onLongPress: () {
                     print("Delete button long pressed for ID: $videoId");
                     lessonProv.deleteDownload(lesson, context); // Pass context
                  }
                );
             case DownloadStatus.failed:
                return IconButton(
                 icon: Icon(Icons.error_outline, color: theme.colorScheme.error),
                 tooltip: "Download Failed. Tap to retry.",
                 iconSize: 24,
                 padding: EdgeInsets.zero,
                 onPressed: () {
                      print("Retry button pressed for ID: $videoId");
                      lessonProv.startDownload(lesson); // Retry download
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
    IconData lessonIcon;
    Color iconColor;
    String typeDescription;

    switch (lesson.lessonType) {
      case LessonType.video:
        lessonIcon = Icons.play_circle_outline_rounded;
        iconColor = theme.colorScheme.error;
        typeDescription = l10n.videoItemType;
        break;
      case LessonType.document:
        lessonIcon = Icons.description_outlined;
        iconColor = theme.colorScheme.secondary;
        typeDescription = l10n.documentItemType;
        break;
      case LessonType.quiz:
        lessonIcon = Icons.quiz_outlined;
        iconColor = theme.colorScheme.tertiary;
        typeDescription = l10n.quizItemType;
        break;
      case LessonType.text:
        lessonIcon = Icons.notes_outlined;
        iconColor = theme.colorScheme.primary;
        typeDescription = l10n.textItemType;
        break;
      default: // Fallback for unknown types
        lessonIcon = Icons.extension_outlined;
        iconColor = theme.colorScheme.onSurface.withOpacity(0.5);
        typeDescription = l10n.unknownItemType;
    }

    // Get the video ID string for the delete button check
    final String? videoIdForDeleteCheck = (lesson.lessonType == LessonType.video && lesson.videoUrl != null)
        ? yt.VideoId.parseVideoId(lesson.videoUrl!)?.value
        : null;

    // Use ValueListenableBuilder for the delete icon's visibility
    Widget deleteButton = const SizedBox.shrink();
    if (videoIdForDeleteCheck != null) {
      deleteButton = ValueListenableBuilder<DownloadStatus>(
         valueListenable: lessonProv.getDownloadStatusNotifier(videoIdForDeleteCheck),
         builder: (context, status, child) {
           if (status == DownloadStatus.downloaded) {
              return IconButton(
                 icon: Icon(Icons.delete_outline, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                 tooltip: "Delete Downloaded File",
                 iconSize: 24,
                 padding: EdgeInsets.zero,
                  onPressed: () {
                     print("Delete button pressed for ID: $videoIdForDeleteCheck");
                     lessonProv.deleteDownload(lesson, context); // Pass context
                  }
               );
           }
           return const SizedBox.shrink(); // Hide delete button if not downloaded
         },
      );
    }


    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      child: ListTile(
        leading: Icon(lessonIcon, color: iconColor, size: 36),
        title: Text(lesson.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
        subtitle: lesson.summary != null && lesson.summary!.isNotEmpty
            ? Text(lesson.summary!, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall)
            : Text(typeDescription, style: theme.textTheme.bodySmall), // Show type if no summary
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Show duration only for video lessons, as per previous structure
             if (lesson.lessonType == LessonType.video && lesson.duration != null && lesson.duration!.isNotEmpty)
               Padding(
                 padding: const EdgeInsets.only(right: 8.0),
                 child: Text(lesson.duration!, style: theme.textTheme.bodySmall),
               ),
            // The download button handles its own state using ValueListenableBuilder
            _buildDownloadButton(context, lesson, lessonProv),
            // Use the delete button widget built with ValueListenableBuilder
            deleteButton,
          ],
        ),
        onTap: () async => await _playOrLaunchContent(context, lesson), // Ensure this is awaited
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, List<Lesson> lessons, LessonProvider lessonProv, LessonType filterType, String noContentMessage, IconData emptyIcon) {
    final theme = Theme.of(context);
    // Filter lessons based on the provided type
    final filteredLessons = lessons.where((l) => l.lessonType == filterType).toList();

    // Get overall loading/error state for the section
     final bool isLoadingInitial = lessonProv.isLoadingForSection(widget.section.id) && lessons.isEmpty;
     final String? errorInitial = lessonProv.errorForSection(widget.section.id);

     // If the entire section is loading or failed to load initially,
     // the main Builder in the Scaffold body will handle showing the loader/error.
     // In this case, hide the individual tab content.
     if (isLoadingInitial || (errorInitial != null && lessons.isEmpty)) {
          return const SizedBox.shrink();
     }


    if (filteredLessons.isEmpty) {
      // Show 'no content' message only if the main lessons list is *not* empty,
      // implying that the section loaded successfully but this specific tab has no content.
       if (lessons.isNotEmpty) {
           return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(emptyIcon, size: 60, color: theme.iconTheme.color?.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(noContentMessage, textAlign: TextAlign.center, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7))),
              ],
            )
          );
       } else {
          // If the main lessons list is empty and not loading/error (shouldn't happen often,
          // but as a fallback), just return an empty box. The main empty state handles it.
          return const SizedBox.shrink();
       }
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

    // Use Consumer or context.watch for the main lesson list and loading/error state
    // Use listen: false for methods that don't require rebuilding the whole screen.
     final lessonProvider = Provider.of<LessonProvider>(context); // Listen for changes to the main lesson list

    final List<Lesson> lessons = lessonProvider.lessonsForSection(widget.section.id);
    final bool isLoading = lessonProvider.isLoadingForSection(widget.section.id);
    final String? error = lessonProvider.errorForSection(widget.section.id);


    return Scaffold(
      appBar: AppBar(
        title: Text(widget.section.title, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: theme.tabBarTheme.labelColor ?? theme.colorScheme.primary,
          unselectedLabelColor: theme.tabBarTheme.unselectedLabelColor ?? theme.colorScheme.onSurface.withOpacity(0.6),
          indicatorColor: theme.tabBarTheme.indicatorColor ?? theme.colorScheme.primary,
          tabs: [
            Tab(text: l10n.videoItemType),
            Tab(text: l10n.textItemType),
            Tab(text: l10n.documentItemType),
            Tab(text: l10n.quizItemType),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshLessons,
        color: theme.colorScheme.primary,
        backgroundColor: theme.colorScheme.surface,
        child: Builder( // Use Builder to get a context below the Scaffold for ScaffoldMessenger
          builder: (context) {
            // Show loading or error state if the main list is empty
            if (isLoading && lessons.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (error != null && lessons.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: theme.colorScheme.error, size: 50),
                      const SizedBox(height: 16),
                      Text(
                        l10n.failedToLoadLessonsError(error),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.refresh),
                        onPressed: _refreshLessons,
                      )
                    ],
                  ),
                ),
              );
            }
            // Show empty state if no lessons were loaded and not currently loading
            if (lessons.isEmpty && !isLoading) {
                 return Center(
                     child: Padding(
                         padding: const EdgeInsets.all(20.0),
                         child: Column(
                             mainAxisAlignment: MainAxisAlignment.center,
                             children: [
                                 Icon(Icons.hourglass_empty_outlined, size: 60, color: theme.iconTheme.color?.withOpacity(0.5)),
                                 const SizedBox(height: 16),
                                 Text(
                                     l10n.noLessonsInChapter,
                                     textAlign: TextAlign.center,
                                     style: theme.textTheme.titleMedium,
                                 ),
                             ],
                         )
                     ),
                 );
             }

            // If lessons are loaded (even if some tabs are empty), show the TabBarView
            return TabBarView(
              controller: _tabController,
               // Pass lessonProvider to _buildTabContent using the one obtained via Provider.of(listen: true)
               // _buildTabContent doesn't call methods that modify the main list, only reads.
               // The ValueListenableBuilders inside _buildLessonItem get notifiers from this provider instance.
              children: [
                _buildTabContent(context, lessons, lessonProvider, LessonType.video, l10n.noVideosAvailable, Icons.video_library_outlined),
                _buildTabContent(context, lessons, lessonProvider, LessonType.text, l10n.noTextLessonsAvailable, Icons.notes_outlined),
                _buildTabContent(context, lessons, lessonProvider, LessonType.document, l10n.noDocumentsAvailable, Icons.description_outlined),
                _buildTabContent(context, lessons, lessonProvider, LessonType.quiz, l10n.noQuizzesAvailable, Icons.quiz_outlined),
              ],
            );
          }
        ),
      ),
    );
  }
}