import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Import Material for BuildContext in delete
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart'; // Import Dio for CancelToken
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;

// Import models, services, and utils using package: syntax assuming they are in lib/
import 'package:mgw_tutorial/models/lesson.dart'; // Assuming Lesson and LessonType are here
import 'package:mgw_tutorial/models/section.dart'; // Assuming Section is here, though not directly used in provider state for now
import 'package:mgw_tutorial/services/api_service.dart'; // Assuming ApiService is here
import 'package:mgw_tutorial/services/media_service.dart'; // Import MediaService
import 'package:mgw_tutorial/utils/download_status.dart'; // Import DownloadStatus enum

class LessonProvider with ChangeNotifier {
  // --- State for fetching lessons (from your second snippet) ---
  // Use section ID as int as per your second snippet's usage
  final Map<int, List<Lesson>> _lessonsBySectionId = {};
  final Map<int, bool> _isLoadingForSectionId = {};
  final Map<int, String?> _errorForSectionId = {};

  // Assuming ApiService exists with a fetchLessons method
  // If not, remove this and use the http logic directly in fetchLessonsForSection
   // final ApiService _apiService = ApiService(); // Removed as it's not provided, using http directly

  static const String _networkErrorMessage = "Sorry, there seems to be a network error. Please check your connection and try again.";
  static const String _timeoutErrorMessage = "The request timed out. Please check your connection or try again later.";
  static const String _unexpectedErrorMessage = "An unexpected error occurred while fetching lessons. Please try again later.";
  static const String _failedToLoadLessonsMessage = "Failed to load lessons for this chapter. Please try again.";
  static const String _apiBaseUrl = "https://lessonservice.amtprinting19.com/api";


  // --- State for downloads (from your first snippet, adapted) ---
  // Use String videoId as key for download status
  final Map<String, ValueNotifier<DownloadStatus>> _downloadStatuses = {};
  final Map<String, ValueNotifier<double>> _downloadProgress = {};
  final Map<String, CancelToken> _cancelTokens = {};
  // Map to store if a downloaded video was video-only.
  // MediaService currently downloads muxed, so this map's utility is limited
  // unless MediaService is enhanced or we rely on the old VideoDownloadService logic.
  // Let's keep it for now based on the UI's expectation.
  // Populating this correctly might require changes to MediaService or external logic.
   final Map<String, bool> _isVideoOnlyDownloaded = {};


  // --- Getters ---
  List<Lesson> lessonsForSection(int sectionId) => _lessonsBySectionId[sectionId] ?? [];
  bool isLoadingForSection(int sectionId) => _isLoadingForSectionId[sectionId] ?? false;
  String? errorForSection(int sectionId) => _errorForSectionId[sectionId];

   // Helper to get the unique ID for storage/status tracking for a downloadable lesson
  String? _getDownloadId(Lesson lesson) {
    if (lesson.lessonType == LessonType.video && lesson.videoUrl != null) {
      // Use youtube_explode_dart to reliably parse the video ID
      // parseVideoId returns VideoId? which has a .value getter
      final videoId = yt.VideoId.parseVideoId(lesson.videoUrl!);
      return videoId?.value; // Return the raw ID string
    }
    // Add other types if they become downloadable (e.g., document ID)
    return null;
  }

  // Get download status notifier for a video ID
  ValueNotifier<DownloadStatus> getDownloadStatusNotifier(String videoId) {
    // Initialize if not exists, default to notDownloaded
    if (!_downloadStatuses.containsKey(videoId)) {
      // Check if it's already downloaded on disk when first accessed
      // This handles cases where app restarts and state is lost
      MediaService.isFileDownloaded(videoId).then((isDownloaded) {
         _downloadStatuses[videoId] ??= ValueNotifier(DownloadStatus.notDownloaded); // Ensure it exists
         if (isDownloaded && _downloadStatuses[videoId]!.value != DownloadStatus.downloaded) {
            print("Initializing status for $videoId based on file existence: Downloaded");
            _downloadStatuses[videoId]!.value = DownloadStatus.downloaded;
            // Assuming progress is 1.0 when downloaded
            _downloadProgress[videoId] ??= ValueNotifier(0.0); // Ensure progress notifier exists
            _downloadProgress[videoId]!.value = 1.0;
            // TODO: How to determine isVideoOnlyDownloaded status on startup?
            // This requires saving the flag along with the file path,
            // perhaps by enhancing MediaService or using a local DB.
            // For now, it defaults to false if the map is empty on startup.
         } else if (!isDownloaded && _downloadStatuses[videoId]!.value == DownloadStatus.downloaded) {
             // Should not happen often if logic is sound, but defensive check
              print("Initializing status for $videoId based on file absence: Not Downloaded (was marked downloaded)");
              _downloadStatuses[videoId]!.value = DownloadStatus.notDownloaded;
              _downloadProgress[videoId] ??= ValueNotifier(0.0);
              _downloadProgress[videoId]!.value = 0.0;
              _isVideoOnlyDownloaded.remove(videoId);
         } else {
              // Already in a non-downloaded/downloading/failed state, or file matches state
              _downloadStatuses[videoId] ??= ValueNotifier(DownloadStatus.notDownloaded);
               _downloadProgress[videoId] ??= ValueNotifier(0.0);
         }
      });
      // Return a new notifier immediately while the check happens async
      _downloadStatuses[videoId] = ValueNotifier(DownloadStatus.notDownloaded); // Initialize synchronously
      _downloadProgress[videoId] = ValueNotifier(0.0); // Also initialize progress
    }
    return _downloadStatuses[videoId]!;
  }

  // Get download progress notifier for a video ID
  ValueNotifier<double> getDownloadProgressNotifier(String videoId) {
     // Ensure status and progress notifiers are initialized
     getDownloadStatusNotifier(videoId);
     return _downloadProgress[videoId]!;
  }

   // Get the local file path for a downloaded lesson
  Future<String?> getDownloadedFilePath(Lesson lesson) async {
    final downloadId = _getDownloadId(lesson);
    if (downloadId == null) return null;
    // Use MediaService to retrieve the path
    return await MediaService.getSecurePath(downloadId);
  }

  // Check if a downloaded video was marked as video-only
  Future<bool> isVideoDownloadedAsVideoOnly(Lesson lesson) async {
     final downloadId = _getDownloadId(lesson);
     if (downloadId == null) return false;

     // First, check our internal map (stateful)
     if (_isVideoOnlyDownloaded.containsKey(downloadId)) {
         return _isVideoOnlyDownloaded[downloadId]!;
     }

     // If not in map, check if the file exists
     final isDownloaded = await MediaService.isFileDownloaded(downloadId);
     if (!isDownloaded) return false; // Not downloaded, so not video-only downloaded

     // TODO: If isDownloaded is true but not in map, how do we know if it's video-only?
     // The current MediaService downloads muxed (video+audio).
     // This flag _isVideoOnlyDownloaded would only be true if the download logic
     // specifically chose a video-only stream *and* saved that fact.
     // The provided MediaService doesn't do this.
     // For now, assume any successfully downloaded file via the current MediaService
     // is NOT video-only. This flag's usefulness depends on how MediaService is implemented.
     return false; // Assume muxed download is not video-only
  }


  // --- Actions ---

  Future<void> fetchLessonsForSection(int sectionId, {bool forceRefresh = false}) async {
    // Use int sectionId as per your second snippet
    if (!forceRefresh && _lessonsBySectionId.containsKey(sectionId) && !(_isLoadingForSectionId[sectionId] ?? false)) {
      // Data is already loaded and not currently loading, and not forced refresh
      // Still check download statuses if data is already present
      _checkExistingDownloads(_lessonsBySectionId[sectionId]!);
      return;
    }

    _isLoadingForSectionId[sectionId] = true;
    // Only clear error and data on force refresh or initial fetch
    if (forceRefresh || !_lessonsBySectionId.containsKey(sectionId)) {
      _errorForSectionId[sectionId] = null;
      _lessonsBySectionId.remove(sectionId); // Clear existing data
    }
    notifyListeners(); // Notify listeners that loading state has changed

    final url = Uri.parse('$_apiBaseUrl/lessons/section/$sectionId');
    print("Fetching lessons for section $sectionId from: $url");

    try {
      // Use http client directly if ApiService is not provided
      final response = await http.get(url, headers: {"Accept": "application/json"})
                                .timeout(const Duration(seconds: 20));
      print("Lessons API Response for section $sectionId Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final List<dynamic> extractedData = json.decode(response.body);
        if (extractedData is List) {
          final lessons = extractedData
              .map((lessonJson) => Lesson.fromJson(lessonJson as Map<String, dynamic>))
              .toList();
          lessons.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));

          _lessonsBySectionId[sectionId] = lessons;
          _errorForSectionId[sectionId] = null; // Clear any previous error

          // After fetching lessons, check existing downloads for video lessons
          await _checkExistingDownloads(lessons); // Await this

        } else {
          _errorForSectionId[sectionId] = 'Failed to load lessons: Unexpected API response format.';
          _lessonsBySectionId[sectionId] = [];
        }
      } else {
        _handleHttpErrorResponse(response, sectionId, _failedToLoadLessonsMessage);
      }
    } on TimeoutException catch (e) {
      print("TimeoutException fetching lessons for section $sectionId: $e");
      _errorForSectionId[sectionId] = _timeoutErrorMessage;
      _lessonsBySectionId[sectionId] = [];
    } on SocketException catch (e) {
       print("SocketException fetching lessons for section $sectionId: $e");
      _errorForSectionId[sectionId] = _networkErrorMessage;
      _lessonsBySectionId[sectionId] = [];
    } on http.ClientException catch (e) {
      print("ClientException fetching lessons for section $sectionId: $e");
      _errorForSectionId[sectionId] = _networkErrorMessage;
      _lessonsBySectionId[sectionId] = [];
    }
    catch (e, s) {
      print("Generic Exception fetching lessons for section $sectionId: $e");
      print(s);
      _errorForSectionId[sectionId] = _unexpectedErrorMessage;
      _lessonsBySectionId[sectionId] = [];
    } finally {
      _isLoadingForSectionId[sectionId] = false;
      notifyListeners(); // Notify listeners once after updating state
    }
  }

  // Check downloads for video lessons upon fetching section data
  Future<void> _checkExistingDownloads(List<Lesson> lessons) async {
      print("Checking existing downloads for ${lessons.length} lessons...");
     for (final lesson in lessons) {
        final downloadId = _getDownloadId(lesson);
        if (downloadId != null) {
           // Check if the file exists using MediaService
           final isDownloaded = await MediaService.isFileDownloaded(downloadId);

           // Get the status notifier (creates it if it doesn't exist)
           final statusNotifier = getDownloadStatusNotifier(downloadId);
           final progressNotifier = getDownloadProgressNotifier(downloadId);


           if (isDownloaded) {
             // If file exists, status should be downloaded, unless it's currently downloading
             if (statusNotifier.value != DownloadStatus.downloaded && statusNotifier.value != DownloadStatus.downloading) {
                statusNotifier.value = DownloadStatus.downloaded;
                progressNotifier.value = 1.0; // Ensure progress is 100%
                print("Status updated to downloaded for ID: $downloadId");
                // TODO: Logic to determine isVideoOnly on startup if file exists?
                // This requires the flag to be stored persistently (e.g., in secure storage or a DB)
                // alongside the file path. MediaService currently doesn't store this.
                // For now, leave _isVideoOnlyDownloaded state management to the download completion logic.
             }
              // If it's already downloading or downloaded, do nothing here.
           } else {
             // If file doesn't exist, status should NOT be downloaded
              if (statusNotifier.value == DownloadStatus.downloaded) {
                 print("Status reset to notDownloaded for ID: $downloadId (file not found)");
                 statusNotifier.value = DownloadStatus.notDownloaded;
                 progressNotifier.value = 0.0;
                 _isVideoOnlyDownloaded.remove(downloadId); // Remove cached status
              }
               // If it's notDownloaded, downloading, failed, cancelled, keep that state.
           }
           // No notifyListeners() here, ValueListenableBuilder handles updates for each item
        }
     }
     // No need for notifyListeners() at the end, as fetchLessonsForSection already calls it.
  }


  // Start a download for a lesson (assumes it's a video lesson)
  Future<void> startDownload(Lesson lesson) async {
    final downloadId = _getDownloadId(lesson);
    if (downloadId == null || lesson.videoUrl == null) {
      print("Cannot download lesson: Invalid type or missing URL.");
      // Optionally update status to failed for this lesson if it's a video with bad URL
       if (lesson.lessonType == LessonType.video) {
           // Create/get notifier and set failed status
           final statusNotifier = getDownloadStatusNotifier(lesson.id.toString()); // Use lesson.id or some other ID if videoId failed
           statusNotifier.value = DownloadStatus.failed;
           getDownloadProgressNotifier(lesson.id.toString()).value = 0.0;
       }
      return;
    }

    // Get the notifiers (creates them if they don't exist)
    final statusNotifier = getDownloadStatusNotifier(downloadId);
    final progressNotifier = getDownloadProgressNotifier(downloadId);

    // Prevent starting download if already downloading or downloaded
    if (statusNotifier.value == DownloadStatus.downloading || statusNotifier.value == DownloadStatus.downloaded) {
      print("Download already in progress or completed for ID: $downloadId");
      return;
    }

    // Set status to downloading and reset progress
    statusNotifier.value = DownloadStatus.downloading;
    progressNotifier.value = 0.0;
    // No notifyListeners() here on the provider, ValueNotifier handles update


    final cancelToken = CancelToken();
    _cancelTokens[downloadId] = cancelToken;

    try {
      print("Starting download for ID: $downloadId, URL: ${lesson.videoUrl!}");
      // Call MediaService to perform the download
      final filePath = await MediaService.downloadVideoFile(
        videoId: downloadId, // Pass the parsed ID
        url: lesson.videoUrl!,
        onProgress: (progress) {
          progressNotifier.value = progress; // Update progress notifier directly
          // DO NOT call notifyListeners() here
        },
        cancelToken: cancelToken,
      );

      if (filePath != null) {
        print("Download succeeded for ID: $downloadId to $filePath");
        statusNotifier.value = DownloadStatus.downloaded;
        progressNotifier.value = 1.0; // Ensure progress is 100%

        // TODO: How to determine if it was video-only *after* download?
        // The current MediaService doesn't provide this info.
        // If MediaService were enhanced to select and report video-only,
        // you would set this flag here.
        _isVideoOnlyDownloaded[downloadId] = false; // Assuming muxed = not video-only

      } else {
        // Download failed or cancelled within MediaService
        print("Download failed (MediaService returned null) for ID: $downloadId");
         // Status might already be cancelled if cancelToken was used, otherwise set failed
        if(statusNotifier.value != DownloadStatus.cancelled) {
           statusNotifier.value = DownloadStatus.failed;
        }
         progressNotifier.value = 0.0;
         _isVideoOnlyDownloaded.remove(downloadId); // Remove any cached status
      }
    } on DioException catch (e) {
       if (CancelToken.isCancel(e)) {
         print("Download cancelled for ID: $downloadId (DioException): ${e.message}");
         statusNotifier.value = DownloadStatus.cancelled;
         progressNotifier.value = 0.0;
         _isVideoOnlyDownloaded.remove(downloadId);
       } else {
         print("Download failed for ID: $downloadId (DioException): $e");
         statusNotifier.value = DownloadStatus.failed;
         progressNotifier.value = 0.0;
         _isVideoOnlyDownloaded.remove(downloadId);
       }
    } catch (e, s) {
      print("Download failed for ID: $downloadId (General Error): $e");
      print(s);
      statusNotifier.value = DownloadStatus.failed;
      progressNotifier.value = 0.0;
      _isVideoOnlyDownloaded.remove(downloadId);
    } finally {
      // Clean up the cancel token regardless of success/failure/cancellation
      _cancelTokens.remove(downloadId);
      // No notifyListeners() needed here, statusNotifier handles the final update
    }
  }

  // Cancel an ongoing download for a lesson
  void cancelDownload(Lesson lesson) {
      final downloadId = _getDownloadId(lesson);
      if (downloadId != null && _cancelTokens.containsKey(downloadId)) {
         final cancelToken = _cancelTokens[downloadId]!;
         if (!cancelToken.isCancelled) {
             cancelToken.cancel("Download cancelled by user");
             print("Cancellation requested for ID: $downloadId");
             // The DioException catch in startDownload will handle updating the status to cancelled
         } else {
            print("Cancel token already cancelled for ID: $downloadId");
         }
      } else {
         print("No active download or invalid ID for cancellation: $downloadId");
      }
  }

  // Delete a downloaded file for a lesson, requires BuildContext for the snackbar
  Future<void> deleteDownload(Lesson lesson, BuildContext context) async {
      final downloadId = _getDownloadId(lesson);
      if (downloadId == null) {
         print("Cannot delete, invalid lesson or URL: ${lesson.title}");
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('Could not delete file: Invalid lesson data.'),
             backgroundColor: Theme.of(context).colorScheme.error,
           ),
         );
         return;
      }

      // Get notifiers before potential deletion
      final statusNotifier = getDownloadStatusNotifier(downloadId);
      final progressNotifier = getDownloadProgressNotifier(downloadId);

      // Cancel ongoing download if any
      if (statusNotifier.value == DownloadStatus.downloading) {
          print("Attempting to cancel ongoing download for deletion: $downloadId");
          cancelDownload(lesson);
          // Wait a brief moment for cancellation to register? Or handle state update gracefully.
          // For simplicity, proceed with deletion attempt immediately.
      }


      print("Attempting to delete file for ID: $downloadId");
      // Delete the file and storage entry using MediaService (which no longer needs context)
      final success = await MediaService.deleteFile(downloadId);

      // Update the status in the provider regardless of MediaService success
      // because MediaService.deleteFile might fail but we still want to reset state.
      // If it failed in MediaService, the file might still be there, but our state is reset.
      statusNotifier.value = DownloadStatus.notDownloaded;
      progressNotifier.value = 0.0;
      _isVideoOnlyDownloaded.remove(downloadId); // Remove cached status

      // Show feedback
      if (success) {
          print("File and storage entry deleted for ID: $downloadId");
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('File deleted successfully'),
             backgroundColor: Theme.of(context).colorScheme.primary, // Use primary for success
           ),
         );
      } else {
          // Note: MediaService.deleteFile returns false on error or if nothing was there.
          // We might want more granular feedback from MediaService.
           print("Failed to delete file or no file/entry found for ID: $downloadId");
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text('File not found or failed to delete'),
               backgroundColor: Theme.of(context).colorScheme.error, // Use error for failure/not found
             ),
           );
      }
      // No notifyListeners() needed here, ValueNotifiers handle the update for the item
  }

  // This method from your second snippet seems to manage a separate list of downloaded videos,
  // potentially stored in a local DB. MediaService uses secure storage and doesn't store titles, etc.
  // If you need this functionality, you'd need to augment MediaService or add a separate layer
  // (like your original VideoDownloadService with DatabaseHelper) that uses MediaService
  // for the *actual* file operations but stores metadata elsewhere.
  // For now, let's provide a basic implementation using MediaService's data.
  // It won't have titles or other metadata from the Lesson object unless you store it.
  // Returning Map<String, String> (ID to path) is what MediaService provides.
  Future<Map<String, String>> getAllDownloadedFiles() async {
      return await MediaService.getAllDownloadedFiles();
  }


  void _handleHttpErrorResponse(http.Response response, int sectionId, String defaultUserMessage) {
    // Use int sectionId as per your second snippet
    try {
      final errorBody = json.decode(response.body);
      if (errorBody is Map && errorBody.containsKey('message') && errorBody['message'] != null && errorBody['message'].toString().isNotEmpty) {
        _errorForSectionId[sectionId] = errorBody['message'].toString();
      } else {
        _errorForSectionId[sectionId] = "$defaultUserMessage (Status: ${response.statusCode})";
      }
    } catch (e) {
      _errorForSectionId[sectionId] = "$defaultUserMessage (Status: ${response.statusCode}). Response not parsable.";
    }
    _lessonsBySectionId[sectionId] = []; // Clear lessons on error
  }

  void clearErrorForSection(int sectionId) {
     _errorForSectionId[sectionId] = null;
     notifyListeners();
  }

  @override
  void dispose() {
    print("LessonProvider dispose called");
    // Dispose all ValueNotifiers when the provider is disposed
    _downloadStatuses.values.forEach((notifier) {
        print("Disposing status notifier"); notifier.dispose();
    });
    _downloadProgress.values.forEach((notifier) {
         print("Disposing progress notifier"); notifier.dispose();
    });
    // Cancel any ongoing downloads
    _cancelTokens.values.forEach((token) {
      if (!token.isCancelled) token.cancel("Provider disposed");
    });
    _cancelTokens.clear();

    super.dispose();
  }
}