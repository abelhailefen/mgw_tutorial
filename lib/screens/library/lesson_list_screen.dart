// lib/screens/library/lesson_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/models/lesson.dart';
import 'package:mgw_tutorial/provider/lesson_provider.dart';
import 'package:mgw_tutorial/models/section.dart';
import 'package:mgw_tutorial/services/video_download_service.dart'; // For DownloadStatus
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:open_filex/open_filex.dart'; // To open downloaded file
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt; // For parseVideoId


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
          .fetchLessonsForSection(widget.section.id, forceRefresh: true); // forceRefresh on init
    });
    print("LessonListScreen for section: ${widget.section.title} (ID: ${widget.section.id})");
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

    if (lesson.lessonType == LessonType.video && lesson.videoUrl != null) {
      final videoId = yt.YoutubeExplode.parseVideoId(lesson.videoUrl!);
      if (videoId != null) {
        final statusNotifier = lessonProvider.getDownloadStatusNotifier(videoId);
        if (statusNotifier.value == DownloadStatus.downloaded) {
          final filePath = await lessonProvider.getDownloadedFilePath(lesson);
          if (filePath != null && filePath.isNotEmpty) {
            print("Attempting to open downloaded file: $filePath");
            final result = await OpenFilex.open(filePath);
            print("OpenFile result: ${result.message}");
            if (result.type != ResultType.done) {
               ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text("${l10n.appTitle.contains("መጂወ") ? "ፋይሉን መክፈት አልተቻለም፡ " : "Could not open file: "}${result.message}"),
                    backgroundColor: theme.colorScheme.errorContainer,
                    behavior: SnackBarBehavior.floating,
                ),
              );
            }
            return;
          }
        }
      }
      // If not downloaded or videoId is null, launch URL
      _launchUrl(context, lesson.videoUrl, lesson.title);
    } else if (lesson.lessonType == LessonType.document && lesson.attachmentUrl != null) {
      _launchUrl(context, lesson.attachmentUrl, lesson.title);
    } else if (lesson.lessonType == LessonType.quiz) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Quiz: ${lesson.title} (Not implemented)"),
              backgroundColor: theme.colorScheme.secondaryContainer,
              behavior: SnackBarBehavior.floating,
          )
      );
    } else if (lesson.lessonType == LessonType.text && lesson.summary != null){
      showDialog(
          context: context,
          builder: (dCtx) => AlertDialog(
              backgroundColor: theme.dialogBackgroundColor,
              title: Text(lesson.title, style: theme.textTheme.titleLarge),
              content: SingleChildScrollView(child: Text(lesson.summary ?? "No text content.", style: theme.textTheme.bodyLarge)),
              actions: [TextButton(child: Text("Close", style: TextStyle(color: theme.colorScheme.primary)), onPressed: ()=>Navigator.of(dCtx).pop())],
      ));
    }
    else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l10n.noLaunchableContent(lesson.title)),
              backgroundColor: theme.colorScheme.secondaryContainer,
              behavior: SnackBarBehavior.floating,
          )
      );
    }
  }

  Future<void> _launchUrl(BuildContext context, String? urlString, String itemName) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    if (urlString == null || urlString.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.itemNotAvailable(itemName)),
            backgroundColor: theme.colorScheme.secondaryContainer,
            behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final Uri uri = Uri.parse(urlString);
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
  }

  Widget _buildDownloadButton(BuildContext context, Lesson lesson, LessonProvider lessonProv) {
    final theme = Theme.of(context);
    if (lesson.lessonType != LessonType.video || lesson.videoUrl == null) {
      return const SizedBox.shrink(); // No download for non-videos
    }

    final videoId = yt.YoutubeExplode.parseVideoId(lesson.videoUrl!);
    if (videoId == null) return const SizedBox.shrink(); // Invalid YT URL

    return SizedBox(
      width: 40, height: 40, // Constrain size
      child: ValueListenableBuilder<DownloadStatus>(
        valueListenable: lessonProv.getDownloadStatusNotifier(videoId),
        builder: (context, status, child) {
          if (status == DownloadStatus.downloading) {
            return ValueListenableBuilder<double>(
              valueListenable: lessonProv.getDownloadProgressNotifier(videoId),
              builder: (context, progress, _) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress > 0 && progress < 1 ? progress : null, // Indeterminate if 0 or 1 initially
                      strokeWidth: 2.5,
                      backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
                    ),
                    // Text("${(progress * 100).toInt()}%", style: TextStyle(fontSize: 8))
                  ],
                );
              },
            );
          } else if (status == DownloadStatus.downloaded) {
            return IconButton(
              icon: Icon(Icons.check_circle, color: theme.colorScheme.primary /* Or Colors.green */),
              tooltip: "Downloaded", // TODO: Localize
              iconSize: 24,
              padding: EdgeInsets.zero,
              onPressed: () async { // Allow playing downloaded file
                 await _playOrLaunchContent(context, lesson);
              },
            );
          } else if (status == DownloadStatus.failed) {
             return IconButton(
              icon: Icon(Icons.error_outline, color: theme.colorScheme.error),
              tooltip: "Download Failed. Tap to retry.", // TODO: Localize
              iconSize: 24,
              padding: EdgeInsets.zero,
              onPressed: () => lessonProv.startDownload(lesson),
            );
          }
          // Default: Not Downloaded
          return IconButton(
            icon: Icon(Icons.download_for_offline_outlined, color: theme.colorScheme.secondary),
            tooltip: "Download Video", // TODO: Localize
            iconSize: 24,
            padding: EdgeInsets.zero,
            onPressed: () => lessonProv.startDownload(lesson),
          );
        },
      ),
    );
  }


  Widget _buildLessonItem(BuildContext context, Lesson lesson, LessonProvider lessonProv) {
    final theme = Theme.of(context);
    IconData lessonIcon;
    Color iconColor;
    String typeDescription;

    switch (lesson.lessonType) {
      case LessonType.video:
        lessonIcon = Icons.play_circle_outline_rounded;
        iconColor = theme.colorScheme.error;
        typeDescription = AppLocalizations.of(context)!.videoItemType;
        break;
      // ... other cases ...
      case LessonType.document:
        lessonIcon = Icons.description_outlined;
        iconColor = theme.colorScheme.secondary;
        typeDescription = AppLocalizations.of(context)!.documentItemType;
        break;
      case LessonType.quiz:
        lessonIcon = Icons.quiz_outlined;
        iconColor = theme.colorScheme.tertiary;
        typeDescription = AppLocalizations.of(context)!.quizItemType;
        break;
      case LessonType.text:
        lessonIcon = Icons.notes_outlined;
        iconColor = theme.colorScheme.primary;
        typeDescription = AppLocalizations.of(context)!.textItemType;
        break;
      default:
        lessonIcon = Icons.extension_outlined;
        iconColor = theme.colorScheme.onSurface.withOpacity(0.5);
        typeDescription = AppLocalizations.of(context)!.unknownItemType;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      child: ListTile(
        leading: Icon(lessonIcon, color: iconColor, size: 36),
        title: Text(lesson.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
        subtitle: lesson.summary != null && lesson.summary!.isNotEmpty
            ? Text(lesson.summary!, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall)
            : Text(typeDescription, style: theme.textTheme.bodySmall),
        trailing: Row( // Use Row for duration and download button
          mainAxisSize: MainAxisSize.min,
          children: [
            if (lesson.duration != null && lesson.duration!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(lesson.duration!, style: theme.textTheme.bodySmall),
              ),
            _buildDownloadButton(context, lesson, lessonProv), // Download button
          ],
        ),
        onTap: () => _playOrLaunchContent(context, lesson),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, List<Lesson> lessons, LessonProvider lessonProv, LessonType filterType, String noContentMessage, IconData emptyIcon) {
    final theme = Theme.of(context);
    final filteredLessons = lessons.where((l) => l.lessonType == filterType).toList();

    if (lessonProv.isLoadingForSection(widget.section.id) && filteredLessons.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (lessonProv.errorForSection(widget.section.id) != null && filteredLessons.isEmpty) {
       return Center(child: Text(lessonProv.errorForSection(widget.section.id)!));
    }

    if (filteredLessons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 60, color: theme.iconTheme.color?.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(noContentMessage, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7))),
          ],
        )
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
    // Listen to LessonProvider for UI updates
    final lessonProvider = Provider.of<LessonProvider>(context);
    final List<Lesson> lessons = lessonProvider.lessonsForSection(widget.section.id);
    // isLoading and error are now also from the provider for this specific section
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
            Tab(text: l10n.textItemType), // Assuming Notes means Text lessons
            Tab(text: l10n.documentItemType),
            Tab(text: l10n.quizItemType),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshLessons,
        color: theme.colorScheme.primary,
        backgroundColor: theme.colorScheme.surface,
        child: Builder( // Use Builder to ensure context for ScaffoldMessenger is correct
          builder: (context) {
            // Overall loading/error for the section's lessons
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
                        l10n.failedToLoadLessonsError(error), // Use localized error
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


            return TabBarView(
              controller: _tabController,
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