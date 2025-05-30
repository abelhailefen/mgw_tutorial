// lib/screens/video_controls_overlay.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoControlsOverlay extends StatefulWidget {
  final VideoPlayerController controller;

  const VideoControlsOverlay({
    super.key,
    required this.controller,
  });

  @override
  State<VideoControlsOverlay> createState() => _VideoControlsOverlayState();
}

class _VideoControlsOverlayState extends State<VideoControlsOverlay> {
  bool _controlsVisible = true;
  bool _isBuffering = false;

  @override
  void initState() {
    super.initState();
    // Listen only if the controller is initialized
    if (widget.controller.value.isInitialized) {
       widget.controller.addListener(_videoListener);
    } else {
      // Handle case where controller might not be initialized immediately
      // Although the parent should prevent this widget from building
      // if controller isn't ready, adding a listener might be safer
      // depending on exact parent build logic. For now, rely on parent check.
    }
    _hideControlsDelayed();
  }

  void _videoListener() {
    final isBuffering = widget.controller.value.isBuffering;
    if (_isBuffering != isBuffering) {
      setState(() {
        _isBuffering = isBuffering;
      });
    }
    if (widget.controller.value.isPlaying && _controlsVisible) {
         _hideControlsDelayed();
     }
  }

  @override
  void dispose() {
     if (widget.controller.value.isInitialized) { // Check before removing listener
       widget.controller.removeListener(_videoListener);
     }
     super.dispose();
  }

  void _toggleControlsVisibility() {
    setState(() {
      _controlsVisible = !_controlsVisible;
    });
    if (_controlsVisible && widget.controller.value.isPlaying) {
      _hideControlsDelayed();
    }
  }

  void _hideControlsDelayed() {
     // Cancel any existing timer if you implement that logic
     Future.delayed(const Duration(seconds: 3), () {
       if (mounted && _controlsVisible && widget.controller.value.isPlaying) {
         setState(() {
           _controlsVisible = false;
         });
       }
     });
  }

  @override
  Widget build(BuildContext context) {
     // The parent widget (VideoPlayerScreen) is responsible for ensuring
     // controller.value.isInitialized is true before building this widget.
     // So, we can safely access controller.value here.

    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleControlsVisibility,
        child: AnimatedOpacity(
          opacity: _controlsVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: _isBuffering
                  ? CircularProgressIndicator(color: Theme.of(context).colorScheme.secondary)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.replay_10, size: 40, color: Colors.white),
                          onPressed: () {
                            final position = widget.controller.value.position - const Duration(seconds: 10);
                            widget.controller.seekTo(position < Duration.zero ? Duration.zero : position);
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            widget.controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                            size: 80,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            widget.controller.value.isPlaying
                                ? widget.controller.pause()
                                : widget.controller.play();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.forward_10, size: 40, color: Colors.white),
                          onPressed: () {
                            final position = widget.controller.value.position + const Duration(seconds: 10);
                             final duration = widget.controller.value.duration;
                             widget.controller.seekTo(position > duration ? duration : position);
                          },
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}