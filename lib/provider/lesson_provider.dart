// lib/provider/lesson_provider.dart
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Needed for BuildContext in deleteDownload
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart'; // Dio import is needed in VideoDownloadService, not directly here now
import 'package:youtube_explode_dart/youtube_explode_dart.dart'; // Use direct import


import 'package:mgw_tutorial/models/lesson.dart'; // <<< IMPORT
import 'package:mgw_tutorial/services/video_download_service.dart'; // <<< IMPORT
import 'package:mgw_tutorial/utils/download_status.dart'; // <<< IMPORT DownloadStatus enum

// Assuming ApiService is still needed for fetching lessons, otherwise remove
// import 'package:mgw_tutorial/services/api_service.dart'; // Assuming ApiService is here

class LessonProvider with ChangeNotifier {
  // --- State for fetching lessons ---
  final Map<int, List<Lesson>> _lessonsBySectionId = {};
  final Map<int, bool> _isLoadingForSectionId = {};
  final Map<int, String?> _errorForSectionId = {};

  // --- Download Service and State ---
  final VideoDownloadService _downloadService = VideoDownloadService();
  // Notifiers are managed within the service, provider just exposes them.

  List<Lesson> lessonsForSection(int sectionId) => _lessonsBySectionId[sectionId] ?? [];
  bool isLoadingForSection(int sectionId) => _isLoadingForSectionId[sectionId] ?? false;
  String? errorForSection(int sectionId) => _errorForSectionId[sectionId];

  // Expose service's notifiers
  ValueNotifier<double> getDownloadProgressNotifier(String videoId) {
     // Delegate to the service, ensure the service's notifier exists
     return _downloadService.getDownloadProgress(videoId);
  }

  ValueNotifier<DownloadStatus> getDownloadStatusNotifier(String videoId) {
    // Delegate to the service, ensure the service's notifier exists
     return _downloadService.getDownloadStatus(videoId);
  }

  // Helper to get the unique ID for storage/status tracking for a downloadable lesson
  String? _getDownloadId(Lesson lesson) {
    if (lesson.lessonType == LessonType.video && lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty) {
      // Corrected: Call parseVideoId on VideoId class (direct import)
      final videoIdObj = VideoId.parseVideoId(lesson.videoUrl!);
      return videoIdObj; // Return the raw ID string using null-aware access
    }
    return null;
  }

  // This method checks if a video was downloaded specifically as video-only.
  // Your current VideoDownloadService snippet downloads muxed streams,
  // so this will likely always return false if downloaded via that service.
  // Keep it if the UI expects it, but understand its current limitation.
  Future<bool> isVideoDownloadedAsVideoOnly(Lesson lesson) async {
      // The current VideoDownloadService does not store or report this flag.
      // It primarily downloads muxed streams.
      // To support this, VideoDownloadService would need to record *how* it downloaded.
      // For now, we'll just check if it's downloaded at all.
       final downloadId = _getDownloadId(lesson);
       if (downloadId == null) return false;
       // isVideoDownloaded in VideoDownloadService needs videoId and title
       final isDownloaded = await _downloadService.isVideoDownloaded(downloadId, lesson.title);
       if (!isDownloaded) return false;

       // As VideoDownloadService downloads muxed, we assume it's NOT video-only.
       // If you modify the service to download video-only, you'd need to update this logic
       // to check a flag stored alongside the download (e.g., in secure storage or a DB).
      return false; // Assuming muxed download is not video-only
  }


  static const String _networkErrorMessage = "Sorry, there seems to be a network error. Please check your connection and try again.";
  static const String _timeoutErrorMessage = "The request timed out. Please check your connection or try again later.";
  static const String _unexpectedErrorMessage = "An unexpected error occurred while fetching lessons. Please try again later.";
  static const String _failedToLoadLessonsMessage = "Failed to load lessons for this chapter. Please try again.";
  static const String _apiBaseUrl = "https://lessonservice.amtprinting19.com/api";

  Future<void> fetchLessonsForSection(int sectionId, {bool forceRefresh = false}) async {
    if (!forceRefresh && _lessonsBySectionId.containsKey(sectionId) && !(_isLoadingForSectionId[sectionId] ?? false)) {
      // Data is already loaded and not currently loading, and not forced refresh
      // Still check download statuses if data is already present
      // We already update statuses when fetching, but let's add an explicit check here
      // in case the user navigates back without refreshing.
       final currentLessons = _lessonsBySectionId[sectionId];
       if (currentLessons != null) {
            await _checkExistingDownloads(currentLessons);
       }
      return;
    }

    _isLoadingForSectionId[sectionId] = true;
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
        // Only process if it's a video lesson with a valid parsed ID
        if (downloadId != null && lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty) {
           // Use the service to check if the file exists
           // isVideoDownloaded in VideoDownloadService needs videoId and title
           final isDownloaded = await _downloadService.isVideoDownloaded(downloadId, lesson.title);

           // Get the status notifier from the service (creates it if it doesn't exist)
           final statusNotifier = _downloadService.getDownloadStatus(downloadId);
           final progressNotifier = _downloadService.getDownloadProgress(downloadId); // Also get progress notifier

           // Update the service's notifier state if it's inconsistent with disk state
           // BUT only update if the current status is NOT already downloading or cancelled.
           // If it's downloading/cancelled, keep that state.
           if (statusNotifier.value != DownloadStatus.downloading && statusNotifier.value != DownloadStatus.cancelled) {
                if (isDownloaded) {
                  if (statusNotifier.value != DownloadStatus.downloaded) {
                      print("Status updated to downloaded for ID: $downloadId (file found)");
                      statusNotifier.value = DownloadStatus.downloaded;
                      progressNotifier.value = 1.0; // Ensure progress is 100%
                  }
                } else {
                  // If file doesn't exist, status should NOT be downloaded
                    if (statusNotifier.value == DownloadStatus.downloaded) {
                       print("Status reset to notDownloaded for ID: $downloadId (file not found)");
                       statusNotifier.value = DownloadStatus.notDownloaded;
                       progressNotifier.value = 0.0; // Reset progress
                    } else if (statusNotifier.value != DownloadStatus.notDownloaded && statusNotifier.value != DownloadStatus.failed){
                         // Reset to notDownloaded if it was in some other temporary state unexpectedly
                         statusNotifier.value = DownloadStatus.notDownloaded;
                         progressNotifier.value = 0.0;
                    }
                }
           }
           // No notifyListeners() here, ValueListenableBuilder handles updates for each item
        } else if (lesson.lessonType == LessonType.video && (lesson.videoUrl == null || lesson.videoUrl!.isEmpty || downloadId == null)) {
             // If it's a video lesson but has a bad or missing URL/ID, ensure status is not stuck on downloading/downloaded
              final fallBackId = lesson.id.toString(); // Fallback ID for state tracking
               final statusNotifier = _downloadService.getDownloadStatus(fallBackId);
               final progressNotifier = _downloadService.getDownloadProgress(fallBackId);
               if (statusNotifier.value == DownloadStatus.downloading || statusNotifier.value == DownloadStatus.downloaded) {
                  print("Resetting status for video lesson with invalid URL/ID: ${lesson.title}");
                   statusNotifier.value = DownloadStatus.failed; // Mark as failed if it was downloading/downloaded
                   progressNotifier.value = 0.0;
               }
        }
     }
     // No need for notifyListeners() at the end, as fetchLessonsForSection already calls it.
  }


  // Start a download for a lesson (assumes it's a video lesson)
  Future<void> startDownload(Lesson lesson) async {
    final downloadId = _getDownloadId(lesson);
    if (downloadId == null || lesson.videoUrl == null || lesson.videoUrl!.isEmpty) {
      print("Cannot download lesson: Invalid type or missing URL.");
      // Optionally update status to failed for this lesson if it's a video with bad URL
       if (lesson.lessonType == LessonType.video && lesson.id != null) {
           // Use lesson.id or another unique ID if videoId could not be parsed
           final fallBackId = lesson.id.toString(); // Fallback ID for state tracking
           final statusNotifier = _downloadService.getDownloadStatus(fallBackId);
           final progressNotifier = _downloadService.getDownloadProgress(fallBackId);
           statusNotifier.value = DownloadStatus.failed;
           progressNotifier.value = 0.0;
           print("Download status set to failed for lesson ID: $fallBackId due to invalid URL");
       }
      return;
    }

    // Delegate download to the service. The service will manage the state notifiers.
    print("LessonProvider: Requesting download for ${lesson.title} ($downloadId)");
    // We don't necessarily need to await here if we rely on the UI listening
    // to the ValueNotifier. This makes the UI responsive immediately.
     _downloadService.downloadYoutubeVideo(
       lesson.videoUrl!,
       lesson.title,
       // The service updates its own notifiers, which LessonListScreen listens to.
       // No need for onProgress/onStatusChange callbacks here unless provider needs them for other logic.
     );

    // No notifyListeners() needed here either, ValueNotifiers handle the update
  }

  // Get the local file path for a downloaded lesson
  Future<String?> getDownloadedFilePath(Lesson lesson) async {
     final downloadId = _getDownloadId(lesson);
     if (downloadId == null) return null;
     // Use service to get the path. getFilePath in VideoDownloadService needs videoId and title
     // The service's getFilePath needs to handle finding the file regardless of the exact extension saved.
     // We'll call the service's method that checks common extensions.
     return await _downloadService.getDownloadedFilePath(downloadId, lesson.title);
  }

   // Delete a downloaded file for a lesson, requires BuildContext for the snackbar
   // Removed 'mounted' checks from provider. SnackBar logic stays in UI layer ideally.
  Future<void> deleteDownload(Lesson lesson, BuildContext context) async {
      final downloadId = _getDownloadId(lesson);
      if (downloadId == null || lesson.videoUrl == null || lesson.videoUrl!.isEmpty) { // Check URL exists too
         print("Cannot delete, invalid lesson or URL: ${lesson.title}");
          // SnackBar requires context which is passed from the UI.
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text('Could not delete file: Invalid lesson data.'), // TODO: Localize this
               backgroundColor: Theme.of(context).colorScheme.error,
             ),
           );
         return;
      }

      // Delegate deletion to the service
      print("LessonProvider: Requesting deletion for ${lesson.title} ($downloadId)");
      // deleteDownloadedVideo in VideoDownloadService needs videoId and title
      final success = await _downloadService.deleteDownloadedVideo(downloadId, lesson.title);

      // Show feedback based on service result
      if (success) {
          print("File deletion reported success by service for ID: $downloadId");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('File deleted successfully'), // TODO: Localize this
                backgroundColor: Theme.of(context).colorScheme.primary, // Use primary for success
              ),
            );
      } else {
           print("File deletion reported failure by service or no file/entry found for ID: $downloadId");
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(
                 content: Text('File not found or failed to delete'), // TODO: Localize this
                 backgroundColor: Theme.of(context).colorScheme.error, // Use error for failure/not found
               ),
             );
      }
      // The service should update its own notifiers upon deletion,
      // triggering UI updates via ValueListenableBuilder.
  }


  void _handleHttpErrorResponse(http.Response response, int sectionId, String defaultUserMessage) {
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
    _downloadService.dispose(); // Clean up service resources (YoutubeExplode instance, Notifiers)
    super.dispose();
  }
}