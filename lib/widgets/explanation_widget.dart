import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:mgw_tutorial/models/question.dart';
import 'package:mgw_tutorial/services/media_service.dart';
import 'package:mgw_tutorial/utils/download_status.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart' as media_kit;

class ExplanationWidget extends StatefulWidget {
  final Question question;
  final String? selectedAnswer;
  final Function(bool isFullScreen)? onFullScreenChange;

  const ExplanationWidget({
    super.key,
    required this.question,
    required this.selectedAnswer,
    this.onFullScreenChange,
  });

  @override
  State<ExplanationWidget> createState() => _ExplanationWidgetState();
}

class _ExplanationWidgetState extends State<ExplanationWidget> {
  YoutubePlayerController? _youtubeController;
  late Player _player;
  media_kit.VideoController? _videoController;
  bool _isVideoInitialized = false;
  late Future<bool> _isVideoDownloaded;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _player = Player(
      configuration: const PlayerConfiguration(
        bufferSize: 32 * 1024 * 1024,
        vo: 'mediakitvideo',
        logLevel: MPVLogLevel.info, // Use valid log level
      ),
    );
    _videoController = media_kit.VideoController(
      _player,
      configuration: const media_kit.VideoControllerConfiguration(),
    );
  }

  void _initializeVideo() {
    final videoUrl = widget.question.explanationVideoUrl;
    if (_isVideoUrlValid(videoUrl)) {
      final videoId = YoutubePlayerController.convertUrlToId(videoUrl!);
      if (videoId != null) {
        _youtubeController = YoutubePlayerController.fromVideoId(
          videoId: videoId,
          params: const YoutubePlayerParams(
            showControls: true,
            showFullscreenButton: true,
            mute: false,
            playsInline: false,
          ),
        );
        // Note: Full-screen change detection not supported in youtube_player_iframe 5.2.1
        // If needed, consider upgrading package or using platform-specific full-screen handling
      } else {
        debugPrint("Invalid YouTube video URL: $videoUrl");
      }
    }
    _isVideoDownloaded = _checkVideoDownloaded();
  }

  bool _isVideoUrlValid(String? videoUrl) {
    return videoUrl != null && videoUrl.isNotEmpty;
  }

  Future<bool> _checkVideoDownloaded() async {
    final videoUrl = widget.question.explanationVideoUrl;
    if (!_isVideoUrlValid(videoUrl)) return false;

    final videoId = _extractVideoId(videoUrl!);
    if (videoId == null) return false;

    return MediaService.isFileDownloaded(videoId);
  }

  String? _extractVideoId(String url) {
    return YoutubePlayerController.convertUrlToId(url);
  }

  Future<void> _downloadVideo() async {
    final videoUrl = widget.question.explanationVideoUrl;
    if (!_isVideoUrlValid(videoUrl)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No video URL available")),
      );
      return;
    }

    final videoId = _extractVideoId(videoUrl!);
    if (videoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid video URL")),
      );
      return;
    }

    final statusNotifier = MediaService.getDownloadStatus(videoId);
    final progressNotifier = MediaService.getDownloadProgress(videoId);

    if (statusNotifier.value == DownloadStatus.downloading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Download in progress")),
      );
      return;
    }

    try {
      final success = await MediaService.downloadVideoFile(
        videoId: videoId,
        url: videoUrl,
        title: widget.question.questionText,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Video downloaded successfully")),
        );
        setState(() {
          _isVideoDownloaded = Future.value(true);
        });
      } else {
        throw Exception("Video download failed");
      }
    } catch (e) {
      debugPrint("Download failed for video ID $videoId: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to download video")),
      );
    }
  }

  Future<void> _playOfflineVideo() async {
    final videoUrl = widget.question.explanationVideoUrl;
    if (!_isVideoUrlValid(videoUrl)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No video URL available")),
      );
      return;
    }

    final videoId = _extractVideoId(videoUrl!);
    if (videoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid video URL")),
      );
      return;
    }

    final filePath = await MediaService.getSecurePath(videoId);
    if (filePath == null || !await File(filePath).exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Offline video not found")),
      );
      return;
    }

    try {
      await _player.stop();
      await _player.open(Media(filePath), play: true);
      setState(() {
        _isVideoInitialized = true;
      });
    } catch (e) {
      debugPrint("Error playing offline video: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error playing video: $e")),
      );
    }
  }

  @override
  void dispose() {
    _youtubeController?.close();
    _player.dispose();
    super.dispose();
  }

  Widget _buildImage(String? url, String imageId) {
    if (url == null || url.isEmpty) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<String?>(
      future: MediaService.getSecurePath(imageId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        final securePath = snapshot.data;
        if (securePath != null && File(securePath).existsSync()) {
          return Image.file(
            File(securePath),
            errorBuilder: (context, error, stackTrace) {
              debugPrint("Error loading local image $imageId: $error");
              return Image.network(
                url,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint("Error loading network image $imageId: $error");
                  return const Text('Failed to load explanation image');
                },
              );
            },
          );
        }
        return Image.network(
          url,
          errorBuilder: (context, error, stackTrace) {
            debugPrint("Error loading network image $imageId: $error");
            return const Text('Failed to load explanation image');
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0.5,
      color: theme.colorScheme.primaryContainer.withOpacity(0.5),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Explanation Title
            const Text(
              "Explanation",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            // Correct Answer
            Text(
              "Correct Answer: ${widget.question.answer}",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            // Explanation Text
            if (widget.question.explanation != null &&
                widget.question.explanation!.isNotEmpty)
              HtmlWidget(
                widget.question.explanation!,
                textStyle: TextStyle(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            const SizedBox(height: 10),
            // Explanation Image
            if (widget.question.explanationImageUrl != null &&
                widget.question.explanationImageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildImage(
                  widget.question.explanationImageUrl,
                  'expimage${widget.question.id}',
                ),
              ),
            // Video Player Section
            if (_isVideoUrlValid(widget.question.explanationVideoUrl))
              FutureBuilder<bool>(
                future: _isVideoDownloaded,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final isDownloaded = snapshot.data ?? false;

                  if (isDownloaded && _isVideoInitialized) {
                    return SizedBox(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.3,
                      child: media_kit.Video(
                        controller: _videoController!,
                        controls: media_kit.AdaptiveVideoControls,
                      ),
                    );
                  } else if (!isDownloaded && _youtubeController != null) {
                    return SizedBox(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.3,
                      child: YoutubePlayer(
                        controller: _youtubeController!,
                        aspectRatio: 16 / 9,
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            const SizedBox(height: 10),
            // Video Control Buttons
            if (_isVideoUrlValid(widget.question.explanationVideoUrl))
              FutureBuilder<bool>(
                future: _isVideoDownloaded,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final isDownloaded = snapshot.data ?? false;
                  final videoId = _extractVideoId(
                      widget.question.explanationVideoUrl!);
                  if (videoId == null) return const SizedBox.shrink();

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Play Offline Button
                      if (isDownloaded)
                        ElevatedButton.icon(
                          onPressed: _playOfflineVideo,
                          icon: const Icon(Icons.play_circle_outline),
                          label: const Text("Play Offline Video"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.secondary,
                            foregroundColor: theme.colorScheme.onSecondary,
                          ),
                        ),
                      const SizedBox(width: 8),
                      // Download Button or Progress
                      if (!isDownloaded)
                        ValueListenableBuilder<DownloadStatus>(
                          valueListenable: MediaService.getDownloadStatus(videoId),
                          builder: (context, status, child) {
                            if (status == DownloadStatus.downloading) {
                              return ValueListenableBuilder<double>(
                                valueListenable:
                                    MediaService.getDownloadProgress(videoId),
                                builder: (context, progress, _) {
                                  return Column(
                                    children: [
                                      SizedBox(
                                        width: 40,
                                        height: 40,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            CircularProgressIndicator(
                                              value: progress,
                                              strokeWidth: 3.0,
                                              backgroundColor: theme
                                                  .colorScheme.onSurface
                                                  .withOpacity(0.1),
                                              color: theme.colorScheme.primary,
                                            ),
                                            if (progress > 0)
                                              Text(
                                                "${(progress * 100).toInt()}%",
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(fontSize: 10),
                                              ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.cancel,
                                            color: theme.colorScheme.error,
                                            size: 16),
                                        onPressed: () =>
                                            MediaService.cancelDownload(videoId),
                                        tooltip: "Cancel Download",
                                      ),
                                    ],
                                  );
                                },
                              );
                            }
                            return IconButton(
                              icon: Icon(Icons.download_for_offline_outlined,
                                  color: theme.colorScheme.secondary),
                              tooltip: "Download Video",
                              onPressed: _downloadVideo,
                            );
                          },
                        ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}