// lib/screens/notifications/blog_detail_screen.dart
import 'package:flutter/material.dart';
// Removed: import 'package:mgw_tutorial/l10n/app_localizations.dart'; // No longer needed if no localized text specific to comments/login
// Removed: import 'package:mgw_tutorial/widgets/login_modal.dart';
// Removed: import 'package:shared_preferences/shared_preferences.dart'; // No longer needed without login checks
import 'package:mgw_tutorial/constants/color.dart'; // CORRECTED: AppColors location
import 'package:mgw_tutorial/models/blog.dart'; // CORRECTED import path
// Removed: import 'package:mgw_tutorial/providers/comment_provider.dart';
// Removed: import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago; // Keep timeago if showing time in details (not currently)
import 'package:chewie/chewie.dart'; // chewie package available
import 'package:video_player/video_player.dart'; // video_player package available

class BlogDetailsScreen extends StatefulWidget {
  final Blog blog;
  const BlogDetailsScreen({required this.blog, super.key});

  @override
  State<BlogDetailsScreen> createState() => _BlogDetailsScreenState();
}

class _BlogDetailsScreenState extends State<BlogDetailsScreen> {
  // Removed: Comment/Reply controllers and state maps
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    // Initialize video player if media is MP4
    if (widget.blog.media != null &&
        widget.blog.media!.toLowerCase().endsWith('.mp4')) {
      _initializeVideoPlayer();
    }
  }

  void _initializeVideoPlayer() {
    final videoUrl = "https://usersservicefx.amtprinting19.com/${widget.blog.media}";
    _videoPlayerController = VideoPlayerController.network(videoUrl)
      ..initialize().then((_) {
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController!,
          autoPlay: false, // Don't auto-play on opening details
          looping: false,
           // Aspect ratio might need adjusting if video has different ratio
        );
        if (mounted) setState(() {}); // Trigger rebuild once initialized
      }).catchError((error) {
        debugPrint("Video initialization error for BlogDetailsScreen: $error");
        // Handle error display or state update
         _videoPlayerController?.dispose(); // Dispose on error
         _videoPlayerController = null; // Set to null
         _chewieController?.dispose(); // Dispose chewie
         _chewieController = null; // Set to null
         if (mounted) setState(() {}); // Trigger rebuild to show error state
      });
  }

  @override
  void dispose() {
    // Dispose video controllers
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    // Removed: Dispose comment/reply controllers
    super.dispose();
  }

  // Removed: _refreshComments, _checkLoginStatus, _handleAddComment, _handleAddReply methods

  @override
  Widget build(BuildContext context) {
    // Removed localization access if no localized strings are used on this simple screen
    // final local = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.blog.title,
            style: theme.appBarTheme.titleTextStyle),
        // Use theme colors or fallback to AppColors
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.primary, // AppColors found
      ),
      // Removed: ChangeNotifierProvider and Consumer for CommentProvider
      body: SingleChildScrollView( // Use SingleChildScrollView for the content
        padding: const EdgeInsets.all(16.0), // Add padding around content
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media Section (Image or Video Player)
            if (widget.blog.media != null) ...[
              widget.blog.media!.toLowerCase().endsWith('.mp4')
                  ? // If it's an MP4, display the Chewie player
                    _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: _chewieController!.videoPlayerController.value.aspectRatio,
                          child: Chewie(controller: _chewieController!),
                        )
                      : // Show loading or error state for video
                       Container(
                           height: 250, // Example height for video placeholder
                           color: Colors.black,
                           child: Center(
                               child: _videoPlayerController?.value.hasError ?? false
                                   ? const Icon(Icons.error, color: Colors.red, size: 60) // Show error icon
                                   : const CircularProgressIndicator.adaptive(valueColor: AlwaysStoppedAnimation<Color>(Colors.white54)), // Show loading indicator
                           ),
                        )
                  : // If not a video, display the image
                    Image.network(
                      "https://usersservicefx.amtprinting19.com/${widget.blog.media}",
                      fit: BoxFit.cover,
                      width: double.infinity, // Take full width
                      errorBuilder: (context, error, stackTrace) =>
                        Container( // Error placeholder for image
                           height: 250, // Example height
                           color: Colors.grey[300],
                           child: const Center(child: Icon(Icons.broken_image, size: 60, color: Colors.grey)),
                        ),
                    ),
            ],
             const SizedBox(height: 16.0), // Space between media and text

             // Blog/Notification Title (Optional, already in AppBar)
             // Text(
             //    widget.blog.title,
             //    style: theme.textTheme.headlineSmall?.copyWith(
             //      fontWeight: FontWeight.bold,
             //       color: theme.colorScheme.onSurface
             //    ),
             // ),
             // const SizedBox(height: 8.0),

             // Blog/Notification Body
            Text(widget.blog.body,
                style: theme.textTheme.bodyLarge), // Use theme bodyLarge

             const SizedBox(height: 16.0), // Space after body

             // Optional: Display notification type and date
             Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Text(
                      widget.blog.notificationType,
                       style: theme.textTheme.bodySmall?.copyWith(
                           fontStyle: FontStyle.italic,
                            color: Colors.grey[600]
                          ),
                   ),
                    Text(
                     timeago.format(DateTime.parse(widget.blog.createdAt)), // timeago.format is available
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                 ],
             ),


            // Removed: Likes and Comments Count Display
            // Removed: Comments List Section
            // Removed: Add Comment Input Field
          ],
        ),
      ),
    );
  }
}