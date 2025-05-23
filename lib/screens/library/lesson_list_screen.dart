import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/models/lesson.dart';
import 'package:mgw_tutorial/provider/lesson_provider.dart';
import 'package:mgw_tutorial/models/section.dart';
import 'package:mgw_tutorial/services/video_download_service.dart'; // For DownloadStatus
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:open_filex/open_filex.dart'; // To open downloaded file
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt; // For VideoId

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
          .fetchLessonsForSection(widget.section.id, forceRefresh: true);
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
      final String? videoId = yt.VideoId.parseVideoId(lesson.videoUrl!);

      if (videoId != null) {
        final statusNotifier = lessonProvider.getDownloadStatusNotifier(videoId);
        if (statusNotifier.value == DownloadStatus.downloaded) {
          final filePath = await lessonProvider.getDownloadedFilePath(lesson); // Uses updated method
          if (filePath != null && filePath.isNotEmpty) {
            print("Attempting to open downloaded file: $filePath");

            // Check if it was a video-only download and inform user
            bool wasVideoOnly = lessonProvider.isVideoDownloadedAsVideoOnly(lesson);
            if (wasVideoOnly && mounted) { // Check mounted before showing SnackBar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.appTitle.contains("መጂወ") ? "ይህ ቪዲዮ ድምፅ ላይኖረው ይችላል።" : "This video may have no audio (downloaded as video-only)."),
                  backgroundColor: theme.colorScheme.secondaryContainer.withOpacity(0.9),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 5),
                ),
              );
            }

            final result = await OpenFilex.open(filePath);
            print("OpenFile result: ${result.message}");
            if (result.type != ResultType.done && mounted) { // Check mounted
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
      // If not downloaded or videoId is null, or filePath is null, launch URL
      _launchUrl(context, lesson.videoUrl, lesson.title);
    } else if (lesson.lessonType == LessonType.document && lesson.attachmentUrl != null) {
      _launchUrl(context, lesson.attachmentUrl, lesson.title);
    } else if (lesson.lessonType == LessonType.quiz) {
      if (mounted) { // Check mounted
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Quiz: ${lesson.title} (Not implemented)"),
                backgroundColor: theme.colorScheme.secondaryContainer,
                behavior: SnackBarBehavior.floating,
            )
        );
      }
    } else if (lesson.lessonType == LessonType.text && lesson.summary != null){
       if (mounted) { // Check mounted
        showDialog(
            context: context,
            builder: (dCtx) => AlertDialog(
                backgroundColor: theme.dialogBackgroundColor,
                title: Text(lesson.title, style: theme.textTheme.titleLarge),
                content: SingleChildScrollView(child: Text(lesson.summary ?? "No text content.", style: theme.textTheme.bodyLarge)),
                actions: [TextButton(child: Text("Close", style: TextStyle(color: theme.colorScheme.primary)), onPressed: ()=>Navigator.of(dCtx).pop())],
        ));
       }
    }
    else {
      if (mounted) { // Check mounted
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
      if (mounted) { // Check mounted
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
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) { // Check mounted
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
      return const SizedBox.shrink();
    }

    final String? videoId = yt.VideoId.parseVideoId(lesson.videoUrl!);

    if (videoId == null) return const SizedBox.shrink();

    return SizedBox(
      width: 40, height: 40,
      child: ValueListenableBuilder<DownloadStatus>(
        valueListenable: lessonProv.getDownloadStatusNotifier(videoId),
        builder: (context, status, child) {
          Widget iconWidget;
          String tooltipText = "";
          VoidCallback? onPressedAction = () => lessonProv.startDownload(lesson);

          if (status == DownloadStatus.downloading) {
            return ValueListenableBuilder<double>(
              valueListenable: lessonProv.getDownloadProgressNotifier(videoId),
              builder: (context, progress, _) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress > 0 && progress < 1 ? progress : null,
                      strokeWidth: 2.5,
                      backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
                    ),
                    // Optionally show percentage
                    // Text("${(progress * 100).toInt()}%", style: TextStyle(fontSize: 10))
                  ],
                );
              },
            );
          } else if (status == DownloadStatus.downloaded) {
            bool isVideoOnly = lessonProv.isVideoDownloadedAsVideoOnly(lesson);
            iconWidget = Icon(
              isVideoOnly ? Icons.videocam_off_outlined : Icons.check_circle, // Different icon for video-only
              color: theme.colorScheme.primary
            );
            tooltipText = isVideoOnly ? "Downloaded (Video Only)" : "Downloaded";
            onPressedAction = () async {
                 await _playOrLaunchContent(context, lesson);
            };
          } else if (status == DownloadStatus.failed) {
             iconWidget = Icon(Icons.error_outline, color: theme.colorScheme.error);
             tooltipText = "Download Failed. Tap to retry.";
             // onPressedAction is already set to startDownload
          } else { // Not Downloaded
            iconWidget = Icon(Icons.download_for_offline_outlined, color: theme.colorScheme.secondary);
            tooltipText = "Download Video";
            // onPressedAction is already set to startDownload
          }
          return IconButton(
            icon: iconWidget,
            tooltip: tooltipText,
            iconSize: 24,
            padding: EdgeInsets.zero,
            onPressed: onPressedAction,
          );
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
        iconColor = theme.colorScheme.error; // YouTube red-ish
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
      default:
        lessonIcon = Icons.extension_outlined;
        iconColor = theme.colorScheme.onSurface.withOpacity(0.5);
        typeDescription = l10n.unknownItemType;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      child: ListTile(
        leading: Icon(lessonIcon, color: iconColor, size: 36),
        title: Text(lesson.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
        subtitle: lesson.summary != null && lesson.summary!.isNotEmpty
            ? Text(lesson.summary!, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall)
            : Text(typeDescription, style: theme.textTheme.bodySmall),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (lesson.duration != null && lesson.duration!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(lesson.duration!, style: theme.textTheme.bodySmall),
              ),
            _buildDownloadButton(context, lesson, lessonProv),
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
       return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            lessonProv.errorForSection(widget.section.id)!,
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
      );
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
    final lessonProvider = Provider.of<LessonProvider>(context);
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
        child: Builder(
          builder: (context) {
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