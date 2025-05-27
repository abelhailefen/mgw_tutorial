// lib/services/media_service.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../utils/download_status.dart';

class MediaService {
  static final _dio = Dio();
  static const _secureStorage = FlutterSecureStorage();
  static final Map<String, ValueNotifier<DownloadStatus>> _statusNotifiers = {};
  static final Map<String, ValueNotifier<double>> _progressNotifiers = {};
  static final Map<String, CancelToken> _cancelTokens = {};

  // Get or create status notifier
  static ValueNotifier<DownloadStatus> getDownloadStatus(String videoId) {
    return _statusNotifiers.putIfAbsent(
      videoId,
      () => ValueNotifier<DownloadStatus>(DownloadStatus.notDownloaded),
    );
  }

  // Get or create progress notifier
  static ValueNotifier<double> getDownloadProgress(String videoId) {
    return _progressNotifiers.putIfAbsent(
      videoId,
      () => ValueNotifier<double>(0.0),
    );
  }

  // Get the file path for storing the media
  static Future<String> _getFilePath(String id, String fileExtension) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$id.$fileExtension';
  }

  // Check if a file is already downloaded
  static Future<bool> isFileDownloaded(String id) async {
    try {
      final storedPath = await _secureStorage.read(key: id);
      print("Checking if file is downloaded for ID: $id, storedPath: $storedPath");
      if (storedPath != null) {
        final file = File(storedPath);
        final exists = file.existsSync();
        print("File exists: $exists for path: $storedPath");
        final statusNotifier = getDownloadStatus(id);
        if (exists && statusNotifier.value != DownloadStatus.downloaded) {
          statusNotifier.value = DownloadStatus.downloaded;
          getDownloadProgress(id).value = 1.0;
        } else if (!exists && statusNotifier.value == DownloadStatus.downloaded) {
          statusNotifier.value = DownloadStatus.notDownloaded;
          getDownloadProgress(id).value = 0.0;
        }
        return exists;
      }
      return false;
    } catch (e) {
      print("Error checking if file is downloaded for ID $id: $e");
      return false;
    }
  }

  // Download a YouTube video
  static Future<bool> downloadVideoFile({
    required String videoId,
    required String url,
    required String title,
    CancelToken? cancelToken,
  }) async {
    if (url.isEmpty) {
      print("Error: Empty video URL for $title");
      _updateStatus(videoId, DownloadStatus.failed);
      return false;
    }

    final yt = YoutubeExplode();
    final statusNotifier = getDownloadStatus(videoId);
    final progressNotifier = getDownloadProgress(videoId);
    final cancelToken = CancelToken();
    _cancelTokens[videoId] = cancelToken;

    try {
      statusNotifier.value = DownloadStatus.downloading;
      progressNotifier.value = 0.0;

      url = url.split(';').first;
      final video = await yt.videos.get(url);
      final cleanVideoId = video.id.value;

      final manifest = await yt.videos.streamsClient.getManifest(cleanVideoId,
          ytClients: [YoutubeApiClient.safari, YoutubeApiClient.androidVr]);

      if (manifest.muxed.isNotEmpty) {
        final muxedStream = manifest.muxed.withHighestBitrate();
        final videoFilePath = await _getFilePath(cleanVideoId, muxedStream.container.name);

        await _dio.download(
          muxedStream.url.toString(),
          videoFilePath,
          cancelToken: cancelToken,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              final progress = received / total;
              progressNotifier.value = progress;
            }
          },
        );

        await _secureStorage.write(key: cleanVideoId, value: videoFilePath);
        statusNotifier.value = DownloadStatus.downloaded;
        progressNotifier.value = 1.0;
        print("Video downloaded successfully for ID $cleanVideoId: $videoFilePath");
        return true;
      } else {
        statusNotifier.value = DownloadStatus.failed;
        progressNotifier.value = 0.0;
        print("No muxed streams available for ID $cleanVideoId");
        return false;
      }
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        statusNotifier.value = DownloadStatus.cancelled;
        progressNotifier.value = 0.0;
        print("Download cancelled for ID $videoId");
      } else {
        statusNotifier.value = DownloadStatus.failed;
        progressNotifier.value = 0.0;
        print("Error downloading video for ID $videoId: $e");
      }
      return false;
    } finally {
      yt.close();
      _cancelTokens.remove(videoId);
    }
  }

  // Cancel a download
  static void cancelDownload(String videoId) {
    final cancelToken = _cancelTokens[videoId];
    if (cancelToken != null && !cancelToken.isCancelled) {
      cancelToken.cancel('Download cancelled by user');
      _updateStatus(videoId, DownloadStatus.cancelled);
      _updateProgress(videoId, 0.0);
      _cancelTokens.remove(videoId);
    }
  }

  // Retrieve a file's local path
  static Future<String?> getSecurePath(String id) async {
    try {
      final path = await _secureStorage.read(key: id);
      return path;
    } catch (e) {
      print("Error retrieving secure path for ID $id: $e");
      return null;
    }
  }

  // Delete a downloaded file
  static Future<bool> deleteFile(String id, BuildContext context) async {
    try {
      final storedPath = await _secureStorage.read(key: id);
      if (storedPath != null) {
        final file = File(storedPath);
        if (await file.exists()) {
          await file.delete();
          print("File deleted successfully for ID: $id");
        }
        await _secureStorage.delete(key: id);
        _updateStatus(id, DownloadStatus.notDownloaded);
        _updateProgress(id, 0.0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.fileDeletedSuccessfully),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.fileNotFoundOrFailedToDelete),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return false;
      }
    } catch (e) {
      print("Error deleting file for ID $id: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.couldNotDeleteFileError}: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return false;
    }
  }

  // Retrieve all downloaded files
  static Future<Map<String, String>> getAllDownloadedFiles() async {
    try {
      final allEntries = await _secureStorage.readAll();
      final downloadedFiles = <String, String>{};

      for (var entry in allEntries.entries) {
        final file = File(entry.value);
        if (await file.exists()) {
          downloadedFiles[entry.key] = entry.value;
        } else {
          await _secureStorage.delete(key: entry.key);
          print("Removed stale secure storage entry for ID: ${entry.key}");
        }
      }

      return downloadedFiles;
    } catch (e) {
      print("Error retrieving downloaded files: $e");
      return {};
    }
  }

  // Helper to update status
  static void _updateStatus(String videoId, DownloadStatus status) {
    final notifier = getDownloadStatus(videoId);
    if (notifier.value != status) {
      notifier.value = status;
    }
  }

  // Helper to update progress
  static void _updateProgress(String videoId, double progress) {
    final notifier = getDownloadProgress(videoId);
    if (notifier.value != progress) {
      notifier.value = progress;
    }
  }

  // Clean up resources
  static void dispose() {
    for (var token in _cancelTokens.values) {
      token.cancel('Service disposed');
    }
    _cancelTokens.clear();
    for (var notifier in _statusNotifiers.values) {
      notifier.dispose();
    }
    for (var notifier in _progressNotifiers.values) {
      notifier.dispose();
    }
    _statusNotifiers.clear();
    _progressNotifiers.clear();
    _dio.close();
  }
}