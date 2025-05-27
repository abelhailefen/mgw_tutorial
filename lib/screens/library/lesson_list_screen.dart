import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;

import '../../models/lesson.dart';
import '../../models/section.dart';
import '../../provider/lesson_provider.dart';
import '../../utils/download_status.dart';

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
    print("LessonListScreen init for section: ${widget.section.title} (ID: ${widget.section.id})");
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
    print("LessonListScreen dispose for section: ${widget.section.title}");
  }

  Future<void> _refreshLessons() async {
    await Provider.of<LessonProvider>(context, listen: false)
        .fetchLessonsForSection(widget.section.id, forceRefresh: true);
  }

  Future<void> _playOrLaunchContent(BuildContext context, Lesson lesson) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final lessonProvider = Provider.of<LessonProvider>(context, listen: false);

    if (lesson.lessonType == LessonType.video && lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty) {
      final String? videoId = yt.VideoId.parseVideoId(lesson.videoUrl!);

      if (videoId != null) {
        final status = lessonProvider.getDownloadStatusNotifier(videoId).value;

        if (status == DownloadStatus.downloaded) {
          final filePath = await lessonProvider.getDownloadedFilePath(lesson);
          if (filePath != null && filePath.isNotEmpty) {
            print("Attempting to open downloaded file: $filePath for video ID $videoId");
            final result = await OpenFilex.open(filePath);
            print("OpenFile result for $filePath: ${result.type}, ${result.message}");

            if (result.type != ResultType.done && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("${l10n.couldNotOpenFileError}${result.message}"),
                  backgroundColor: theme.colorScheme.errorContainer,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            return;
          } else {
            print("Download status was downloaded ($videoId), but file path not found/invalid.");
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.couldNotFindDownloadedFileError),
                  backgroundColor: theme.colorScheme.errorContainer,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        } else if (status == DownloadStatus.downloading) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.videoIsDownloadingMessage),
                backgroundColor: theme.colorScheme.secondaryContainer,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        } else if (status == DownloadStatus.failed) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.videoDownloadFailedMessage),
                backgroundColor: theme.colorScheme.errorContainer,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        } else if (status == DownloadStatus.cancelled) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.videoDownloadCancelledMessage),
                backgroundColor: theme.colorScheme.secondaryContainer,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
      }
      _launchUrl(context, lesson.videoUrl, lesson.title);
    } else if (lesson.lessonType == LessonType.document && lesson.attachmentUrl != null && lesson.attachmentUrl!.isNotEmpty) {
      _launchUrl(context, lesson.attachmentUrl, lesson.title);
    } else if (lesson.lessonType == LessonType.quiz) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${l10n.quizItemType}: ${lesson.title} (${l10n.notImplementedMessage})"),
            backgroundColor: theme.colorScheme.secondaryContainer,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else if (lesson.lessonType == LessonType.text && lesson.summary != null && lesson.summary!.isNotEmpty) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (dCtx) => AlertDialog(
            backgroundColor: theme.dialogBackgroundColor,
            title: Text(lesson.title, style: theme.textTheme.titleLarge),
            content: SingleChildScrollView(child: Text(lesson.summary ?? l10n.noTextContent, style: theme.textTheme.bodyLarge)),
            actions: [
              TextButton(
                child: Text(l10n.closeButtonText, style: TextStyle(color: theme.colorScheme.primary)),
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
            content: Text(l10n.noLaunchableContent(lesson.title)),
            backgroundColor: theme.colorScheme.secondaryContainer,
            behavior: SnackBarBehavior.floating,
          ),
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
      if (!await launchUrl(uri, mode: LaunchMode.inAppWebView)) {
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          print("Cannot launch URL $urlString with any method.");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.couldNotLaunchItem(urlString)),
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

  Widget _buildDownloadButton(BuildContext context, Lesson lesson, LessonProvider lessonProv) {
    final theme = Theme.of(context);
    if (lesson.lessonType != LessonType.video || lesson.videoUrl == null || lesson.videoUrl!.isEmpty) {
      return const SizedBox.shrink();
    }
    if (lesson.videoProvider?.toLowerCase() != 'youtube') {
      return SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: Icon(
            Icons.videocam_off_outlined,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
            size: 24,
          ),
        ),
      );
    }

    final String? videoId = yt.VideoId.parseVideoId(lesson.videoUrl!);
    if (videoId == null) {
      return SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: Icon(
            Icons.link_off,
            color: theme.colorScheme.error.withOpacity(0.7),
            size: 24,
          ),
        ),
      );
    }

    return SizedBox(
      width: 40,
      height: 40,
      child: ValueListenableBuilder<DownloadStatus>(
        valueListenable: lessonProv.getDownloadStatusNotifier(videoId),
        builder: (context, status, child) {
          switch (status) {
            case DownloadStatus.notDownloaded:
            case DownloadStatus.cancelled:
              return IconButton(
                icon: Icon(Icons.download_for_offline_outlined, color: theme.colorScheme.secondary),
                tooltip: AppLocalizations.of(context)!.downloadVideoTooltip,
                iconSize: 24,
                padding: EdgeInsets.zero,
                onPressed: () {
                  print("Download button pressed for ID: $videoId");
                  lessonProv.startDownload(lesson);
                },
              );
            case DownloadStatus.downloading:
              return ValueListenableBuilder<double>(
                valueListenable: lessonProv.getDownloadProgressNotifier(videoId),
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
                          backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
                          color: theme.colorScheme.primary,
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
                            print("Cancel download pressed for ID: $videoId");
                            lessonProv.cancelDownload(lesson);
                          },
                          child: Icon(
                            Icons.cancel,
                            size: 16,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            case DownloadStatus.downloaded:
              return IconButton(
                icon: Icon(Icons.check_circle, color: theme.colorScheme.primary),
                tooltip: AppLocalizations.of(context)!.downloadedVideoTooltip,
                iconSize: 24,
                padding: EdgeInsets.zero,
                onPressed: () async {
                  print("Play button pressed for ID: $videoId");
                  await _playOrLaunchContent(context, lesson);
                },
                onLongPress: () {
                  print("Delete button long pressed for ID: $videoId");
                  lessonProv.deleteDownload(lesson, context);
                },
              );
            case DownloadStatus.failed:
              return IconButton(
                icon: Icon(Icons.error_outline, color: theme.colorScheme.error),
                tooltip: AppLocalizations.of(context)!.downloadFailedTooltip,
                iconSize: 24,
                padding: EdgeInsets.zero,
                onPressed: () {
                  print("Retry button pressed for ID: $videoId");
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
      default:
        lessonIcon = Icons.extension_outlined;
        iconColor = theme.colorScheme.onSurface.withOpacity(0.5);
        typeDescription = l10n.unknownItemType;
    }

    final String? videoIdForDeleteCheck = (lesson.lessonType == LessonType.video && lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty)
        ? yt.VideoId.parseVideoId(lesson.videoUrl!)
        : null;

    Widget deleteButton = const SizedBox.shrink();
    if (videoIdForDeleteCheck != null) {
      deleteButton = SizedBox(
        width: 40,
        height: 40,
        child: ValueListenableBuilder<DownloadStatus>(
          valueListenable: lessonProv.getDownloadStatusNotifier(videoIdForDeleteCheck),
          builder: (context, status, child) {
            if (status == DownloadStatus.downloaded) {
              return IconButton(
                icon: Icon(Icons.delete_outline, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                tooltip: l10n.deleteDownloadedFileTooltip,
                iconSize: 24,
                padding: EdgeInsets.zero,
                onPressed: () {
                  print("Delete button pressed for ID: $videoIdForDeleteCheck");
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: Icon(lessonIcon, color: iconColor, size: 36),
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
            _buildDownloadButton(context, lesson, lessonProv),
            deleteButton,
          ],
        ),
        onTap: () async => await _playOrLaunchContent(context, lesson),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, List<Lesson> lessons, LessonProvider lessonProv, LessonType filterType, String noContentMessage, IconData emptyIcon) {
    final theme = Theme.of(context);
    final filteredLessons = lessons.where((l) => l.lessonType == filterType).toList();
    final bool isLoadingInitial = lessonProv.isLoadingForSection(widget.section.id) && lessons.isEmpty;
    final String? errorInitial = lessonProv.errorForSection(widget.section.id);

    if (isLoadingInitial || (errorInitial != null && lessons.isEmpty)) {
      return const SizedBox.shrink();
    }

    if (filteredLessons.isEmpty) {
      if (lessons.isNotEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(emptyIcon, size: 60, color: theme.iconTheme.color?.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(noContentMessage, textAlign: TextAlign.center, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7))),
            ],
          ),
        );
      } else {
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
                      ),
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
                  ),
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
          },
        ),
      ),
    );
  }
}