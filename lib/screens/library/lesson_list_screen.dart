// lib/screens/library/lesson_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // Keep this import
import 'package:open_filex/open_filex.dart'; // Keep this import
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Assuming this import is correct
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt; // Alias for parseVideoId


// Corrected imports using package: syntax assuming standard lib structure
import 'package:mgw_tutorial/models/lesson.dart'; // Import Lesson and LessonType
import 'package:mgw_tutorial/models/section.dart'; // Import Section
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
          .fetchLessonsForSection(widget.section.id, forceRefresh: true); // forceRefresh on init for fresh data
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

    // Handle Video Lessons
    if (lesson.lessonType == LessonType.video && lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty) {
      // Get the video ID string using the yt alias
      // Corrected: Call parseVideoId on yt.VideoId and use ?.value
      final String? videoId = yt.VideoId.parseVideoId(lesson.videoUrl!);

      if (videoId != null) {
        // Get the current download status from the provider's ValueNotifier
        // We need to *read* the current value synchronously here
        final status = lessonProvider.getDownloadStatusNotifier(videoId).value;

        if (status == DownloadStatus.downloaded) {
          // File is downloaded, try to open it
          final filePath = await lessonProvider.getDownloadedFilePath(lesson);
          if (filePath != null && filePath.isNotEmpty) {
            print("Attempting to open downloaded file: $filePath for video ID $videoId");

             // Removed the isVideoDownloadedAsVideoOnly check as the service doesn't support it.
             // If you implement video-only download and status tracking, you can add this back.
            // bool wasVideoOnly = await lessonProvider.isVideoDownloadedAsVideoOnly(lesson);
            // if (wasVideoOnly && mounted) {
            //    ScaffoldMessenger.of(context).showSnackBar(...); // Localize the warning
            // }

            // Use open_filex to open the file
            final result = await OpenFilex.open(filePath);
            print("OpenFile result for $filePath: ${result.type}, ${result.message}");

            if (result.type != ResultType.done && mounted) { // Check mounted before ScaffoldMessenger
               // Show error if opening failed
               ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text("${l10n.couldNotOpenFileError}${result.message}"), // Localize error message
                    backgroundColor: theme.colorScheme.errorContainer,
                    behavior: SnackBarBehavior.floating,
                ),
              );
            }
            return; // Stop here if we successfully opened the local file or showed an error trying

          } else {
             // Fallback or error if status was downloaded but file path is null/empty - should not happen often
             print("Download status was downloaded ($videoId), but file path not found/invalid.");
             if(mounted) { // Check mounted before ScaffoldMessenger
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(l10n.couldNotFindDownloadedFileError), // Localize error message
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
             if(mounted) { // Check mounted before ScaffoldMessenger
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(l10n.videoIsDownloadingMessage), // Localize
                        backgroundColor: theme.colorScheme.secondaryContainer,
                        behavior: SnackBarBehavior.floating,
                    ),
                );
             }
             return; // Don't launch URL while downloading
         } else if (status == DownloadStatus.failed) {
             // User tapped while download failed, inform them
              if(mounted) { // Check mounted before ScaffoldMessenger
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(l10n.videoDownloadFailedMessage), // Localize
                        backgroundColor: theme.colorScheme.errorContainer,
                        behavior: SnackBarBehavior.floating,
                    ),
                );
             }
             // User needs to tap the retry icon explicitly.
             return;
         } else if (status == DownloadStatus.cancelled) {
            // User tapped while cancelled, inform them
             if(mounted) { // Check mounted before ScaffoldMessenger
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(l10n.videoDownloadCancelledMessage), // Localize
                        backgroundColor: theme.colorScheme.secondaryContainer,
                        behavior: SnackBarBehavior.floating,
                    ),
                );
             }
             // User needs to tap the download icon explicitly.
             return;
         }
      }
       // If not downloaded, not downloading, not failed, not cancelled, file not found, or videoId is null/URL is empty
       // Fallback to launching the original URL externally.
       _launchUrl(context, lesson.videoUrl, lesson.title); // Use videoUrl for external launch

    }
    // Handle Document Lessons
    else if (lesson.lessonType == LessonType.document && lesson.attachmentUrl != null && lesson.attachmentUrl!.isNotEmpty) {
      // TODO: Implement download for documents? For now, just launch URL.
      _launchUrl(context, lesson.attachmentUrl, lesson.title); // Use attachmentUrl for documents
    }
    // Handle Quiz Lessons
    else if (lesson.lessonType == LessonType.quiz) {
      // TODO: Implement Quiz logic
      if (mounted) { // Check mounted before ScaffoldMessenger
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("${l10n.quizItemType}: ${lesson.title} (${l10n.notImplementedMessage})"), // Localize
                backgroundColor: theme.colorScheme.secondaryContainer,
                behavior: SnackBarBehavior.floating,
            )
        );
      }
    }
    // Handle Text Lessons
    else if (lesson.lessonType == LessonType.text && lesson.summary != null && lesson.summary!.isNotEmpty){ // Added check for empty summary
       if (mounted) { // Check mounted before showDialog
        showDialog(
            context: context,
            builder: (dCtx) => AlertDialog(
                backgroundColor: theme.dialogBackgroundColor, // Use theme color
                title: Text(lesson.title, style: theme.textTheme.titleLarge), // Use theme text style
                content: SingleChildScrollView(child: Text(lesson.summary ?? l10n.noTextContent, style: theme.textTheme.bodyLarge)), // Localize and theme text style
                actions: [TextButton(child: Text(l10n.closeButtonText, style: TextStyle(color: theme.colorScheme.primary)), onPressed: ()=>Navigator.of(dCtx).pop())], // Localize and theme color
        ));
       }
    }
    // Handle Lessons with no launchable content or missing data
    else {
      if (mounted) { // Check mounted before ScaffoldMessenger
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(l10n.noLaunchableContent(lesson.title)), // Localize
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
      if (mounted) { // Check mounted before ScaffoldMessenger
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l10n.itemNotAvailable(itemName)), // Localize
              backgroundColor: theme.colorScheme.secondaryContainer,
              behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final Uri uri = Uri.parse(urlString);
    try {
       // Check if the URL can be launched before attempting
       // canLaunchUrl is deprecated, use launchUrl with canLaunch mode
        if (!await launchUrl(uri, mode: LaunchMode.inAppWebView)) {
           // If in-app webview fails, try external application
           if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
              print("Cannot launch URL $urlString with any method.");
               if (mounted) { // Check mounted before ScaffoldMessenger
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                       content: Text(l10n.couldNotLaunchItem(urlString)), // Localize
                       backgroundColor: theme.colorScheme.errorContainer,
                       behavior: SnackBarBehavior.floating,
                   ),
                 );
               }
           } else {
                print("Launched URL $urlString externally.");
           }
       } else {
           print("Launched URL $urlString in-app.");
       }


    } catch (e) {
       // Handle potential exceptions during Uri.parse or launchUrl
        print("Error launching URL $urlString: $e");
         if (mounted) { // Check mounted before ScaffoldMessenger
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
                 content: Text("${l10n.couldNotLaunchItem(urlString)}: ${e.toString()}"), // Include error message, localize
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
    // Only show download button for video lessons with a valid non-empty YouTube URL
    if (lesson.lessonType != LessonType.video || lesson.videoUrl == null || lesson.videoUrl!.isEmpty) {
      return const SizedBox.shrink(); // Hide button for non-video or invalid video lessons
    }

     // Ensure the video provider is YouTube if you only support YouTube downloads
     if (lesson.videoProvider?.toLowerCase() != 'youtube') {
         // Maybe show a different icon for unsupported video types?
         return SizedBox(
            width: 40, height: 40,
            child: Center(
                 child: Icon(
                    Icons.videocam_off_outlined, // Or a 'not supported' icon
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    size: 24,
                 ),
            ),
         );
     }


    // Get the video ID string using the yt alias
    // Corrected: Call parseVideoId on yt.VideoId and use ?.value
    final String? videoId = yt.VideoId.parseVideoId(lesson.videoUrl!);

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
    // Wrap with SizedBox to maintain consistent size and alignment in the trailing row
    return SizedBox(
       width: 40, height: 40,
       child: ValueListenableBuilder<DownloadStatus>(
         valueListenable: lessonProv.getDownloadStatusNotifier(videoId),
         builder: (context, status, child) {
           switch (status) {
             case DownloadStatus.notDownloaded:
             case DownloadStatus.cancelled: // Treat cancelled like not downloaded for retry
               return IconButton(
                 icon: Icon(Icons.download_for_offline_outlined, color: theme.colorScheme.secondary),
                 tooltip: AppLocalizations.of(context)!.downloadVideoTooltip, // Localize
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
                      // Display progress percentage only if progress > 0 and < 1
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
                  tooltip: AppLocalizations.of(context)!.downloadedVideoTooltip, // Localize
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
                 tooltip: AppLocalizations.of(context)!.downloadFailedTooltip, // Localize
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
    final l10n = AppLocalizations.of(context)!; // Get localization instance
    IconData lessonIcon;
    Color iconColor;
    String typeDescription;

    // Determine icon, color, and type description based on lesson type
    switch (lesson.lessonType) {
      case LessonType.video:
        lessonIcon = Icons.play_circle_outline_rounded;
        iconColor = theme.colorScheme.error; // Common color for video
        typeDescription = l10n.videoItemType; // Localized description
        break;
      case LessonType.document:
        lessonIcon = Icons.description_outlined;
        iconColor = theme.colorScheme.secondary; // Common color for documents
        typeDescription = l10n.documentItemType; // Localized description
        break;
      case LessonType.quiz:
        lessonIcon = Icons.quiz_outlined;
        iconColor = theme.colorScheme.tertiary; // Common color for quizzes
        typeDescription = l10n.quizItemType; // Localized description
        break;
      case LessonType.text:
        lessonIcon = Icons.notes_outlined;
        iconColor = theme.colorScheme.primary; // Common color for text
        typeDescription = l10n.textItemType; // Localized description
        break;
      default: // Fallback for unknown types
        lessonIcon = Icons.extension_outlined;
        iconColor = theme.colorScheme.onSurface.withOpacity(0.5);
        typeDescription = l10n.unknownItemType; // Localized description
    }

    // Get the video ID string for the delete button check (only for video lessons)
    final String? videoIdForDeleteCheck = (lesson.lessonType == LessonType.video && lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty)
        // OLD (incorrect)
        // ? yt.VideoId.parseVideoId(lesson.videoUrl!)?.value
        // NEW (correct)
        ? yt.VideoId.parseVideoId(lesson.videoUrl!)
        : null;

    // Build the delete button widget wrapped in a SizedBox for layout consistency
    Widget deleteButton = const SizedBox.shrink();
    if (videoIdForDeleteCheck != null) {
      // Use ValueListenableBuilder for the delete icon's visibility, listening to the status
       deleteButton = SizedBox(
           width: 40, height: 40, // Keep size consistent with download button container
           child: ValueListenableBuilder<DownloadStatus>(
              valueListenable: lessonProv.getDownloadStatusNotifier(videoIdForDeleteCheck),
              builder: (context, status, child) {
                // Only show the delete button if the status is 'downloaded'
                if (status == DownloadStatus.downloaded) {
                   return IconButton(
                      icon: Icon(Icons.delete_outline, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      tooltip: l10n.deleteDownloadedFileTooltip, // Localize
                      iconSize: 24,
                      padding: EdgeInsets.zero,
                       onPressed: () {
                          print("Delete button pressed for ID: $videoIdForDeleteCheck");
                          // Call the provider method to handle deletion
                          lessonProv.deleteDownload(lesson, context); // Pass context for snackbar
                       }
                    );
                }
                return const SizedBox.shrink(); // Hide delete button if not downloaded
              },
           ),
       );
    }


    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      elevation: 2.0, // Add a little shadow
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)), // Rounded corners
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: Icon(lessonIcon, color: iconColor, size: 36),
        title: Text(lesson.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
        subtitle: lesson.summary != null && lesson.summary!.isNotEmpty
            ? Text(lesson.summary!, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall)
            : Text(typeDescription, style: theme.textTheme.bodySmall), // Show type if no summary
        trailing: Row( // Use Row for duration, download button, and delete button
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

  // Builds the content for each tab (Video, Text, Document, Quiz)
  Widget _buildTabContent(BuildContext context, List<Lesson> lessons, LessonProvider lessonProv, LessonType filterType, String noContentMessage, IconData emptyIcon) {
    final theme = Theme.of(context);
    // Filter lessons based on the provided LessonType
    final filteredLessons = lessons.where((l) => l.lessonType == filterType).toList();

    // Get overall loading/error state for the section from the provider
    // We check `lessons.isEmpty` to ensure we only show the full screen loader/error
    // if the *initial* fetch failed or is loading and there's no data yet.
     final bool isLoadingInitial = lessonProv.isLoadingForSection(widget.section.id) && lessons.isEmpty;
     final String? errorInitial = lessonProv.errorForSection(widget.section.id);

     // If the entire section is loading or failed to load initially,
     // the main Builder in the Scaffold body will handle showing the loader/error overlay.
     // In this case, the individual tab content should remain hidden.
     if (isLoadingInitial || (errorInitial != null && lessons.isEmpty)) {
          return const SizedBox.shrink();
     }

    // If the filtered list for this specific tab is empty (but the overall section loaded successfully)
    if (filteredLessons.isEmpty) {
      // Show the 'no content' message specific to this tab type.
      // We only show this if the overall lesson list (`lessons`) is *not* empty,
      // meaning the fetch succeeded, but this category has no items.
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
          // If the main lessons list is empty AND we are not in the initial loading/error state,
          // this is an unexpected scenario or the main empty state handler took over.
          // Return an empty box for safety.
          return const SizedBox.shrink();
       }
    }

    // If there are lessons in this tab, build the list view
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: filteredLessons.length,
      // Use the filtered lesson list and the lessonProvider instance
      itemBuilder: (ctx, index) => _buildLessonItem(context, filteredLessons[index], lessonProv),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get localization and theme instances
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Use Provider.of<LessonProvider>(context) to listen to changes in the provider.
    // This will cause the widget to rebuild when notifyListeners() is called in the provider.
    final lessonProvider = Provider.of<LessonProvider>(context);

    // Get the current state from the provider
    final List<Lesson> lessons = lessonProvider.lessonsForSection(widget.section.id);
    final bool isLoading = lessonProvider.isLoadingForSection(widget.section.id);
    final String? error = lessonProvider.errorForSection(widget.section.id);


    return Scaffold(
      appBar: AppBar(
        title: Text(widget.section.title, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18)), // Display section title
        bottom: TabBar( // TabBar for filtering lesson types
          controller: _tabController,
          isScrollable: true, // Allow scrolling if many tabs
          labelColor: theme.tabBarTheme.labelColor ?? theme.colorScheme.primary, // Themable tab colors
          unselectedLabelColor: theme.tabBarTheme.unselectedLabelColor ?? theme.colorScheme.onSurface.withOpacity(0.6),
          indicatorColor: theme.tabBarTheme.indicatorColor ?? theme.colorScheme.primary,
          tabs: [ // Define tabs using localized text
            Tab(text: l10n.videoItemType),
            Tab(text: l10n.textItemType), // Assuming Notes means Text lessons
            Tab(text: l10n.documentItemType),
            Tab(text: l10n.quizItemType),
          ],
        ),
      ),
      body: RefreshIndicator( // Pull-to-refresh functionality
        onRefresh: _refreshLessons, // Call provider to refresh lessons
        color: theme.colorScheme.primary, // Themable refresh indicator color
        backgroundColor: theme.colorScheme.surface, // Themable refresh indicator background
        child: Builder( // Use Builder to ensure a valid BuildContext for ScaffoldMessenger
          builder: (context) {
            // === Handle initial loading or error states ===
            // If currently loading AND the lessons list is empty (initial load or refresh failed)
            if (isLoading && lessons.isEmpty) {
              return const Center(child: CircularProgressIndicator()); // Show a loading spinner
            }
            // If there's an error AND the lessons list is empty (initial load failed)
            if (error != null && lessons.isEmpty) {
              return Center( // Show an error message with a retry button
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: theme.colorScheme.error, size: 50), // Error icon
                      const SizedBox(height: 16),
                      Text(
                        l10n.failedToLoadLessonsError(error), // Localized error message including the error details
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon( // Retry button
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.refresh), // Localized button text
                        onPressed: _refreshLessons, // Call refresh when pressed
                      )
                    ],
                  ),
                ),
              );
            }
            // If the lessons list is empty AND not currently loading (e.g., section genuinely has no lessons)
            if (lessons.isEmpty && !isLoading) {
                 return Center( // Show an empty state message
                     child: Padding(
                         padding: const EdgeInsets.all(20.0),
                         child: Column(
                             mainAxisAlignment: MainAxisAlignment.center,
                             children: [
                                 Icon(Icons.hourglass_empty_outlined, size: 60, color: theme.iconTheme.color?.withOpacity(0.5)), // Empty state icon
                                 const SizedBox(height: 16),
                                 Text(
                                     l10n.noLessonsInChapter, // Localized empty message
                                     textAlign: TextAlign.center,
                                     style: theme.textTheme.titleMedium,
                                 ),
                             ],
                         )
                     ),
                 );
             }

            // === If lessons are loaded (list is not empty) ===
            // Show the TabBarView containing the filtered lists for each type.
            // _buildTabContent will handle showing "no content" messages for individual tabs
            // if they are empty but the overall section is not.
            return TabBarView(
              controller: _tabController,
              children: [
                // Pass necessary data and the lessonProvider instance to each tab content builder
                _buildTabContent(context, lessons, lessonProvider, LessonType.video, l10n.noVideosAvailable, Icons.video_library_outlined), // Localized empty messages/icons
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