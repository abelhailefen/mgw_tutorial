import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart' as media_kit;
import 'package:mgw_tutorial/models/lesson.dart';
import 'package:mgw_tutorial/provider/lesson_provider.dart';
import 'package:mgw_tutorial/utils/download_status.dart';
import 'package:provider/provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'dart:io';

class VideoPlayerScreen extends StatefulWidget {
  final String videoTitle;
  final String videoPath;
  final List<Lesson> lessons;
  final String? originalVideoUrl;
  final bool isLocal;

  const VideoPlayerScreen({
    super.key,
    required this.videoTitle,
    required this.videoPath,
    required this.lessons,
    this.originalVideoUrl,
    this.isLocal = false,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final player = Player(
    configuration: const PlayerConfiguration(
      bufferSize: 32 * 1024 * 1024,
      vo: 'mediakitvideo',
      logLevel: MPVLogLevel.debug,
    ),
  );
  late final controller = media_kit.VideoController(
    player,
    configuration: const media_kit.VideoControllerConfiguration(
      enableHardwareAcceleration: false,
    ),
  );

  int _currentlyPlayingIndex = -1;
  final Map<String, Future<bool>> _fileStatuses = {};
  final Set<String> _downloadingFiles = {};
  final Map<String, double> _downloadProgress = {};
  bool _isLoading = true;
  bool _videoError = false;
  String _errorMessage = '';
  String _selectedSpeed = '1.0';
  Size _videoSize = const Size(16, 9);
  bool _isOpening = false;

  @override
  void initState() {
    super.initState();
    _initializeFileStatuses();
    player.streams.width.listen((width) {
      if (width != null && width > 0 && mounted) {
        player.streams.height.listen((height) {
          if (height != null && height > 0 && mounted) {
            setState(() {
              _videoSize = Size(width.toDouble(), height.toDouble());
            });
            print("Updated video size: $_videoSize");
          }
        });
      }
    });
    player.streams.error.listen((error) {
      if (error != null && mounted) {
        setState(() {
          _videoError = true;
          _errorMessage = 'Playback error: $error';
          _isLoading = false;
        });
        _showSnackBar(_errorMessage);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeVideo(isLocal: widget.isLocal);
  }

  void _initializeFileStatuses() {
    for (Lesson lesson in widget.lessons) {
      final videoUrl = lesson.videoUrl;
      if (videoUrl != null && videoUrl.isNotEmpty) {
        _checkFileStatus(videoUrl);
      }
    }
  }

  void _changePlaybackSpeed(double speed) {
    if (!mounted) return;
    setState(() {
      _selectedSpeed = speed.toString();
      player.setRate(speed);
    });
  }

  Future<void> _initializeVideo({required bool isLocal}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _videoError = false;
      _errorMessage = '';
    });

    String uri = '';
    print("Initializing video: isLocal=$isLocal, url=${widget.originalVideoUrl}");
    try {
      if (isLocal) {
        uri = File(widget.videoPath).uri.toString();
        print("Local video URI: $uri");
      } else {
        if (widget.originalVideoUrl == null || widget.originalVideoUrl!.isEmpty) {
          if (!mounted) return;
          setState(() {
            _videoError = true;
            _errorMessage = 'No online URL available for streaming';
            _isLoading = false;
          });
          _showSnackBar(_errorMessage);
          return;
        }

        try {
          final explode = YoutubeExplode();
          // Use VideoId to parse the URL robustly
          final videoId = VideoId(widget.originalVideoUrl!);
          if (videoId.value.isEmpty) {
            throw Exception('Could not extract video ID from URL');
          }
          print("Fetching stream manifest for video ID: ${videoId.value}");
          final streamManifest = await explode.videos.streamsClient.getManifest(videoId).timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Timed out fetching YouTube stream'),
          );
          print("Stream manifest fetched successfully");
          final mp4VideoStreams = streamManifest.videoOnly.where((stream) => stream.container.name == 'mp4').toList();
          if (mp4VideoStreams.isEmpty) {
            print("No video-only MP4 streams found, trying muxed streams");
            final muxedStreams = streamManifest.muxed.where((stream) => stream.container.name == 'mp4').toList();
            if (muxedStreams.isEmpty) {
              print("No MP4 streams found, trying any stream");
              final allStreams = streamManifest.video;
              if (allStreams.isEmpty) {
                throw Exception('No suitable streams found');
              }
              final videoStream = allStreams.reduce((a, b) => a.bitrate.bitsPerSecond > b.bitrate.bitsPerSecond ? a : b);
              uri = videoStream.url.toString();
            } else {
              final videoStream = muxedStreams.reduce((a, b) => a.bitrate.bitsPerSecond > b.bitrate.bitsPerSecond ? a : b);
              uri = videoStream.url.toString();
            }
          } else {
            final videoStream = mp4VideoStreams.reduce((a, b) => a.bitrate.bitsPerSecond > b.bitrate.bitsPerSecond ? a : b);
            uri = videoStream.url.toString();
          }
          explode.close();
          print("Extracted streamable URL: $uri");
        } catch (e) {
          print("Error fetching YouTube stream: $e");
          if (!mounted) return;
          setState(() {
            _videoError = true;
            _errorMessage = 'Failed to fetch YouTube stream: $e';
            _isLoading = false;
          });
          _showSnackBar(_errorMessage);
          return;
        }
      }

      print("Opening media: $uri");
      await player.open(Media(uri), play: true).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Timed out loading video'),
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      print("Playing ${isLocal ? 'local' : 'online'} video: $uri");
    } catch (e) {
      print("Error playing video: $e");
      if (isLocal && widget.originalVideoUrl != null) {
        print("Local playback failed: $e. Falling back to online URL: ${widget.originalVideoUrl}");
        await _initializeVideo(isLocal: false);
      } else {
        if (!mounted) return;
        setState(() {
          _videoError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
        _showSnackBar("Error playing video: $_errorMessage");
      }
    }
  }

  void _showSnackBar(String message) {
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
    print("VideoPlayerScreen disposed");
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

  Future<void> _openFile(List<Lesson> lessons, String title, String url, bool isLocal) async {
    if (_isOpening) return;
    _isOpening = true;
    print("Opening file: title=$title, url=$url, isLocal=$isLocal");
    player.stop();
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
    if (downloadId == null && isLocal) {
      _showSnackBar("No downloaded file available for $title");
      _isOpening = false;
      return;
    }

    String filePath = '';
    if (isLocal) {
      filePath = await lessonProvider.getDownloadedFilePath(lesson) ?? '';
      if (filePath.isEmpty) {
        _showSnackBar("Failed to get file path for $title");
        _isOpening = false;
        return;
      }
    }

    if (!mounted) {
      _isOpening = false;
      return;
    }
    setState(() {
      _currentlyPlayingIndex = lessons.indexWhere((l) => l.videoUrl == url);
    });

    await Future.delayed(Duration.zero);
    if (!mounted) {
      _isOpening = false;
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(
          videoPath: isLocal ? filePath : '',
          videoTitle: title,
          lessons: lessons,
          originalVideoUrl: url,
          isLocal: isLocal,
        ),
      ),
    );
    _isOpening = false;
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
                  await _openFile(widget.lessons, lesson.title, lesson.videoUrl!, true);
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
        leading: IconButton(
          icon: Icon(
            Icons.play_circle_outline_rounded,
            color: theme.colorScheme.error,
            size: 36,
          ),
          onPressed: lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty
              ? () async {
                  final downloadId = lessonProv.getDownloadId(lesson);
                  bool isLocal = false;
                  String filePath = '';
                  if (downloadId != null) {
                    final status = lessonProv.getDownloadStatusNotifier(downloadId).value;
                    if (status == DownloadStatus.downloaded) {
                      filePath = await lessonProv.getDownloadedFilePath(lesson) ?? '';
                      isLocal = filePath.isNotEmpty;
                    }
                  }
                  await _openFile(widget.lessons, lesson.title, lesson.videoUrl!, isLocal);
                }
              : null,
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
          if (!mounted) return;
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
              aspectRatio: _videoSize.width / _videoSize.height,
              child: _videoError
                  ? Center(child: Text('Error: $_errorMessage'))
                  : _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                          
                            const SizedBox(height: 16),
                            Expanded(
                              child: media_kit.Video(
                                controller: controller,
                                controls: media_kit.AdaptiveVideoControls,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
            ),
          ),
          Expanded(
            child: Container(
              color: theme.colorScheme.surface,
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