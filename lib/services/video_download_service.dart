//lib/services/video_download_service.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoDownloadService {
  final YoutubeExplode _ytExplode = YoutubeExplode();
  final Dio _dio = Dio();

  // To store download progress (video_id: progress_value)
  final Map<String, ValueNotifier<double>> _downloadProgressNotifiers = {};
  // To store download status (video_id: status_enum or bool)
  final Map<String, ValueNotifier<DownloadStatus>> _downloadStatusNotifiers = {};


  ValueNotifier<double> getDownloadProgress(String videoId) {
    _downloadProgressNotifiers.putIfAbsent(videoId, () => ValueNotifier(0.0));
    return _downloadProgressNotifiers[videoId]!;
  }

  ValueNotifier<DownloadStatus> getDownloadStatus(String videoId) {
    _downloadStatusNotifiers.putIfAbsent(videoId, () => ValueNotifier(DownloadStatus.notDownloaded));
    return _downloadStatusNotifiers[videoId]!;
  }


  Future<bool> _requestPermissions() async {
    // For app-specific directory, permissions are often not strictly needed on modern OS,
    // but asking can be good practice or required for broader access.
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    return status.isGranted;
  }

  Future<String?> getAppSpecificVideoDirectory() async {
    try {
      // Using getApplicationDocumentsDirectory for files that shouldn't be user-visible easily
      // Or getExternalStorageDirectory for more visible storage (requires more permission handling)
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

  Future<String?> getFilePath(String videoId, String videoTitle) async {
    final dirPath = await getAppSpecificVideoDirectory();
    if (dirPath == null) return null;
    // Sanitize title to create a valid filename
    String safeTitle = videoTitle.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
    if (safeTitle.isEmpty) safeTitle = videoId; // Fallback to videoId if title becomes empty
    return '$dirPath/${safeTitle}_$videoId.mp4'; // Ensure unique name with videoId
  }


  Future<File?> downloadYoutubeVideo(String videoUrl, String videoTitle, {
    Function(String videoId, double progress)? onProgress,
    Function(String videoId, DownloadStatus status, String? filePath)? onStatusChange,
  }) async {
    final videoId = YoutubeExplode.parseVideoId(videoUrl);
    if (videoId == null) {
      print("Invalid YouTube URL");
      onStatusChange?.call("", DownloadStatus.failed, null); // Use empty string if videoId is null
      return null;
    }

    // Initialize notifiers if they don't exist
    final progressNotifier = getDownloadProgress(videoId);
    final statusNotifier = getDownloadStatus(videoId);

    // Check if already downloaded (simple check, can be improved with database)
    String? filePath = await getFilePath(videoId, videoTitle);
    if (filePath == null) {
      statusNotifier.value = DownloadStatus.failed;
      onStatusChange?.call(videoId, DownloadStatus.failed, null);
      return null;
    }
    if (await File(filePath).exists()) {
      print("Video already downloaded: $filePath");
      statusNotifier.value = DownloadStatus.downloaded;
      onStatusChange?.call(videoId, DownloadStatus.downloaded, filePath);
      return File(filePath);
    }

    // Request permissions (optional for app-specific directory, but good for broader cases)
    // if (!await _requestPermissions()) {
    //   print("Storage permission denied");
    //   statusNotifier.value = DownloadStatus.failed;
    //   onStatusChange?.call(videoId, DownloadStatus.failed, null);
    //   return null;
    // }


    try {
      statusNotifier.value = DownloadStatus.downloading;
      onStatusChange?.call(videoId, DownloadStatus.downloading, null);
      progressNotifier.value = 0.0;

      var manifest = await _ytExplode.videos.streamsClient.getManifest(videoId);
      // Get the muxed stream with the highest video quality.
      // You might want to offer quality selection to the user.
      var streamInfo = manifest.muxed.withHighestBitrate(); // Or use .first for smallest

      if (streamInfo == null) {
        print("No suitable muxed stream found for $videoId");
        statusNotifier.value = DownloadStatus.failed;
        onStatusChange?.call(videoId, DownloadStatus.failed, null);
        return null;
      }

      print('Downloading: ${streamInfo.url} to $filePath');
      print('File size: ${streamInfo.size}');


      await _dio.download(
        streamInfo.url.toString(),
        filePath, // Temporary path during download
        onReceiveProgress: (received, total) {
          if (total != -1) {
            double currentProgress = received / total;
            progressNotifier.value = currentProgress;
            onProgress?.call(videoId, currentProgress);
            // print('Download progress for $videoId: ${(currentProgress * 100).toStringAsFixed(0)}%');
          }
        },
        deleteOnError: true, // Delete partially downloaded file on error
      );

      print("Download complete for $videoId: $filePath");
      statusNotifier.value = DownloadStatus.downloaded;
      onStatusChange?.call(videoId, DownloadStatus.downloaded, filePath);
      return File(filePath);

    } catch (e,s) {
      print("Error downloading video $videoId: $e");
      print(s);
      statusNotifier.value = DownloadStatus.failed;
      onStatusChange?.call(videoId, DownloadStatus.failed, null);
      // Attempt to delete partial file if error occurs after creation
      if (await File(filePath).exists()) {
        try {
          await File(filePath).delete();
        } catch (deleteError) {
          print("Error deleting partial file $filePath: $deleteError");
        }
      }
      return null;
    } finally {
       // Ensure progress is 100% if downloaded, or reset if failed and not already downloading
      if (statusNotifier.value == DownloadStatus.downloaded) {
        progressNotifier.value = 1.0;
      } else if (statusNotifier.value == DownloadStatus.failed) {
        progressNotifier.value = 0.0; // Reset progress on failure
      }
    }
  }

  Future<bool> isVideoDownloaded(String videoId, String videoTitle) async {
    final filePath = await getFilePath(videoId, videoTitle);
    if (filePath == null) return false;
    return await File(filePath).exists();
  }

  void dispose() {
    _ytExplode.close();
    // Dispose notifiers if they are not managed elsewhere (e.g., by the UI widgets directly)
    _downloadProgressNotifiers.forEach((_, notifier) => notifier.dispose());
    _downloadStatusNotifiers.forEach((_, notifier) => notifier.dispose());
    _downloadProgressNotifiers.clear();
    _downloadStatusNotifiers.clear();
  }
}

enum DownloadStatus {
  notDownloaded,
  downloading,
  downloaded,
  failed,
}