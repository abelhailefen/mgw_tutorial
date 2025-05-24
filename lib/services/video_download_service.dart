// lib/services/video_download_service.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
// Removed permission_handler import as it's not used in the download logic itself
// but should be handled by the UI before calling download.
// import 'package:permission_handler/permission_handler.dart';
import 'database_helper.dart'; // Import your DatabaseHelper

class VideoDownloadService {
  final YoutubeExplode _ytExplode = YoutubeExplode();
  final Dio _dio = Dio();
  final DatabaseHelper _dbHelper = DatabaseHelper(); // Instance of DatabaseHelper

  final Map<String, ValueNotifier<double>> _downloadProgressNotifiers = {};
  final Map<String, ValueNotifier<DownloadStatus>> _downloadStatusNotifiers = {};
  // _isVideoOnlyDownload map is no longer needed here, DB will be source of truth.

  ValueNotifier<double> getDownloadProgress(String videoId) {
    _downloadProgressNotifiers.putIfAbsent(videoId, () => ValueNotifier(0.0));
    return _downloadProgressNotifiers[videoId]!;
  }

  ValueNotifier<DownloadStatus> getDownloadStatus(String videoId) {
    _downloadStatusNotifiers.putIfAbsent(videoId, () => ValueNotifier(DownloadStatus.notDownloaded));
    // Initialize status from DB if not already set by an active download
    if (_downloadStatusNotifiers[videoId]?.value == DownloadStatus.notDownloaded) {
      _dbHelper.isVideoDownloadedInDb(videoId).then((isDownloaded) {
        if (isDownloaded && _downloadStatusNotifiers[videoId]?.value == DownloadStatus.notDownloaded) {
           // Check again to avoid race condition if download started in between
          _downloadStatusNotifiers[videoId]?.value = DownloadStatus.downloaded;
          _downloadProgressNotifiers[videoId]?.value = 1.0; // Assume 100% if in DB
        }
      });
    }
    return _downloadStatusNotifiers[videoId]!;
  }

  Future<bool> isVideoDownloadedAsVideoOnly(String videoId) async {
    final downloadedVideo = await _dbHelper.getDownloadedVideo(videoId);
    return downloadedVideo?.isVideoOnly ?? false;
  }

  Future<String?> getAppSpecificVideoDirectory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final videoDir = Directory('${directory.path}/videos');
      if (!await videoDir.exists()) {
        await videoDir.create(recursive: true);
      }
      return videoDir.path;
    } catch (e) {
      print("Error getting video directory: $e");
      return null;
    }
  }

  Future<String?> _generateFilePath(String videoId, String videoTitle, {bool isVideoOnly = false}) async {
    final dirPath = await getAppSpecificVideoDirectory();
    if (dirPath == null) return null;
    String safeTitle = videoTitle.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
    if (safeTitle.isEmpty) safeTitle = videoId;
    String extension = ".mp4"; // Keep .mp4 for both
    String suffix = isVideoOnly ? "_video_only" : ""; // Filename suffix distinction
    return '$dirPath/${safeTitle}_$videoId$suffix$extension';
  }

  Future<File?> downloadYoutubeVideo(String videoUrl, String videoTitle, {
    Function(String videoId, double progress)? onProgress,
    // isVideoOnly in onStatusChange indicates the type of stream being ATTEMPTED or SUCCEEDED
    Function(String videoId, DownloadStatus status, String? filePath, bool isVideoOnlyAttempt)? onStatusChange,
  }) async {
    final String? videoId = VideoId.parseVideoId(videoUrl);

    if (videoId == null) {
      print("Invalid YouTube URL, cannot extract Video ID: $videoUrl");
      onStatusChange?.call(videoUrl, DownloadStatus.failed, null, false);
      return null;
    }

    final progressNotifier = getDownloadProgress(videoId); // This will also trigger DB check for initial status
    final statusNotifier = getDownloadStatus(videoId);

    // Check if already downloaded via DB
    final existingDownload = await _dbHelper.getDownloadedVideo(videoId);
    if (existingDownload != null) {
      if (await File(existingDownload.filePath).exists()) {
        print("Video already downloaded (from DB): ${existingDownload.filePath} (videoOnly: ${existingDownload.isVideoOnly})");
        statusNotifier.value = DownloadStatus.downloaded;
        progressNotifier.value = 1.0;
        onStatusChange?.call(videoId, DownloadStatus.downloaded, existingDownload.filePath, existingDownload.isVideoOnly);
        return File(existingDownload.filePath);
      } else {
        // File path in DB but file doesn't exist on disk - corrupted state
        print("DB record exists for $videoId but file not found at ${existingDownload.filePath}. Deleting DB record.");
        await _dbHelper.deleteDownloadedVideo(videoId);
        // Proceed to download
      }
    }
    
    // If an active download is in progress for this videoId, don't start another one.
    // This check is a bit simplistic. A more robust solution might involve a download queue or managing a set of active download IDs.
    if (statusNotifier.value == DownloadStatus.downloading) {
        print("Download already in progress for $videoId.");
        // onStatusChange?.call(videoId, DownloadStatus.downloading, null, false); // Or current attempt type
        return null; // Or return a future that completes when the current download finishes.
    }


    String? finalFilePath; // The path where the file will be saved
    bool decidedIsVideoOnly = false;

    try {
      statusNotifier.value = DownloadStatus.downloading;
      // Initial onStatusChange, type of attempt is not yet known for sure for fallback
      onStatusChange?.call(videoId, DownloadStatus.downloading, null, false);
      progressNotifier.value = 0.0;

      print("Attempting to get manifest for video ID: $videoId (from URL: $videoUrl)");
      var manifest = await _ytExplode.videos.streamsClient.getManifest(videoId);
      
      StreamInfo? streamInfo;
      String downloadTypeMessage = "muxed (video+audio)";

      if (manifest.muxed.isNotEmpty) {
        streamInfo = manifest.muxed.withHighestBitrate();
        decidedIsVideoOnly = false;
      } else if (manifest.videoOnly.isNotEmpty) {
        print("No muxed streams found. Falling back to video-only stream for $videoId.");
        streamInfo = manifest.videoOnly.withHighestBitrate();
        decidedIsVideoOnly = true;
        downloadTypeMessage = "video-only (no audio)";
        // Update onStatusChange as we now know the attempt type
        onStatusChange?.call(videoId, DownloadStatus.downloading, null, true);
      } else {
        print("No muxed or video-only streams found for $videoId.");
        // streamInfo remains null
      }

      if (streamInfo == null) {
        print("No suitable stream (muxed or video-only) found for $videoId. Cannot download.");
        statusNotifier.value = DownloadStatus.failed;
        onStatusChange?.call(videoId, DownloadStatus.failed, "No downloadable stream found.", decidedIsVideoOnly);
        return null;
      }

      finalFilePath = await _generateFilePath(videoId, videoTitle, isVideoOnly: decidedIsVideoOnly);
      if (finalFilePath == null) {
          statusNotifier.value = DownloadStatus.failed;
          onStatusChange?.call(videoId, DownloadStatus.failed, "Failed to determine file path.", decidedIsVideoOnly);
          return null;
      }

      print('Downloading ($downloadTypeMessage): ${streamInfo.url} to $finalFilePath');
      print('File size: ${streamInfo.size}');

      await _dio.download(
        streamInfo.url.toString(),
        finalFilePath, // Save to the determined path
        onReceiveProgress: (received, total) {
          if (total != -1) {
            double currentProgress = received / total;
            progressNotifier.value = currentProgress;
            onProgress?.call(videoId, currentProgress);
          }
        },
        deleteOnError: true, // Dio will delete the file if an error occurs during download
      );

      print("Download complete for $videoId ($downloadTypeMessage): $finalFilePath");
      
      // Save to Database
      final downloadedVideoEntry = DownloadedVideo(
          videoId: videoId,
          title: videoTitle,
          filePath: finalFilePath,
          isVideoOnly: decidedIsVideoOnly,
          downloadedAt: DateTime.now(),
      );
      await _dbHelper.insertOrUpdateDownloadedVideo(downloadedVideoEntry);

      statusNotifier.value = DownloadStatus.downloaded;
      onStatusChange?.call(videoId, DownloadStatus.downloaded, finalFilePath, decidedIsVideoOnly);
      return File(finalFilePath);

    } catch (e, s) {
      print("====== VIDEO DOWNLOAD SERVICE ERROR ======");
      print("Error occurred while trying to download video ID: $videoId (from URL: $videoUrl)");
      print("File path target (might be null if error before filePath assignment): $finalFilePath");
      print("Exception type: ${e.runtimeType}");
      print("Exception details: $e");
      print("Stack trace: $s");
      print("========================================");

      statusNotifier.value = DownloadStatus.failed;
      onStatusChange?.call(videoId, DownloadStatus.failed, e.toString(), decidedIsVideoOnly); // Use decidedIsVideoOnly

      // No need to manually delete file if dio's deleteOnError is true and error was from dio.
      // However, if the error was before dio.download or after, we might need to clean up.
      // Since deleteOnError is true, we assume dio handles its own partial files.
      // If finalFilePath was determined and file exists (e.g. error after download but before DB write), then delete.
      if (finalFilePath != null && await File(finalFilePath).exists()) {
          try {
              await File(finalFilePath).delete();
              print("Cleaned up file $finalFilePath due to error after potential creation.");
          } catch (deleteErr) {
              print("Error cleaning up file $finalFilePath: $deleteErr");
          }
      }
      return null;
    } finally {
      // Final status updates based on the outcome
      if (statusNotifier.value == DownloadStatus.downloaded) {
        progressNotifier.value = 1.0;
      } else if (statusNotifier.value == DownloadStatus.failed) {
         if (progressNotifier.value != 0.0) {
            progressNotifier.value = 0.0;
         }
      } else if (statusNotifier.value == DownloadStatus.downloading) {
        // This case means an error occurred that wasn't caught and set to failed,
        // or the download was cancelled externally.
        print("WARNING: Download status is still 'downloading' in finally block for $videoId. Setting to failed.");
        statusNotifier.value = DownloadStatus.failed;
        if (progressNotifier.value != 0.0) progressNotifier.value = 0.0;
      }
    }
  }

  Future<bool> isVideoDownloaded(String videoId) async {
    // Primary check from DB
    return _dbHelper.isVideoDownloadedInDb(videoId);
  }

  Future<String?> getActualDownloadedFilePath(String videoId) async {
    final downloadedVideo = await _dbHelper.getDownloadedVideo(videoId);
    return downloadedVideo?.filePath;
  }

  Future<void> deleteDownloadedVideo(String videoId, String videoTitle /* For filename generation if needed, or just use videoId */) async {
    final downloadedVideo = await _dbHelper.getDownloadedVideo(videoId);
    if (downloadedVideo != null) {
      final file = File(downloadedVideo.filePath);
      try {
        if (await file.exists()) {
          await file.delete();
          print("File deleted: ${downloadedVideo.filePath}");
        } else {
          print("File not found for deletion, but DB record existed: ${downloadedVideo.filePath}");
        }
      } catch (e) {
        print("Error deleting file ${downloadedVideo.filePath}: $e");
        // Decide if you still want to delete DB record or not
      }
      await _dbHelper.deleteDownloadedVideo(videoId);
    } else {
        print("No DB record found to delete for videoId: $videoId");
        // Fallback: try to delete files based on generated names if no DB record (cleanup old files)
        String? muxedPath = await _generateFilePath(videoId, videoTitle, isVideoOnly: false);
        if (muxedPath != null && await File(muxedPath).exists()) await File(muxedPath).delete();
        String? videoOnlyPath = await _generateFilePath(videoId, videoTitle, isVideoOnly: true);
        if (videoOnlyPath != null && await File(videoOnlyPath).exists()) await File(videoOnlyPath).delete();
    }
    // Update notifiers
    getDownloadStatus(videoId).value = DownloadStatus.notDownloaded;
    getDownloadProgress(videoId).value = 0.0;
  }

  Future<List<DownloadedVideo>> getAllDownloadedVideosFromDb() async {
    return _dbHelper.getAllDownloadedVideos();
  }

  void dispose() {
    // _ytExplode.close(); // YoutubeExplode has no close method anymore since v2.0.0
    _downloadProgressNotifiers.forEach((_, notifier) => notifier.dispose());
    _downloadStatusNotifiers.forEach((_, notifier) => notifier.dispose());
    _downloadProgressNotifiers.clear();
    _downloadStatusNotifiers.clear();
    // Database itself is a singleton and doesn't need explicit closing here,
    // but if you had a non-singleton DB connection, you'd close it.
  }
}

// enum DownloadStatus remains the same
enum DownloadStatus {
  notDownloaded,
  downloading,
  downloaded,
  failed,
}