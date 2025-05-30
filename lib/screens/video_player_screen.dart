import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mgw_tutorial/models/lesson.dart';
import 'package:mgw_tutorial/screens/video_controls_overlay.dart';
import 'package:mgw_tutorial/screens/video_bottom_controls.dart';
import 'package:url_launcher/url_launcher.dart';

class VideoPlayerScreen extends StatefulWidget {
  static const routeName = '/video-player';
  final String videoTitle;
  final String videoPath;
  final String? originalVideoUrl;
  final List<Lesson> lessons;

  const VideoPlayerScreen({
    super.key,
    required this.videoTitle,
    required this.videoPath,
    this.originalVideoUrl,
    required this.lessons,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> with TickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool isLoading = true;
  bool videoError = false;
  String errorMessage = '';
  double _playbackSpeed = 1.0;
  bool _isMuted = false;
  late TabController _tabController;
  bool _isFullscreen = false;

  List<Lesson> videoLessons = [];
  List<Lesson> otherLessons = [];

  Lesson? get _currentLesson {
    try {
      if (widget.originalVideoUrl != null && widget.originalVideoUrl!.isNotEmpty) {
        return widget.lessons.firstWhere((l) => l.videoUrl == widget.originalVideoUrl, orElse: () => throw StateError('not found'));
      }
      return widget.lessons.firstWhere((l) => l.title == widget.videoTitle, orElse: () => throw StateError('not found'));
    } catch (e) {
      print("Warning: Could not find the current lesson in the provided list.");
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    categorizeLessons();
    initializeVideo(widget.videoPath);
  }

  void categorizeLessons() {
    for (var lesson in widget.lessons) {
      if (lesson.lessonType == LessonType.video) {
        videoLessons.add(lesson);
      } else {
        otherLessons.add(lesson);
      }
    }
  }

  Future<void> initializeVideo(String path, {bool isLocal = true}) async {
    if (_controller != null) {
      await _controller!.dispose();
    }

    setState(() {
      isLoading = true;
      videoError = false;
      errorMessage = '';
      _controller = null;
    });

    // First attempt: Try hardware decoding
    try {
      _controller = isLocal
          ? VideoPlayerController.file(File(path))
          : VideoPlayerController.network(widget.originalVideoUrl!);
      await _controller!.initialize();
      _controller!.setLooping(true);
      _controller!.play();
      setState(() {
        isLoading = false;
        videoError = false;
      });
      print("Video initialized with hardware decoding from ${isLocal ? 'path: $path' : 'URL: ${widget.originalVideoUrl}'}");
    } catch (e) {
      print("Hardware decoding failed: $e");

      // Check if the error is codec-related (e.g., DecoderInitializationException)
      if (e is PlatformException && e.message?.contains('DecoderInitializationException') == true) {
        // Second attempt: Try software decoding
        try {
          _controller = isLocal
              ? VideoPlayerController.file(File(path))
              : VideoPlayerController.network(widget.originalVideoUrl!);
          await _controller!.initializeWithOptions(
            VideoPlayerOptions(
              allowHardwareAcceleration: false,
            ),
          );
          _controller!.setLooping(true);
          _controller!.play();
          setState(() {
            isLoading = false;
            videoError = false;
          });
          print("Video initialized with software decoding from ${isLocal ? 'path: $path' : 'URL: ${widget.originalVideoUrl}'}");
        } catch (e) {
          print("Software decoding also failed: $e");
          _controller = null;
          setState(() {
            videoError = true;
            errorMessage = _getConciseErrorMessage(e);
            isLoading = false;
          });
          _showSnackbar("${AppLocalizations.of(context)!.videoPlaybackError}: $errorMessage");
          if (isLocal && widget.originalVideoUrl != null && !videoError) {
            print("Falling back to online URL: ${widget.originalVideoUrl}");
            await initializeVideo(widget.originalVideoUrl!, isLocal: false);
          }
        }
      } else {
        // Handle other errors (not codec-related)
        _controller = null;
        setState(() {
          videoError = true;
          errorMessage = _getConciseErrorMessage(e);
          isLoading = false;
        });
        _showSnackbar("${AppLocalizations.of(context)!.videoPlaybackError}: $errorMessage");
        if (isLocal && widget.originalVideoUrl != null && !videoError) {
          print("Falling back to online URL: ${widget.originalVideoUrl}");
          await initializeVideo(widget.originalVideoUrl!, isLocal: false);
        }
      }
    }
  }

  String _getConciseErrorMessage(dynamic error) {
    if (error is PlatformException) {
      if (error.message != null && error.message!.contains('MediaCodecVideoRenderer error')) {
        final match = RegExp(r'Decoder init failed: .*').firstMatch(error.message!);
        if (match != null) {
          return match.group(0)!;
        }
      }
      return error.message ?? error.toString();
    }
    return error.toString();
  }

  void _showSnackbar(String message) {
    if (!mounted) return;
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: theme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    if (_isFullscreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    _tabController.dispose();
    super.dispose();
  }

  void _toggleMute() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller!.setVolume(_isMuted ? 0 : 1);
    });
  }

  void _changeSpeed(double speed) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    setState(() {
      _playbackSpeed = speed;
      _controller!.setPlaybackSpeed(speed);
    });
  }

  void _toggleFullscreen() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    setState(() {
      _isFullscreen = !_isFullscreen;
      if (_isFullscreen) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeRight,
          DeviceOrientation.landscapeLeft,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    });
  }

  Future<bool> _onWillPop() async {
    if (_isFullscreen) {
      _toggleFullscreen();
      return false;
    }
    return true;
  }

  Future<void> _launchOriginalUrl(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (widget.originalVideoUrl == null || widget.originalVideoUrl!.isEmpty) {
      _showSnackbar(l10n.noOnlineVideoUrlAvailable);
      return;
    }

    final Uri uri = Uri.parse(widget.originalVideoUrl!);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (!await launchUrl(uri, mode: LaunchMode.inAppWebView)) {
          _showSnackbar(l10n.couldNotLaunchItem(widget.originalVideoUrl!));
        }
      }
    } catch (e) {
      _showSnackbar("${l10n.couldNotLaunchItem(widget.originalVideoUrl!)}: $e");
    }
  }

  Widget _buildLessonList(List<Lesson> lessons, {required bool isVideoTab}) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (lessons.isEmpty) {
      return Center(
        child: Text(
          isVideoTab ? l10n.noOtherVideosInChapter : l10n.noOtherContentInChapter,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
        ),
      );
    }

    return ListView.builder(
      itemCount: lessons.length,
      itemBuilder: (context, index) {
        final lesson = lessons[index];
        IconData lessonIcon;
        Color iconColor;
        String itemTypeDescription;

        switch (lesson.lessonType) {
          case LessonType.video:
            lessonIcon = Icons.play_circle_outline_rounded;
            iconColor = theme.colorScheme.error;
            itemTypeDescription = l10n.videoItemType;
            break;
          case LessonType.document:
            lessonIcon = Icons.description_outlined;
            iconColor = theme.colorScheme.secondary;
            itemTypeDescription = l10n.documentItemType;
            break;
          case LessonType.quiz:
            lessonIcon = Icons.quiz_outlined;
            iconColor = theme.colorScheme.tertiary;
            itemTypeDescription = l10n.quizItemType;
            break;
          case LessonType.text:
            lessonIcon = Icons.notes_outlined;
            iconColor = theme.colorScheme.primary;
            itemTypeDescription = l10n.textItemType;
            break;
          default:
            lessonIcon = Icons.extension_outlined;
            iconColor = theme.colorScheme.onSurface.withOpacity(0.5);
            itemTypeDescription = l10n.unknownItemType;
        }

        final bool isAttemptedLocalVideo = isVideoTab && lesson.videoUrl != null && lesson.videoUrl == (_currentLesson?.videoUrl ?? 'none');

        return Card(
          color: isAttemptedLocalVideo ? theme.colorScheme.primaryContainer.withOpacity(0.5) : null,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: 1.0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          child: ListTile(
            leading: Icon(lessonIcon, color: iconColor),
            title: Text(
              lesson.title ?? 'Untitled',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: isAttemptedLocalVideo ? FontWeight.bold : FontWeight.w500,
                color: isAttemptedLocalVideo ? theme.colorScheme.onPrimaryContainer : null,
              ),
            ),
            subtitle: Text(
              lesson.summary != null && lesson.summary!.isNotEmpty ? lesson.summary! : itemTypeDescription,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isAttemptedLocalVideo ? theme.colorScheme.onPrimaryContainer.withOpacity(0.7) : null,
              ),
            ),
            trailing: isVideoTab && lesson.duration != null && lesson.duration!.isNotEmpty
                ? Text(lesson.duration!, style: theme.textTheme.bodySmall?.copyWith(color: isAttemptedLocalVideo ? theme.colorScheme.onPrimaryContainer : null))
                : null,
            onTap: () {
              if (lesson.lessonType == LessonType.video) {
                if (isAttemptedLocalVideo) {
                  if (videoError) {
                    initializeVideo(widget.videoPath);
                  }
                } else {
                  _showSnackbar(l10n.cannotPlayOtherVideoHere);
                }
              } else if (lesson.lessonType == LessonType.text && lesson.summary != null && lesson.summary!.isNotEmpty) {
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
              } else if (lesson.lessonType == LessonType.document && lesson.attachmentUrl != null && lesson.attachmentUrl!.isNotEmpty) {
                _launchOriginalUrl(context);
              } else if (lesson.lessonType == LessonType.quiz) {
                _showSnackbar("${lesson.lessonType.toString().split('.').last}: ${lesson.title} (${l10n.notImplementedMessage})");
              } else {
                _showSnackbar(l10n.noLaunchableContent(lesson.title));
              }
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    double? videoContainerHeight;
    if (_controller != null && _controller!.value.isInitialized) {
      videoContainerHeight = MediaQuery.of(context).size.width / _controller!.value.aspectRatio;
    } else {
      videoContainerHeight = MediaQuery.of(context).size.width * (9 / 16);
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: _isFullscreen
            ? null
            : AppBar(
                title: Text(widget.videoTitle, style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onPrimary)),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
        body: isLoading
            ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
            : videoError
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 50),
                          const SizedBox(height: 16),
                          Text(
                            '${l10n.videoPlaybackError}: $errorMessage',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.error),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: isLoading ? null : () => initializeVideo(widget.videoPath),
                            child: Text(l10n.retry),
                          ),
                          if (widget.originalVideoUrl != null && widget.originalVideoUrl!.isNotEmpty) const SizedBox(height: 10),
                          if (widget.originalVideoUrl != null && widget.originalVideoUrl!.isNotEmpty)
                            TextButton.icon(
                              icon: Icon(Icons.open_in_browser, color: theme.colorScheme.primary),
                              label: Text(l10n.playOriginalOnline),
                              onPressed: isLoading ? null : () => _launchOriginalUrl(context),
                            ),
                        ],
                      ),
                    ),
                  )
                : (_controller != null && _controller!.value.isInitialized)
                    ? Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: MediaQuery.of(context).size.width,
                            height: _isFullscreen ? MediaQuery.of(context).size.height : videoContainerHeight!,
                            child: Center(
                              child: AspectRatio(
                                aspectRatio: _controller!.value.aspectRatio,
                                child: Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    VideoPlayer(_controller!),
                                    VideoControlsOverlay(controller: _controller!),
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: VideoBottomControls(
                                        controller: _controller!,
                                        onMuteToggle: _toggleMute,
                                        isMuted: _isMuted,
                                        onSpeedChange: _changeSpeed,
                                        currentSpeed: _playbackSpeed,
                                        onZoomToggle: _toggleFullscreen,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 40,
                                      left: 0,
                                      right: 0,
                                      child: VideoProgressIndicator(
                                        _controller!,
                                        allowScrubbing: true,
                                        colors: VideoProgressColors(
                                          playedColor: theme.colorScheme.primary,
                                          bufferedColor: theme.colorScheme.primary.withOpacity(0.3),
                                          backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (!_isFullscreen)
                            Expanded(
                              child: Column(
                                children: [
                                  TabBar(
                                    controller: _tabController,
                                    labelColor: theme.colorScheme.primary,
                                    unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
                                    indicatorColor: theme.colorScheme.primary,
                                    tabs: [
                                      Tab(text: l10n.videoItemType),
                                      Tab(text: l10n.otherItemsTabTitle),
                                    ],
                                  ),
                                  Expanded(
                                    child: TabBarView(
                                      controller: _tabController,
                                      children: [
                                        _buildLessonList(videoLessons, isVideoTab: true),
                                        _buildLessonList(otherLessons, isVideoTab: false),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      )
                    : Center(child: Text(l10n.unexpectedError)),
      ),
    );
  }
}