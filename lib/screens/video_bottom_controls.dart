// lib/screens/video_bottom_controls.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoBottomControls extends StatelessWidget {
   final VideoPlayerController controller;
   final VoidCallback onMuteToggle;
   final bool isMuted;
   final Function(double) onSpeedChange;
   final double currentSpeed;
   final VoidCallback onZoomToggle;

   const VideoBottomControls({
      super.key,
      required this.controller,
      required this.onMuteToggle,
      required this.isMuted,
      required this.onSpeedChange,
      required this.currentSpeed,
      required this.onZoomToggle,
   });

   @override
   Widget build(BuildContext context) {
      final theme = Theme.of(context);

      // The parent widget (VideoPlayerScreen) is responsible for ensuring
      // controller.value.isInitialized is true before building this widget.
      // So, we can safely access controller.value here.

      return Container(
        color: Colors.black.withOpacity(0.2),
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          children: [
             // Current time
             ValueListenableBuilder(
               valueListenable: controller,
               builder: (context, VideoPlayerValue value, child) {
                   final position = value.position;
                   final duration = value.duration;
                   String formatDuration(Duration d) {
                      String twoDigits(int n) => n.toString().padLeft(2, '0');
                      final hours = twoDigits(d.inHours);
                      final minutes = twoDigits(d.inMinutes.remainder(60));
                      final seconds = twoDigits(d.inSeconds.remainder(60));
                      if (d.inHours > 0) {
                         return '$hours:$minutes:$seconds';
                      }
                      return '$minutes:$seconds';
                   }

                   final positionString = formatDuration(position);
                   final durationString = duration != null ? formatDuration(duration) : '--:--';


                   return Text('$positionString / $durationString', style: const TextStyle(color: Colors.white, fontSize: 12));
               },
             ),
            Expanded(
              child: Container(),
            ),
            // Controls aligned to the right
            IconButton(
              icon: Icon(
                isMuted ? Icons.volume_off : Icons.volume_up,
                size: 24, color: Colors.white,
              ),
              onPressed: onMuteToggle,
            ),
            PopupMenuButton<double>(
              onSelected: onSpeedChange,
              icon: const Icon(Icons.speed, color: Colors.white, size: 24),
              itemBuilder: (context) => [0.5, 1.0, 1.5, 2.0].map((speed) {
                return PopupMenuItem(
                  value: speed,
                  child: Text(
                    '${speed}x',
                    style: TextStyle(
                      fontWeight: speed == currentSpeed ? FontWeight.bold : FontWeight.normal,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                );
              }).toList(),
            ),
            IconButton(
              icon: const Icon( Icons.fullscreen, size: 24, color: Colors.white ),
              onPressed: onZoomToggle,
            ),
          ],
        ),
      );
   }
}