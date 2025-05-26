// lib/services/video_download_service.dart
import 'dart:io'; // <--- ADD THIS IMPORT
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart'; // Direct import without alias
import 'package:permission_handler/permission_handler.dart';

// Import DownloadStatus enum - Ensure this file exists at lib/utils/download_status.dart
import 'package:mgw_tutorial/utils/download_status.dart';

class VideoDownloadService {
  final YoutubeExplode _ytExplode = YoutubeExplode();
  final Dio _dio = Dio();

  // Using CancelToken per download allows cancelling specific downloads
  final Map<String, CancelToken> _cancelTokens = {};

  // To store download progress (video_id: progress_value)
  final Map<String, ValueNotifier<double>> _downloadProgressNotifiers = {};
  // To store download status (video_id: status_enum or bool)
  final Map<String, ValueNotifier<DownloadStatus>> _downloadStatusNotifiers = {};

  // Helper to get progress notifier, initializes if needed
  ValueNotifier<double> getDownloadProgress(String videoId) {
    return _downloadProgressNotifiers.putIfAbsent(videoId, () => ValueNotifier(0.0));
  }

  // Helper to get status notifier, initializes if needed, and triggers initial disk check
  ValueNotifier<DownloadStatus> getDownloadStatus(String videoId) {
    if (!_downloadStatusNotifiers.containsKey(videoId)) {
      final notifier = ValueNotifier(DownloadStatus.notDownloaded);
      _downloadStatusNotifiers[videoId] = notifier;
      // The initial disk check needs the video title, which the provider has.
      // It's better that the provider calls checkAndSetInitialDownloadStatus after fetching lessons.
      // This getter just ensures the notifier object exists for the UI.
    }
    return _downloadStatusNotifiers[videoId]!;
  }

   // This method is called by the Provider after fetching lessons
   // to set the initial status based on file existence.
  Future<void> checkAndSetInitialDownloadStatus(String videoId, String videoTitle) async {
       final isDownloaded = await isVideoDownloaded(videoId, videoTitle); // Checks file existence

       // Get notifiers (ensuring they exist)
       final statusNotifier = getDownloadStatus(videoId);
       final progressNotifier = getDownloadProgress(videoId);

       // Only update if the current status is not already downloading or cancelled
       if (statusNotifier.value != DownloadStatus.downloading && statusNotifier.value != DownloadStatus.cancelled) {
            if (isDownloaded) {
              if (statusNotifier.value != DownloadStatus.downloaded) {
                  print("Service: Initial status set to downloaded for $videoId (file found)");
                  statusNotifier.value = DownloadStatus.downloaded;
                  progressNotifier.value = 1.0; // Ensure progress is 100%
              }
            } else {
              // If file doesn't exist, status should NOT be downloaded
                if (statusNotifier.value == DownloadStatus.downloaded) {
                   print("Service: Initial status reset to notDownloaded for $videoId (file not found)");
                   statusNotifier.value = DownloadStatus.notDownloaded;
                   progressNotifier.value = 0.0; // Reset progress
                } else if (statusNotifier.value != DownloadStatus.notDownloaded && statusNotifier.value != DownloadStatus.failed){
                     // Reset to notDownloaded if it was in some other temporary state unexpectedly
                     statusNotifier.value = DownloadStatus.notDownloaded;
                     progressNotifier.value = 0.0;
                }
            }
       }
  }


  Future<bool> _requestPermissions() async {
    // For app-specific directory (getApplicationDocumentsDirectory), permissions
    // are often not strictly needed on modern OS versions (Android 10+ / Scoped Storage)
    // unless targeting older Android versions or storing in shared locations.
    // Request storage permission on Android
    if (Platform.isAndroid) {
        // Consider checking and requesting MANAGE_EXTERNAL_STORAGE if targeting Android 11+
        // and saving outside app-specific directories.
        // For getApplicationDocumentsDirectory, this might not be strictly necessary.
        final status = await Permission.storage.request();
        return status.isGranted;
    }
    // On iOS, getApplicationDocumentsDirectory does not require extra permission requests
     return true; // Assume permissions are handled by OS on other platforms
  }


  Future<String?> getAppSpecificVideoDirectory() async {
    try {
      // Using getApplicationDocumentsDirectory for files that shouldn't be user-visible easily
      final directory = await getApplicationDocumentsDirectory();
      final videoDir = Directory('${directory.path}/videos'); // Use Directory from dart:io
      if (!await videoDir.exists()) {
        await videoDir.create(recursive: true);
      }
      return videoDir.path;
    } catch (e) {
      print("Error getting video directory: $e");
      return null;
    }
  }

  // Helper to get the expected file path including the file extension
  // This is used to *predict* the path where a file *might* be or *will* be saved.
   Future<String?> _buildExpectedFilePath(String videoId, String videoTitle, String extension) async {
       final dirPath = await getAppSpecificVideoDirectory();
       if (dirPath == null) return null;

       // Sanitize title to create a valid filename (remove invalid characters, replace spaces)
       String safeTitle = videoTitle.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(RegExp(r'\s+'), '_');
        // Trim or limit length if titles are very long
        if (safeTitle.length > 50) safeTitle = safeTitle.substring(0, 50);

       if (safeTitle.isEmpty) safeTitle = "video"; // Fallback if title becomes empty

       // Use videoId to guarantee uniqueness and include the extension
       return '$dirPath/${safeTitle}_$videoId.$extension';
   }

   // Method exposed to Provider to get the path of an *already downloaded* file.
   // This needs to check common extensions if the exact saved extension isn't stored.
   Future<String?> getDownloadedFilePath(String videoId, String videoTitle) async {
        List<String> potentialExtensions = ['mp4', 'webm']; // Check common muxed extensions
         final dirPath = await getAppSpecificVideoDirectory();
         if (dirPath == null) return null;

        String safeTitle = videoTitle.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(RegExp(r'\s+'), '_');
        if (safeTitle.length > 50) safeTitle = safeTitle.substring(0, 50);
        if (safeTitle.isEmpty) safeTitle = "video";

       for (var ext in potentialExtensions) {
           final filePath = '$dirPath/${safeTitle}_$videoId.$ext';
           if (await File(filePath).exists()) { // Use File from dart:io
               print("Found downloaded file for $videoId at $filePath");
               return filePath; // Return the path of the first existing file found
           }
       }
       print("No downloaded file found for $videoId with checked extensions in $dirPath");
       return null; // No matching file found with any checked extension
   }


  Future<bool> downloadYoutubeVideo(String videoUrl, String videoTitle) async {
    // Corrected: Call parseVideoId on VideoId class
    final videoIdObj = VideoId.parseVideoId(videoUrl);
    if (videoIdObj == null) {
      print("Invalid YouTube URL: $videoUrl");
      // We don't have a videoId string to track state with.
      // Could use the lesson.id as a fallback key if needed, but requires refactoring.
      // For now, just indicate failure.
      return false;
    }
     final videoId = videoIdObj; // videoIdObj is already a String

    // Get notifiers (creates them if they don't exist)
    final progressNotifier = getDownloadProgress(videoId);
    final statusNotifier = getDownloadStatus(videoId);

     // Check if already downloading or downloaded to prevent duplicate starts
     if (statusNotifier.value == DownloadStatus.downloading) {
         print("Download already in progress for $videoId");
         return false; // Indicate download wasn't started (already running)
     }
     if (statusNotifier.value == DownloadStatus.downloaded) {
         print("Video already downloaded: $videoId");
          progressNotifier.value = 1.0; // Ensure progress is 100%
         return true; // Indicate already downloaded
     }


    // Request permissions (optional but good practice depending on storage location)
    if (!await _requestPermissions()) {
       print("Storage permission denied for $videoId");
       statusNotifier.value = DownloadStatus.failed;
       return false;
     }


    final cancelToken = CancelToken();
    _cancelTokens[videoId] = cancelToken; // Store token

    // Define filePath variable outside try block so it's accessible in catch
    String? expectedFilePathDuringDownload; // Use a variable for the path being targeted

    try {
      statusNotifier.value = DownloadStatus.downloading;
      progressNotifier.value = 0.0;
      print("Starting download for $videoId");

      var manifest = await _ytExplode.videos.streamsClient.getManifest(videoIdObj); // Use VideoId object here
      // Get the muxed stream with the highest video quality.
      // You might want to offer quality selection to the user.
      var streamInfo = manifest.muxed.withHighestBitrate(); // Or use .first for smallest bitrate if smaller size preferred

      if (streamInfo == null) {
        print("No suitable muxed stream found for $videoId");
        statusNotifier.value = DownloadStatus.failed;
         _cancelTokens.remove(videoId); // Clean up token on failure
        return false;
      }

      // Get the target file path using the actual container extension from the stream
       expectedFilePathDuringDownload = await _buildExpectedFilePath(videoId, videoTitle, streamInfo.container.name);
        if (expectedFilePathDuringDownload == null) {
           print("Could not determine file path with extension for $videoId");
           statusNotifier.value = DownloadStatus.failed;
            _cancelTokens.remove(videoId);
           return false;
        }

      print('Downloading: ${streamInfo.url} to $expectedFilePathDuringDownload');
      print('File size: ${streamInfo.size}');

      await _dio.download(
        streamInfo.url.toString(),
        expectedFilePathDuringDownload,
        cancelToken: cancelToken, // Pass the cancel token
        onReceiveProgress: (received, total) {
          if (total != -1) {
            double currentProgress = received / total;
            // Safely update notifier value
             if (_downloadProgressNotifiers.containsKey(videoId)) {
                 _downloadProgressNotifiers[videoId]!.value = currentProgress;
             }
          }
        },
        deleteOnError: true, // Delete partially downloaded file on error
      );

      print("Download complete for $videoId: $expectedFilePathDuringDownload");
      // Safely update status notifier value
      if (_downloadStatusNotifiers.containsKey(videoId)) {
         _downloadStatusNotifiers[videoId]!.value = DownloadStatus.downloaded;
      }
       // Ensure progress is 100% on success
       if (_downloadProgressNotifiers.containsKey(videoId)) {
          _downloadProgressNotifiers[videoId]!.value = 1.0;
       }

      _cancelTokens.remove(videoId); // Remove token on success
      return true;

    } on DioException catch (e) {
       _cancelTokens.remove(videoId); // Always remove token after download attempt finishes

      if (CancelToken.isCancel(e)) {
         print("Download cancelled for $videoId: ${e.message}");
          if (_downloadStatusNotifiers.containsKey(videoId)) {
              _downloadStatusNotifiers[videoId]!.value = DownloadStatus.cancelled;
          }
          if (_downloadProgressNotifiers.containsKey(videoId)) {
             _downloadProgressNotifiers[videoId]!.value = 0.0; // Reset progress on cancellation
          }
         // Attempt to delete partial file on cancellation
         if (expectedFilePathDuringDownload != null && File(expectedFilePathDuringDownload).existsSync()) {
            try { await File(expectedFilePathDuringDownload).delete(); } catch (_) {
                 print("Error deleting partial file $expectedFilePathDuringDownload after cancellation: $_");
            }
         }
         return false; // Indicate cancellation
      } else {
         print("Dio Error downloading video $videoId: $e");
         print(e.response?.statusCode);
         print(e.response?.data);

         if (_downloadStatusNotifiers.containsKey(videoId)) {
            statusNotifier.value = DownloadStatus.failed; // Use the notifier variable
         }
         if (_downloadProgressNotifiers.containsKey(videoId)) {
            progressNotifier.value = 0.0; // Use the notifier variable
         }
          // Attempt to delete partial file on error
         if (expectedFilePathDuringDownload != null && File(expectedFilePathDuringDownload).existsSync()) {
            try { await File(expectedFilePathDuringDownload).delete(); } catch (_) {
                 print("Error deleting partial file $expectedFilePathDuringDownload after Dio error: $_");
            }
         }
         return false; // Indicate failure
      }

    } catch (e,s) {
      _cancelTokens.remove(videoId); // Always remove token

      print("Generic Error downloading video $videoId: $e");
      print(s); // Print stack trace

       if (_downloadStatusNotifiers.containsKey(videoId)) {
            statusNotifier.value = DownloadStatus.failed; // Use notifier variable
       }
        if (_downloadProgressNotifiers.containsKey(videoId)) {
            progressNotifier.value = 0.0; // Use notifier variable
       }
        // Attempt to delete partial file on error
       if (expectedFilePathDuringDownload != null && File(expectedFilePathDuringDownload).existsSync()) {
          try { await File(expectedFilePathDuringDownload).delete(); } catch (_) {
               print("Error deleting partial file $expectedFilePathDuringDownload after generic error: $_");
          }
       }
      return false; // Indicate failure
    }
  }


  // Method to delete a downloaded video file and reset its status
  Future<bool> deleteDownloadedVideo(String videoId, String videoTitle) async {
      // Cancel any ongoing download for this ID if it somehow wasn't already
       if (_cancelTokens.containsKey(videoId) && !_cancelTokens[videoId]!.isCancelled) {
           _cancelTokens[videoId]!.cancel("Deleted by user");
           print("Cancelled download $videoId during deletion");
       }
       _cancelTokens.remove(videoId); // Remove token


      // Need to find the file regardless of its exact extension (.mp4, .webm, etc.)
      // A simple way is to try deleting common extensions associated with muxed streams.
      // A more robust way requires storing the exact path when downloaded.
      final dirPath = await getAppSpecificVideoDirectory();
      if (dirPath == null) {
         print("Could not get directory path to delete $videoId");
         // Reset state even if delete fails due to missing directory
         if (_downloadStatusNotifiers.containsKey(videoId)) {
             _downloadStatusNotifiers[videoId]!.value = DownloadStatus.notDownloaded;
         }
          if (_downloadProgressNotifiers.containsKey(videoId)) {
             _downloadProgressNotifiers[videoId]!.value = 0.0;
         }
         return false;
      }

      String safeTitle = videoTitle.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(RegExp(r'\s+'), '_');
       if (safeTitle.length > 50) safeTitle = safeTitle.substring(0, 50);
       if (safeTitle.isEmpty) safeTitle = "video";

      bool deleted = false;
      List<String> potentialExtensions = ['mp4', 'webm']; // Add other potential muxed extensions if needed

      for (var ext in potentialExtensions) {
          final filePath = '$dirPath/${safeTitle}_$videoId.$ext';
          final file = File(filePath); // Use File from dart:io
           if (await file.exists()) {
               try {
                 await file.delete();
                 print("Deleted file: $filePath");
                 deleted = true; // Mark as deleted if at least one file is removed
               } catch (e) {
                  print("Error deleting $filePath: $e");
                  // Keep deleted = false if primary deletion fails
               }
           }
      }


      // Reset status and progress notifiers regardless of whether file was found/deleted
      // This ensures the UI state is reset.
      if (_downloadStatusNotifiers.containsKey(videoId)) {
          _downloadStatusNotifiers[videoId]!.value = DownloadStatus.notDownloaded;
      }
       if (_downloadProgressNotifiers.containsKey(videoId)) {
          _downloadProgressNotifiers[videoId]!.value = 0.0;
      }


      return deleted; // Return true if at least one file was successfully deleted
  }


  Future<bool> isVideoDownloaded(String videoId, String videoTitle) async {
     final dirPath = await getAppSpecificVideoDirectory();
     if (dirPath == null) return false;

     String safeTitle = videoTitle.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(RegExp(r'\s+'), '_');
     if (safeTitle.length > 50) safeTitle = safeTitle.substring(0, 50);
     if (safeTitle.isEmpty) safeTitle = "video";

      List<String> potentialExtensions = ['mp4', 'webm']; // Check common muxed extensions

      for (var ext in potentialExtensions) {
          final filePath = '$dirPath/${safeTitle}_$videoId.$ext';
          if (await File(filePath).exists()) { // Use File from dart:io
              print("File found for $videoId with extension .$ext at $filePath");
              return true; // Found a matching file
          }
      }
      print("No file found for $videoId with checked extensions in $dirPath");
      return false; // No matching file found with any checked extension
  }

  void dispose() {
    print("VideoDownloadService dispose called");
    _ytExplode.close();
     // Cancel any remaining downloads when the service is disposed
    _cancelTokens.forEach((videoId, token) {
       if (!token.isCancelled) {
          token.cancel("Service disposing");
          print("Cancelled download $videoId during dispose");
       }
    });
    _cancelTokens.clear();

    // Dispose all ValueNotifiers
    _downloadProgressNotifiers.forEach((videoId, notifier) {
        print("Disposing progress notifier for $videoId"); notifier.dispose();
    });
    _downloadStatusNotifiers.forEach((videoId, notifier) {
        print("Disposing status notifier for $videoId"); notifier.dispose();
    });
    _downloadProgressNotifiers.clear();
    _downloadStatusNotifiers.clear();

  }
}

// Ensure DownloadStatus enum is defined in lib/utils/download_status.dart
// enum DownloadStatus {
//   notDownloaded,
//   downloading,
//   downloaded,
//   failed,
//   cancelled,
// }