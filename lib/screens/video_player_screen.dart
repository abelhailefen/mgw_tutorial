import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:mgw_tutorial/models/lesson.dart';
import 'package:mgw_tutorial/provider/lesson_provider.dart';
import 'package:mgw_tutorial/utils/download_status.dart';
import 'package:provider/provider.dart';
import 'dart:io';

class VideoPlayerScreen extends StatefulWidget {
  final String videoTitle;
  final String videoPath;
  final List<Lesson> lessons;
  final String? originalVideoUrl;

  const VideoPlayerScreen({
    super.key,
    required this.videoTitle,
    required this.videoPath,
    required this.lessons,
    this.originalVideoUrl,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final player = Player();
  late final controller = VideoController(player);

  int _currentlyPlayingIndex = -1;
  final Map<String, Future<bool>> _fileStatuses = {};
  final Set<String> _downloadingFiles = {};
  final Map<String, double> _downloadProgress = {};
  bool isLoading = true;
  bool videoError = false;
  String errorMessage = '';
  String selectedSpeed = '1.0';
  bool _isLocal = true;

  @override
  void initState() {
    super.initState();
    _initializeFileStatuses();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    initializeVideo();
  }

  void _initializeFileStatuses() {
    for (var lesson in widget.lessons) {
      final videoUrl = lesson.videoUrl;
      if (videoUrl != null && videoUrl.isNotEmpty) {
        _checkFileStatus(videoUrl);
      }
    }
  }

  void _changePlaybackSpeed(double speed) {
    setState(() {
      selectedSpeed = speed.toString();
      player.setRate(speed);
    });
  }

  Future<void> initializeVideo({bool isLocal = true}) async {
    setState(() {
      isLoading = true;
      videoError = false;
      errorMessage = '';
      _isLocal = isLocal;
    });

    String uri = isLocal
        ? File(widget.videoPath).uri.toString()
        : widget.originalVideoUrl ?? '';

    if (!isLocal && (uri.isEmpty || widget.originalVideoUrl == null)) {
      setState(() {
        videoError = true;
        errorMessage = 'No online URL available for fallback';
        isLoading = false;
      });
      _showSnackbar(errorMessage);
      return;
    }

    try {
      await player.open(Media(uri), play: true);
      setState(() {
        isLoading = false;
      });
      print("Playing ${isLocal ? 'local' : 'online'} video: $uri");
    } catch (e) {
      if (isLocal && widget.originalVideoUrl != null) {
        print("Local playback failed: $e. Falling back to online URL: ${widget.originalVideoUrl}");
        await initializeVideo(isLocal: false);
      } else {
        setState(() {
          videoError = true;
          errorMessage = e.toString();
          isLoading = false;
        });
        _showSnackbar("Error playing video: $errorMessage");
      }
    }
  }

  void _showSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  void _checkFileStatus(String url) {
    final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
    final lesson = widget.lessons.firstWhere(
      (l) => l.videoUrl == url,
      orElse: () => Lesson(
        id: -1,
        title: '',
        sectionId: -1,
        lessonTypeString: 'video',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    final downloadId = lessonProvider.getDownloadId(lesson);
    if (downloadId != null) {
      _fileStatuses[downloadId] = Future.value(
        lessonProvider.getDownloadStatusNotifier(downloadId).value == DownloadStatus.downloaded,
      );
    }
  }

  Future<void> _openFile(List<Lesson> lessons, String title, String url) async {
    setState(() {
      player.stop();
    });
    final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
    final lesson = lessons.firstWhere(
      (l) => l.videoUrl == url,
      orElse: () => Lesson(
        id: -1,
        title: '',
        sectionId: -1,
        lessonTypeString: 'video',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    final downloadId = lessonProvider.getDownloadId(lesson);
    if (downloadId == null || !mounted) return;

    final filePath = await lessonProvider.getDownloadedFilePath(lesson);
    if (filePath == null) {
      _showSnackbar("Failed to get file path for $title");
      return;
    }

    setState(() {
      _currentlyPlayingIndex = lessons.indexWhere((l) => l.videoUrl == url);
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(
          videoPath: filePath,
          videoTitle: title,
          lessons: lessons,
          originalVideoUrl: url,
        ),
      ),
    );
  }

  Widget _buildSpeedDropdown() {
    return DropdownButton<String>(
      value: selectedSpeed,
      onChanged: (String? newValue) {
        double speed = double.parse(newValue!);
        _changePlaybackSpeed(speed);
      },
      items: ['0.5', '1.0', '1.25', '1.5', '2.0']
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            'Speed: $value',
            style: const TextStyle(color: Colors.black),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDownloadButton(BuildContext context, Lesson lesson, LessonProvider lessonProv) {
    final theme = Theme.of(context);
    final String? downloadId = lessonProv.getDownloadId(lesson);

    if (downloadId == null) {
      if (lesson.lessonType == LessonType.video) {
        return SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Icon(
              Icons.cloud_off_outlined,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
              size: 24,
            ),
          ),
        );
      }
      print("No download button: Not a supported downloadable type or missing/invalid URL.");
      return const SizedBox.shrink();
    }

    print("Showing download button for video ID: $downloadId");
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
                icon: Icon(Icons.download_for_offline_outlined, color: theme.colorScheme.secondary),
                tooltip: 'Download Video',
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
                            print("Cancel download pressed for ID: $downloadId");
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
                icon: Icon(Icons.play_circle_fill, color: theme.colorScheme.primary),
                tooltip: 'Play Downloaded Video',
                iconSize: 24,
                padding: EdgeInsets.zero,
                onPressed: () async {
                  print("Play button pressed for ID: $downloadId");
                  await _openFile(widget.lessons, lesson.title, lesson.videoUrl!);
                },
                onLongPress: () {
                  print("Delete button long pressed for ID: $downloadId");
                  lessonProv.deleteDownload(lesson, context);
                },
              );
            case DownloadStatus.failed:
              return IconButton(
                icon: Icon(Icons.error_outline, color: theme.colorScheme.error),
                tooltip: 'Download Failed - Retry',
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

  Widget _buildLessonItem(BuildContext context, Lesson lesson, int index, LessonProvider lessonProv) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: Icon(
          Icons.play_circle_outline_rounded,
          color: theme.colorScheme.error,
          size: 36,
        ),
        title: Text(
          lesson.title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: _currentlyPlayingIndex == index
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
          ),
        ),
        subtitle: lesson.duration != null && lesson.duration!.isNotEmpty
            ? Text(
                lesson.duration!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              )
            : null,
        trailing: _buildDownloadButton(context, lesson, lessonProv),
        onTap: () {
          setState(() {
            _currentlyPlayingIndex = index;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lessonProvider = Provider.of<LessonProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.videoTitle),
        backgroundColor: theme.colorScheme.primary,
        elevation: 10,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height / 2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: videoError
                  ? Center(child: Text('Error: $errorMessage'))
                  : isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            const SizedBox(height: 50),
                            _buildSpeedDropdown(),
                            const SizedBox(height: 16),
                            Expanded(
                              child: Video(
                                controller: controller,
                                controls: AdaptiveVideoControls,
                              ),
                            ),
                          ],
                        ),
            ),
          ),
          Expanded(
            child: Container(
              color: theme.colorScheme.surface, // Lighter background
              child: Column(
                children: [
                  _currentlyPlayingIndex != -1
                      ? Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            "Currently Playing: ${widget.lessons[_currentlyPlayingIndex].title}",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        )
                      : const SizedBox(),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: widget.lessons.length,
                      itemBuilder: (context, index) {
                        final lesson = widget.lessons[index];
                        final videoUrl = lesson.videoUrl;
                        if (videoUrl == null || videoUrl.isEmpty) return const SizedBox();
                        return _buildLessonItem(context, lesson, index, lessonProvider);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}