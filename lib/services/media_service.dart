import 'dart:io';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../l10n/app_localizations.dart';
import '../utils/download_status.dart';

class MediaService {
  static final _dio = Dio();
  static const _secureStorage = FlutterSecureStorage();
  static final Map<String, ValueNotifier<DownloadStatus>> _statusNotifiers = {};
  static final Map<String, ValueNotifier<double>> _progressNotifiers = {};
  static final Map<String, CancelToken> _cancelTokens = {};

  static final Map<String, String> _fileExtensions = {};

  static ValueNotifier<DownloadStatus> getDownloadStatus(String id) {
    return _statusNotifiers.putIfAbsent(
      id,
      () => ValueNotifier<DownloadStatus>(DownloadStatus.notDownloaded),
    );
  }

  static ValueNotifier<double> getDownloadProgress(String id) {
    return _progressNotifiers.putIfAbsent(
      id,
      () => ValueNotifier<double>(0.0),
    );
  }

  static Future<String> _getFilePath(String id, String fileExtension) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/downloads/$id.$fileExtension';
    final fileDir = Directory(filePath).parent;
     if (!await fileDir.exists()) {
        await fileDir.create(recursive: true);
     }
    _fileExtensions[id] = fileExtension;
    return filePath;
  }

   static String? _getFileExtension(String id) {
       return _fileExtensions[id];
   }

  static Future<bool> isFileDownloaded(String id) async {
    try {
      final storedPath = await _secureStorage.read(key: id);

      if (storedPath != null && storedPath.isNotEmpty) {
        final file = File(storedPath);
        final exists = await file.exists();
        final statusNotifier = getDownloadStatus(id);

        if (exists) {
           if (!_fileExtensions.containsKey(id)) {
               final parts = storedPath.split('.');
               if (parts.isNotEmpty) {
                   _fileExtensions[id] = parts.last;
               }
           }

          if (statusNotifier.value != DownloadStatus.downloaded) {
            statusNotifier.value = DownloadStatus.downloaded;
            getDownloadProgress(id).value = 1.0;
             debugPrint("MediaService: File found for ID $id, status set to downloaded.");
          }
          return true;
        } else {
          debugPrint("MediaService: Stale secure storage entry found for ID $id. File not found at $storedPath. Cleaning up secure storage and resetting status.");
          await _secureStorage.delete(key: id);
          _fileExtensions.remove(id);
          statusNotifier.value = DownloadStatus.notDownloaded;
          getDownloadProgress(id).value = 0.0;
          return false;
        }
      } else {
         final statusNotifier = getDownloadStatus(id);
          if (statusNotifier.value == DownloadStatus.downloaded) {
            statusNotifier.value = DownloadStatus.notDownloaded;
            getDownloadProgress(id).value = 0.0;
             debugPrint("MediaService: No secure storage entry for ID $id, but status was downloaded. Resetting status.");
          }
          _fileExtensions.remove(id);
         return false;
      }
    } catch (e, s) {
       debugPrint("MediaService: Error checking file download status for ID $id: $e\n$s");
      getDownloadStatus(id).value = DownloadStatus.notDownloaded;
      getDownloadProgress(id).value = 0.0;
      _fileExtensions.remove(id);
      return false;
    }
  }


  static Future<bool> downloadVideoFile({
    required String videoId,
    required String url,
    required String title,
  }) async {
    if (url.isEmpty) {
      _updateStatus(videoId, DownloadStatus.failed);
      debugPrint("MediaService: Video download failed for ID $videoId. URL is empty.");
      return false;
    }

    final statusNotifier = getDownloadStatus(videoId);

     if (statusNotifier.value == DownloadStatus.downloaded) {
       debugPrint("MediaService: Video already downloaded for ID $videoId. Returning true.");
       return true;
    }

    cancelDownload(videoId);

    final cancelToken = CancelToken();
    _cancelTokens[videoId] = cancelToken;
    debugPrint("MediaService: Starting video download process for ID $videoId from URL: $url");

    YoutubeExplode? yt;

    try {
      _updateStatus(videoId, DownloadStatus.downloading);
      _updateProgress(videoId, 0.0);
      debugPrint("MediaService: Status updated to downloading for ID $videoId.");

      yt = YoutubeExplode();
      debugPrint("MediaService: YoutubeExplode client created for ID $videoId.");

      final video = await yt.videos.get(url).timeout(const Duration(seconds: 30));
      debugPrint("MediaService: Fetched video object from URL: $url. Actual video ID: ${video.id.value}");

      final manifest = await yt.videos.streamsClient.getManifest(video.id).timeout(const Duration(seconds: 60));
      debugPrint("MediaService: Fetched manifest for ID ${video.id.value}.");

      if (manifest.muxed.isNotEmpty) {
        final muxedStream = manifest.muxed.withHighestBitrate();
        final fileExtension = muxedStream.container.name;
        final videoFilePath = await _getFilePath(videoId, fileExtension);
        debugPrint("MediaService: Selected muxed stream, file extension: $fileExtension");
        debugPrint("MediaService: Starting file download to $videoFilePath for ID $videoId.");

        await _dio.download(
          muxedStream.url.toString(),
          videoFilePath,
          cancelToken: cancelToken,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              final progress = received / total;
              _updateProgress(videoId, progress);
            }
          },
        ).timeout(const Duration(seconds: 120));

        await _secureStorage.write(key: videoId, value: videoFilePath);
        _updateStatus(videoId, DownloadStatus.downloaded);
        _updateProgress(videoId, 1.0);
        debugPrint("MediaService: Video download successful for ID $videoId to $videoFilePath.");
        return true;
      } else {
        _updateStatus(videoId, DownloadStatus.failed);
        _updateProgress(videoId, 0.0);
        debugPrint("MediaService: No muxed streams available for ID ${video.id.value}. Cannot download this video.");
        return false;
      }
    } catch (e, s) {
      DownloadStatus finalStatus = DownloadStatus.failed;
      String errorMessage = "An unexpected error occurred";

      if (e is DioException && e.type == DioExceptionType.cancel) {
        finalStatus = DownloadStatus.cancelled;
        errorMessage = "Download cancelled";
        debugPrint("MediaService: Download cancelled for ID $videoId.");
         return false;
      } else if (e is TimeoutException) {
         errorMessage = "Timeout during download process";
         debugPrint("MediaService: Timeout during video download process for ID $videoId: $e");
      }
      else {
        errorMessage = "Error fetching video streams: $e";
        debugPrint("MediaService: Error downloading video for ID $videoId: $e");
        debugPrint(s.toString());
      }

      _updateStatus(videoId, finalStatus);
      _updateProgress(videoId, 0.0);
      return false;
    } finally {
      yt?.close();
      _cancelTokens.remove(videoId);
      debugPrint("MediaService: YoutubeExplode client closed and cancel token removed for ID $videoId.");
    }
  }


  static Future<bool> downloadPDFFile({
    required String pdfId,
    required String url,
    required String title,
  }) async {
    if (url.isEmpty) {
      _updateStatus(pdfId, DownloadStatus.failed);
      debugPrint("MediaService: PDF download failed for ID $pdfId. URL is empty.");
      return false;
    }

    final statusNotifier = getDownloadStatus(pdfId);

     if (statusNotifier.value == DownloadStatus.downloaded) {
        debugPrint("MediaService: PDF already downloaded for ID $pdfId. Returning true.");
       return true;
    }

    cancelDownload(pdfId);

    final cancelToken = CancelToken();
    _cancelTokens[pdfId] = cancelToken;
    debugPrint("MediaService: Starting PDF download for ID $pdfId from URL: $url");


    try {
      _updateStatus(pdfId, DownloadStatus.downloading);
      _updateProgress(pdfId, 0.0);
       debugPrint("MediaService: Status updated to downloading for ID $pdfId.");


      final pdfFilePath = await _getFilePath(pdfId, 'pdf');
      debugPrint("MediaService: Starting file download to $pdfFilePath for ID $pdfId.");


      await _dio.download(
        url,
        pdfFilePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            _updateProgress(pdfId, progress);
          }
        },
      ).timeout(const Duration(seconds: 60));

      await _secureStorage.write(key: pdfId, value: pdfFilePath);
      _updateStatus(pdfId, DownloadStatus.downloaded);
      _updateProgress(pdfId, 1.0);
      debugPrint("MediaService: PDF download successful for ID $pdfId.");
      return true;
    } catch (e, s) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        _updateStatus(pdfId, DownloadStatus.cancelled);
        _updateProgress(pdfId, 0.0);
        debugPrint("MediaService: Download cancelled for ID $pdfId.");
        return false;
      } else if (e is TimeoutException) {
         _updateStatus(pdfId, DownloadStatus.failed);
         _updateProgress(pdfId, 0.0);
         debugPrint("MediaService: Timeout during PDF download process for ID $pdfId: $e");
         debugPrint(s.toString());
         return false;
      }
      else {
        _updateStatus(pdfId, DownloadStatus.failed);
        _updateProgress(pdfId, 0.0);
        debugPrint("MediaService: Error downloading PDF for ID $pdfId: $e");
        debugPrint(s.toString());
        return false;
      }
    } finally {
      _cancelTokens.remove(pdfId);
      debugPrint("MediaService: Cancel token removed for ID $pdfId.");
    }
  }

  static Future<bool> downloadHtmlFile({
    required String htmlId,
    required String url,
    required String title,
  }) async {
    if (url.isEmpty) {
      _updateStatus(htmlId, DownloadStatus.failed);
      debugPrint("MediaService: HTML download failed for ID $htmlId. URL is empty.");
      return false;
    }

    final statusNotifier = getDownloadStatus(htmlId);

     if (statusNotifier.value == DownloadStatus.downloaded) {
       debugPrint("MediaService: HTML already downloaded for ID $htmlId. Returning true.");
       return true;
    }

    cancelDownload(htmlId);

    final cancelToken = CancelToken();
    _cancelTokens[htmlId] = cancelToken;
    debugPrint("MediaService: Starting HTML download for ID $htmlId from URL: $url");

    try {
      _updateStatus(htmlId, DownloadStatus.downloading);
      _updateProgress(htmlId, 0.0);
       debugPrint("MediaService: Status updated to downloading for ID $htmlId.");


      final htmlFilePath = await _getFilePath(htmlId, 'html');
       debugPrint("MediaService: Starting file download to $htmlFilePath for ID $htmlId.");


      await _dio.download(
        url,
        htmlFilePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            _updateProgress(htmlId, progress);
          }
        },
      ).timeout(const Duration(seconds: 60));

      await _secureStorage.write(key: htmlId, value: htmlFilePath);
      _updateStatus(htmlId, DownloadStatus.downloaded);
      _updateProgress(htmlId, 1.0);
      debugPrint("MediaService: HTML download successful for ID $htmlId.");
      return true;
    } catch (e, s) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        _updateStatus(htmlId, DownloadStatus.cancelled);
        _updateProgress(htmlId, 0.0);
        debugPrint("MediaService: Download cancelled for ID $htmlId.");
        return false;
      } else if (e is TimeoutException) {
         _updateStatus(htmlId, DownloadStatus.failed);
         _updateProgress(htmlId, 0.0);
         debugPrint("MediaService: Timeout during HTML download process for ID $htmlId: $e");
         debugPrint(s.toString());
         return false;
      }
      else {
        _updateStatus(htmlId, DownloadStatus.failed);
        _updateProgress(htmlId, 0.0);
        debugPrint("MediaService: Error downloading HTML for ID $htmlId: $e");
        debugPrint(s.toString());
        return false;
      }
    } finally {
      _cancelTokens.remove(htmlId);
       debugPrint("MediaService: Cancel token removed for ID $htmlId.");
    }
  }

  static void cancelDownload(String id) {
    final cancelToken = _cancelTokens[id];
    if (cancelToken != null && !cancelToken.isCancelled) {
      debugPrint("MediaService: Attempting to cancel download for ID $id.");
      try {
         cancelToken.cancel('Download cancelled by user');
      } catch(e) {
         debugPrint("MediaService: Error cancelling Dio download for ID $id: $e");
      }
    }
     if (_statusNotifiers.containsKey(id) && _statusNotifiers[id]!.value == DownloadStatus.downloading) {
         _updateStatus(id, DownloadStatus.cancelled);
          debugPrint("MediaService: Status updated to cancelled for ID $id.");
     }
     _cancelTokens.remove(id);
  }

  static Future<String?> getSecurePath(String id) async {
    try {
      final storedPath = await _secureStorage.read(key: id);

       if (storedPath != null && storedPath.isNotEmpty) {
         final file = File(storedPath);
         if (await file.exists()) {
             debugPrint("MediaService: Found secure path for ID $id: $storedPath");
             getDownloadStatus(id).value = DownloadStatus.downloaded;
             getDownloadProgress(id).value = 1.0;
            return storedPath;
         } else {
            debugPrint("MediaService: Stored file not found for ID $id at path $storedPath. Cleaning up secure storage and resetting status.");
            await _secureStorage.delete(key: id);
            _fileExtensions.remove(id);
            _updateStatus(id, DownloadStatus.notDownloaded);
         }
       } else {
         debugPrint("MediaService: No secure storage entry found for ID $id.");
         _fileExtensions.remove(id);
         if (getDownloadStatus(id).value == DownloadStatus.downloaded) {
             _updateStatus(id, DownloadStatus.notDownloaded);
         }
       }
      return null;
    } catch (e, s) {
       debugPrint("MediaService: Error getting secure path for ID $id: $e\n$s");
       _updateStatus(id, DownloadStatus.notDownloaded);
       getDownloadProgress(id).value = 0.0;
       _fileExtensions.remove(id);
      return null;
    }
  }

  static Future<bool> deleteFile(String id, BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    bool success = false;
    String? storedPath;
    debugPrint("MediaService: Attempting to delete file for ID $id.");

    try {
      storedPath = await _secureStorage.read(key: id);
      if (storedPath != null && storedPath.isNotEmpty) {
        final file = File(storedPath);
        if (await file.exists()) {
           debugPrint("MediaService: Found file at $storedPath for ID $id. Deleting.");
          await file.delete();
          success = true;
           debugPrint("MediaService: File deleted successfully for ID $id.");
        } else {
           debugPrint("MediaService: No file found at $storedPath for ID $id, but secure storage entry exists. Treating as successful deletion and cleaning up.");
           success = true;
        }
      } else {
         debugPrint("MediaService: No secure storage entry found for ID $id. Nothing to delete.");
         success = true;
      }
    } catch (e, s) {
      debugPrint("MediaService: Error during file deletion for ID $id: $e\n$s");
      success = false;
    } finally {
       if (success) {
          await _secureStorage.delete(key: id);
          _fileExtensions.remove(id);
         _updateStatus(id, DownloadStatus.notDownloaded);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.fileDeletedSuccessfully),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
       } else {
           ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${l10n.couldNotDeleteFileError}: ${storedPath ?? 'Unknown File'}'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
           );
       }
    }
    return success;
  }


  static Future<Map<String, String>> getAllDownloadedFiles() async {
    debugPrint("MediaService: Getting all downloaded files from secure storage.");
    try {
      final allEntries = await _secureStorage.readAll();
      final downloadedFiles = <String, String>{};

      for (var entry in allEntries.entries) {
        final file = File(entry.value);
        if (await file.exists()) {
          downloadedFiles[entry.key] = entry.value;
           debugPrint("MediaService: Found downloaded file for ID: ${entry.key}");
            if (!_fileExtensions.containsKey(entry.key)) {
               final parts = entry.value.split('.');
               if (parts.isNotEmpty) {
                   _fileExtensions[entry.key] = parts.last;
               }
           }
        } else {
           debugPrint("MediaService: Stale entry found for ID: ${entry.key}. File not found. Cleaning up secure storage.");
          await _secureStorage.delete(key: entry.key);
           _fileExtensions.remove(entry.key);
        }
      }
      debugPrint("MediaService: Found ${downloadedFiles.length} valid downloaded files.");
      return downloadedFiles;
    } catch (e, s) {
       debugPrint("MediaService: Error retrieving all downloaded files: $e\n$s");
      return {};
    }
  }

  static void _updateStatus(String id, DownloadStatus status) {
    final notifier = getDownloadStatus(id);
    if (notifier.value != status) {
      notifier.value = status;
       debugPrint("MediaService: Updated status for ID $id to $status");
       if (status == DownloadStatus.notDownloaded || status == DownloadStatus.failed || status == DownloadStatus.cancelled) {
           getDownloadProgress(id).value = 0.0;
       } else if (status == DownloadStatus.downloaded) {
           getDownloadProgress(id).value = 1.0;
       }
    }
  }

  static void _updateProgress(String id, double progress) {
    final notifier = getDownloadProgress(id);
     if ((notifier.value - progress).abs() > 0.01 || progress == 0.0 || progress == 1.0) {
        notifier.value = progress.clamp(0.0, 1.0);
     }
  }

  static void dispose() {
     debugPrint("MediaService: Dispose called. Cancelling active downloads.");
    for (var token in _cancelTokens.values) {
      if (!token.isCancelled) {
        try {
           token.cancel('Service disposed');
        } catch(e) {
           debugPrint("MediaService: Error cancelling token during dispose: $e");
        }
      }
    }
    _cancelTokens.clear();
    _statusNotifiers.clear();
    _progressNotifiers.clear();
    _fileExtensions.clear();
  }
}