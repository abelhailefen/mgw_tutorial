// lib/screens/notifications/notification_list_view.dart
import 'package:flutter/material.dart';
import 'package:mgw_tutorial/constants/color.dart'; // CORRECTED: AppColors location
import 'package:mgw_tutorial/l10n/app_localizations.dart'; // Correct localization import
import 'package:mgw_tutorial/models/blog.dart'; // CORRECTED import path
import 'package:mgw_tutorial/provider/notification_provider.dart'; // CORRECTED: Path adjusted to 'provider'
import 'package:mgw_tutorial/screens/notifications/blog_detail_screen.dart'; // CORRECTED: Path adjusted to 'notifications'
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:timeago/timeago.dart'
    as timeago; // timeago package is available

class NotificationListView extends StatefulWidget {
  const NotificationListView({super.key});

  @override
  State<NotificationListView> createState() => _NotificationListViewState();
}

class _NotificationListViewState extends State<NotificationListView> {
  final Map<int, VideoPlayerController> _videoControllers = {};

  @override
  void dispose() {
    // Dispose all video controllers
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    super.dispose();
  }

  bool _isVideo(String? media) {
    if (media == null) return false;
    final lowerMedia = media.toLowerCase();
    return lowerMedia.endsWith('.mp4') ||
        lowerMedia.endsWith('.mov') ||
        lowerMedia.endsWith('.avi') ||
        lowerMedia.endsWith('.mkv');
  }

  Widget _buildVideoWithPlayIcon(String? mediaUrl, int blogId) {
    final videoUrl = "https://userservice.mgwcommunity.com/${mediaUrl ?? ''}";

    // Dispose and recreate controller if URL changes for the same ID (unlikely in a list, but good practice)
    // Or just always create if not exists.
    if (!_videoControllers.containsKey(blogId)) {
      _videoControllers[blogId] = VideoPlayerController.network(videoUrl)
        ..initialize().then((_) {
          // Optional setState here if the initial frame doesn't show or needs size update
          // if (mounted) setState(() {});
        }).catchError((error) {
          print("Error initializing video for blog $blogId: $error");
          _videoControllers.remove(blogId); // Remove controller on error
          if (mounted)
            setState(() {}); // Trigger rebuild to show error/placeholder
        });
    }

    final videoController = _videoControllers[blogId];

    if (videoController == null || !videoController.value.isInitialized) {
      // Show a loading indicator or a simple container until initialized or on error
      return Container(
        height: 180, // Consistent height
        color: Colors.black, // Dark background for video loading
        child: const Center(
          child: CircularProgressIndicator.adaptive(
              valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white54)), // White indicator over dark
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Display the first frame of the video
        AspectRatio(
          aspectRatio: videoController.value.aspectRatio,
          child: VideoPlayer(videoController),
        ),
        // Display play icon overlay
        const Center(
          child: Icon(
            Icons.play_circle_outline,
            size: 50,
            color: Colors.white70, // Slightly transparent white
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // Correct localization access
    final theme = Theme.of(context);

    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        if (notificationProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (notificationProvider.errorMessage != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text(
                    notificationProvider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: Colors.redAccent),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      notificationProvider.fetchNotifications();
                    },
                    child: Text(l10n.retry), // Localized key
                  )
                ],
              ),
            ),
          );
        }

        final notifications = notificationProvider.notifications;

        if (notifications.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 80,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.noNotificationsMessage, // Localized key
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => notificationProvider.fetchNotifications(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final isVideo = _isVideo(notification.media);

              return Card(
                elevation: 4.0,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: InkWell(
                  onTap: () {
                    // Navigate to BlogDetailsScreen, which will now only show media and text
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        // Pass the notification data using the Blog model structure
                        builder: (context) =>
                            BlogDetailsScreen(blog: notification),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Media section (Image or Video Preview)
                      if (notification.media != null)
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12.0),
                            topRight: Radius.circular(12.0),
                          ),
                          child: isVideo
                              ? _buildVideoWithPlayIcon(
                                  notification.media, notification.id)
                              : Image.network(
                                  "https://userservice.mgwcommunity.com/${notification.media}",
                                  height: 180, // Fixed height for list items
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    print(
                                        "Error loading image for blog ${notification.id}: $error");
                                    return Container(
                                      height: 180,
                                      color: Colors.grey[300],
                                      child: const Center(
                                        child: Icon(Icons.broken_image,
                                            size: 50, color: Colors.grey),
                                      ),
                                    );
                                  },
                                ),
                        )
                      else
                        Container(
                          height: 180, // Fixed height even if no media
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.image_not_supported,
                                size: 50, color: Colors.grey),
                          ),
                        ),

                      // Text content
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              notification.body,
                              style: theme.textTheme.bodyMedium,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              // Notification type and time
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  notification
                                      .notificationType, // Display the type
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey[600]),
                                ),
                                Text(
                                  timeago.format(DateTime.parse(notification
                                      .createdAt)), // timeago.format is available
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            // Removed Like/Comment row
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
