import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoDownloadService {
  final YoutubeExplode _ytExplode = YoutubeExplode();
  final Dio _dio = Dio();

  final Map<String, ValueNotifier<double>> _downloadProgressNotifiers = {};
  final Map<String, ValueNotifier<DownloadStatus>> _downloadStatusNotifiers = {};
  // To track if a video was downloaded as video-only
  final Map<String, bool> _isVideoOnlyDownload = {};


  ValueNotifier<double> getDownloadProgress(String videoId) {
    _downloadProgressNotifiers.putIfAbsent(videoId, () => ValueNotifier(0.0));
    return _downloadProgressNotifiers[videoId]!;
  }

  ValueNotifier<DownloadStatus> getDownloadStatus(String videoId) {
    _downloadStatusNotifiers.putIfAbsent(videoId, () => ValueNotifier(DownloadStatus.notDownloaded));
    return _downloadStatusNotifiers[videoId]!;
  }

  bool isVideoDownloadedAsVideoOnly(String videoId) {
    return _isVideoOnlyDownload[videoId] ?? false;
  }


  Future<bool> _requestPermissions() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    return status.isGranted;
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

  // Modified to potentially include a suffix if video-only
  Future<String?> getFilePath(String videoId, String videoTitle, {bool isVideoOnly = false}) async {
    final dirPath = await getAppSpecificVideoDirectory();
    if (dirPath == null) return null;
    String safeTitle = videoTitle.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
    if (safeTitle.isEmpty) safeTitle = videoId;
    // Use .mp4 extension for video-only as well, as players can often handle it.
    // Or, you could use a more specific extension like .m4v if desired.
    // String extension = isVideoOnly ? ".m4v" : ".mp4"; // Example if you want different extension
    String extension = ".mp4";
    String suffix = isVideoOnly ? "_video_only" : "";
    return '$dirPath/${safeTitle}_$videoId$suffix$extension';
  }


  Future<File?> downloadYoutubeVideo(String videoUrl, String videoTitle, {
    Function(String videoId, double progress)? onProgress,
    Function(String videoId, DownloadStatus status, String? filePath, bool isVideoOnly)? onStatusChange, // Added isVideoOnly
  }) async {
    final String? videoId = VideoId.parseVideoId(videoUrl);

    if (videoId == null) {
      print("Invalid YouTube URL, cannot extract Video ID: $videoUrl");
      onStatusChange?.call(videoUrl, DownloadStatus.failed, null, false);
      return null;
    }

    final progressNotifier = getDownloadProgress(videoId);
    final statusNotifier = getDownloadStatus(videoId);

    // Check if already downloaded (consider video-only status for filename)
    // We need a more robust way to check if it's downloaded, considering both normal and video-only paths.
    // For now, let's assume a re-download if the exact type (muxed vs video-only) isn't known or differs.
    // A better approach would be to store the download type alongside the status.

    // Let's determine the preferred file path first by trying muxed.
    // The actual filePath will be determined after stream selection.
    String? filePath; // Will be set later
    bool decidedIsVideoOnly = false;


    // Initial check if a file exists (could be muxed or video_only from a previous attempt)
    // This part needs more robust logic if you want to avoid re-downloading if *any* version exists.
    // For simplicity now, we'll proceed and overwrite/create based on what stream we find.
    // A more complex check:
    // String potentialMuxedPath = await getFilePath(videoId, videoTitle, isVideoOnly: false);
    // String potentialVideoOnlyPath = await getFilePath(videoId, videoTitle, isVideoOnly: true);
    // if (potentialMuxedPath != null && await File(potentialMuxedPath).exists()) {
    //   filePath = potentialMuxedPath;
    //   _isVideoOnlyDownload[videoId] = false;
    // } else if (potentialVideoOnlyPath != null && await File(potentialVideoOnlyPath).exists()) {
    //   filePath = potentialVideoOnlyPath;
    //   _isVideoOnlyDownload[videoId] = true;
    // }
    // if (filePath != null) {
    //    print("Video already downloaded (${_isVideoOnlyDownload[videoId]! ? 'video-only' : 'muxed'}): $filePath");
    //    statusNotifier.value = DownloadStatus.downloaded;
    //    progressNotifier.value = 1.0;
    //    onStatusChange?.call(videoId, DownloadStatus.downloaded, filePath, _isVideoOnlyDownload[videoId]!);
    //    return File(filePath);
    // }


    try {
      statusNotifier.value = DownloadStatus.downloading;
      onStatusChange?.call(videoId, DownloadStatus.downloading, null, false); // Initially assume not video-only
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
        streamInfo = manifest.videoOnly.withHighestBitrate(); // Could also use .firstWhereOrNull for specific formats
        decidedIsVideoOnly = true;
        downloadTypeMessage = "video-only (no audio)";
        _isVideoOnlyDownload[videoId] = true;
        // Update status change callback if we've decided it's video-only now
        onStatusChange?.call(videoId, DownloadStatus.downloading, null, true);
      } else {
        print("No muxed or video-only streams found for $videoId.");
      }

      if (streamInfo == null) {
        print("No suitable stream (muxed or video-only) found for $videoId. Cannot download.");
        statusNotifier.value = DownloadStatus.failed;
        onStatusChange?.call(videoId, DownloadStatus.failed, "No downloadable stream found.", false);
        _isVideoOnlyDownload.remove(videoId);
        return null;
      }

      // Now determine the final filePath based on whether it's video-only
      filePath = await getFilePath(videoId, videoTitle, isVideoOnly: decidedIsVideoOnly);
      if (filePath == null) { // Should not happen if getAppSpecificVideoDirectory works
          statusNotifier.value = DownloadStatus.failed;
          onStatusChange?.call(videoId, DownloadStatus.failed, "Failed to determine file path.", decidedIsVideoOnly);
          _isVideoOnlyDownload.remove(videoId);
          return null;
      }
      // If a file with the *specific* decided name already exists, treat as downloaded
      if (await File(filePath).exists()){
          print("Video already downloaded as $downloadTypeMessage: $filePath");
          statusNotifier.value = DownloadStatus.downloaded;
          progressNotifier.value = 1.0;
          _isVideoOnlyDownload[videoId] = decidedIsVideoOnly; // Ensure this is set
          onStatusChange?.call(videoId, DownloadStatus.downloaded, filePath, decidedIsVideoOnly);
          return File(filePath);
      }


      print('Downloading ($downloadTypeMessage): ${streamInfo.url} to $filePath');
      print('File size: ${streamInfo.size}');

      await _dio.download(
        streamInfo.url.toString(),
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            double currentProgress = received / total;
            progressNotifier.value = currentProgress;
            onProgress?.call(videoId, currentProgress);
          }
        },
        deleteOnError: true,
      );

      print("Download complete for $videoId ($downloadTypeMessage): $filePath");
      statusNotifier.value = DownloadStatus.downloaded;
      _isVideoOnlyDownload[videoId] = decidedIsVideoOnly; // Store the type of download
      onStatusChange?.call(videoId, DownloadStatus.downloaded, filePath, decidedIsVideoOnly);
      return File(filePath);

    } catch (e, s) {
      print("====== VIDEO DOWNLOAD SERVICE ERROR ======");
      print("Error occurred while trying to download video ID: $videoId (from URL: $videoUrl)");
      print("File path target (might be null if error before filePath assignment): $filePath");
      print("Exception type: ${e.runtimeType}");
      print("Exception details: $e");
      print("Stack trace: $s");
      print("========================================");

      statusNotifier.value = DownloadStatus.failed;
      // If we had decided it's video only before error, reflect that. Otherwise, false.
      onStatusChange?.call(videoId, DownloadStatus.failed, e.toString(), _isVideoOnlyDownload[videoId] ?? false);
      _isVideoOnlyDownload.remove(videoId);


      if (filePath != null && await File(filePath).exists()) {
        try {
          await File(filePath).delete();
          print("Deleted partially downloaded or empty file due to error: $filePath");
        } catch (deleteError) {
          print("Error deleting partial file $filePath after download error: $deleteError");
        }
      }
      return null;
    } finally {
      if (statusNotifier.value == DownloadStatus.downloaded) {
        progressNotifier.value = 1.0;
      } else if (statusNotifier.value == DownloadStatus.failed) {
         if (progressNotifier.value != 0.0) {
            progressNotifier.value = 0.0;
         }
      }
      else if (statusNotifier.value == DownloadStatus.downloading) {
        print("WARNING: Download status is still 'downloading' in finally block. Setting to failed.");
        statusNotifier.value = DownloadStatus.failed;
        if (progressNotifier.value != 0.0) progressNotifier.value = 0.0;
        _isVideoOnlyDownload.remove(videoId); // Clear stale state
      }
    }
  }

  Future<bool> isVideoDownloaded(String videoId, String videoTitle) async {
    // This needs to check both possible filenames
    String? muxedPath = await getFilePath(videoId, videoTitle, isVideoOnly: false);
    if (muxedPath != null && await File(muxedPath).exists()) {
      _isVideoOnlyDownload[videoId] = false; // Update state if found
      return true;
    }
    String? videoOnlyPath = await getFilePath(videoId, videoTitle, isVideoOnly: true);
    if (videoOnlyPath != null && await File(videoOnlyPath).exists()) {
      _isVideoOnlyDownload[videoId] = true; // Update state if found
      return true;
    }
    return false;
  }

  // Helper to get the actual path of a downloaded video, considering its type
  Future<String?> getActualDownloadedFilePath(String videoId, String videoTitle) async {
    if (_isVideoOnlyDownload[videoId] == true) { // Check explicitly for true
        return getFilePath(videoId, videoTitle, isVideoOnly: true);
    }
    // Default to checking/returning muxed path, or if type is unknown/false
    return getFilePath(videoId, videoTitle, isVideoOnly: false);
  }


  void dispose() {
    _ytExplode.close();
    _downloadProgressNotifiers.forEach((_, notifier) => notifier.dispose());
    _downloadStatusNotifiers.forEach((_, notifier) => notifier.dispose());
    _downloadProgressNotifiers.clear();
    _downloadStatusNotifiers.clear();
    _isVideoOnlyDownload.clear();
  }
}

enum DownloadStatus {
  notDownloaded,
  downloading,
  downloaded,
  failed,
}