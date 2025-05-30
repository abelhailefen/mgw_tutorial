// lib/screens/video_player_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mgw_tutorial/models/lesson.dart';
import 'package:mgw_tutorial/screens/video_controls_overlay.dart';
import 'package:mgw_tutorial/screens/video_bottom_controls.dart';
// Import url_launcher to potentially launch the original URL
import 'package:url_launcher/url_launcher.dart';

class VideoPlayerScreen extends StatefulWidget {
  static const routeName = '/video-player';
  final String videoTitle;
  final String videoPath; // Local downloaded path
  final String? originalVideoUrl; // Add original URL for fallback
  final List<Lesson> lessons;

  const VideoPlayerScreen({
    super.key,
    required this.videoTitle,
    required this.videoPath,
    this.originalVideoUrl, // Make original URL optional
    required this.lessons,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with TickerProviderStateMixin {
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

  // Find the current lesson from the list based on the original URL or title
  Lesson? get _currentLesson {
     try {
       // Try finding by original URL first
        if (widget.originalVideoUrl != null && widget.originalVideoUrl!.isNotEmpty) {
             return widget.lessons.firstWhere((l) => l.videoUrl == widget.originalVideoUrl, orElse: () => throw StateError('not found'));
        }
        // Fallback to finding by title (less reliable)
        return widget.lessons.firstWhere((l) => l.title == widget.videoTitle, orElse: () => throw StateError('not found'));
     } catch (e) {
        print("Warning: Could not find the current lesson in the provided list.");
        return null; // Return null if lesson is not found
     }
  }


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    categorizeLessons();
    initializeVideo(widget.videoPath); // Attempt to play downloaded file
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

  Future<void> initializeVideo(String path) async {
    if (_controller != null) {
        // No need to check isInitialized here, dispose handles it
        await _controller!.dispose();
    }

    setState(() {
      isLoading = true;
      videoError = false;
      errorMessage = '';
      _controller = null; // Ensure controller is null before assignment attempt
    });

    try {
      _controller = VideoPlayerController.file(File(path));
      await _controller!.initialize();
      _controller!.setLooping(true);
      _controller!.play();
      setState(() {
        isLoading = false;
        videoError = false;
      });
       print("Video initialized and playing from path: $path");
    } catch (e) {
      print("Error initializing video from path $path: $e");
      _controller = null; // Set to null on error
      setState(() {
        videoError = true;
        // Capture a more concise error message if possible
        errorMessage = _getConciseErrorMessage(e);
        isLoading = false;
      });
      _showSnackbar("Error playing video: $errorMessage");
    }
  }

  // Helper to get a cleaner error message
  String _getConciseErrorMessage(dynamic error) {
    if (error is PlatformException) {
       // Check for specific known error patterns
       if (error.message != null && error.message!.contains('MediaCodecVideoRenderer error')) {
          // Extract relevant part, like "Decoder init failed: OMX..."
          final match = RegExp(r'Decoder init failed: .*').firstMatch(error.message!);
          if (match != null) {
             return match.group(0)!; // Return the matched string
          }
       }
       // Fallback to platform exception message
       return error.message ?? error.toString();
    }
     // Fallback to generic error string
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
    if (_controller != null) {
       _controller!.dispose();
    }
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

   // Function to launch the original URL
  Future<void> _launchOriginalUrl(BuildContext context) async {
     final l10n = AppLocalizations.of(context)!;
     final theme = Theme.of(context);

     if (widget.originalVideoUrl == null || widget.originalVideoUrl!.isEmpty) {
        _showSnackbar(l10n.noOnlineVideoUrlAvailable ?? 'No online video URL available.'); // Assuming new key
        return;
     }

     final Uri uri = Uri.parse(widget.originalVideoUrl!);
      try {
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
           print("Cannot launch URL ${widget.originalVideoUrl} externally, trying in-app.");
          if (!await launchUrl(uri, mode: LaunchMode.inAppWebView)) {
             print("Cannot launch URL ${widget.originalVideoUrl} with any method.");
             if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(
                   content: Text(l10n.couldNotLaunchItem(widget.originalVideoUrl!)), // Reuse key
                   backgroundColor: theme.colorScheme.errorContainer,
                   behavior: SnackBarBehavior.floating,
                 ),
               );
             }
          } else {
             print("Launched URL ${widget.originalVideoUrl} in-app.");
          }
        } else {
          print("Launched URL ${widget.originalVideoUrl} externally.");
        }
      } catch (e) {
        print("Error launching URL ${widget.originalVideoUrl}: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("${l10n.couldNotLaunchItem(widget.originalVideoUrl!)}: ${e.toString()}"),
              backgroundColor: theme.colorScheme.errorContainer,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
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
                  itemTypeDescription = l10n.unknownItemType ?? 'Unknown Type';
             }

             // Check if this lesson is the one we attempted to play locally
             final bool isAttemptedLocalVideo = isVideoTab && lesson.videoUrl != null && lesson.videoUrl == (_currentLesson?.videoUrl ?? 'none');


             return Card(
               // Highlight the video that corresponds to the one we *tried* to play locally
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
                    )
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
                         print("Tapped the currently playing/attempted video lesson: ${lesson.title}");
                          // If the video failed, maybe tapping it again triggers the retry button on the main screen?
                          if (videoError) {
                            initializeVideo(widget.videoPath); // Retry playing the local file
                          }
                      } else {
                         print("Tapped a different video lesson: ${lesson.title}. Playing other downloaded videos from this list requires additional logic (access to downloaded path).");
                         _showSnackbar(l10n.cannotPlayOtherVideoHere ?? 'Cannot play other videos from this list.');
                       }
                   } else {
                      // Handle taps for non-video lessons (notes, documents, quizzes etc.)
                       print("Tapped non-video lesson: ${lesson.title}. Implementing display/launch logic.");
                       if (lesson.lessonType == LessonType.text && lesson.summary != null && lesson.summary!.isNotEmpty) {
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
                           // Replicate or call a shared function for launching URLs
                            final urlToLaunch = lesson.attachmentUrl!;
                            // Example: Call a utility function like launchExternalUrl(context, urlToLaunch, lesson.title);
                           _showSnackbar("${lesson.lessonType.toString().split('.').last}: ${lesson.title} - URL: $urlToLaunch");
                       }
                        else if (lesson.lessonType == LessonType.quiz) {
                           _showSnackbar("${lesson.lessonType.toString().split('.').last}: ${lesson.title} (${l10n.notImplementedMessage})");
                       }
                         else {
                           _showSnackbar(l10n.noLaunchableContent(lesson.title));
                         }
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
     // Calculate height only if controller exists AND is initialized
     if (_controller != null && _controller!.value.isInitialized) {
        videoContainerHeight = MediaQuery.of(context).size.width / _controller!.value.aspectRatio;
     } else {
        // Default height when loading or error occurs
        videoContainerHeight = MediaQuery.of(context).size.width * (9/16); // Assume 16:9 aspect ratio if not initialized
     }


    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: _isFullscreen
            ? null
            : AppBar(
                title: Text(widget.videoTitle,
                    style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onPrimary)),
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
                            '${l10n.videoPlaybackError}: $errorMessage', // Show concise error message
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.error),
                          ),
                          const SizedBox(height: 20),
                          // Show retry button
                          ElevatedButton(
                             onPressed: isLoading ? null : () => initializeVideo(widget.videoPath), // Disable if already loading
                             child: Text(l10n.retry),
                          ),
                          // Add option to play original online if available
                          if (widget.originalVideoUrl != null && widget.originalVideoUrl!.isNotEmpty)
                             const SizedBox(height: 10),
                          if (widget.originalVideoUrl != null && widget.originalVideoUrl!.isNotEmpty)
                            TextButton.icon(
                               icon: Icon(Icons.open_in_browser, color: theme.colorScheme.primary),
                               label: Text(l10n.playOriginalOnline ?? 'Play Original Online'), // Assuming new key
                               onPressed: isLoading ? null : () => _launchOriginalUrl(context), // Disable if loading
                            ),
                        ],
                      ),
                    ),
                  )
                // Only build the video player section if the controller is initialized
                : (_controller != null && _controller!.value.isInitialized)
                    ? Column(
                          children: [
                             // Video player container
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

                                      VideoControlsOverlay(
                                        controller: _controller!,
                                      ),

                                      Positioned(
                                         bottom: 0, left: 0, right: 0,
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
                                         bottom: 40, // Adjust based on bottom control height
                                         left: 0, right: 0,
                                         child: VideoProgressIndicator(_controller!,
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
                                        Tab(text: l10n.otherItemsTabTitle ?? 'Other Content'),
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
                      // If not loading, not error, and controller isn't initialized, something is wrong.
                      // This state shouldn't ideally happen if initializeVideo is called in initState
                      // and error/loading states are handled. Could show a different message.
                      : Center(child: Text(l10n.unexpectedError ?? 'An unexpected error occurred.')), // Assuming new key
      ),
    );
  }
}