// lib/provider/lesson_provider.dart
import 'dart:convert';
import 'dart:async';
import 'dart:io'; // Not directly used here but often useful
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mgw_tutorial/models/lesson.dart';
import 'package:mgw_tutorial/services/video_download_service.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt; // For VideoId

class LessonProvider with ChangeNotifier {
  Map<int, List<Lesson>> _lessonsBySectionId = {};
  Map<int, bool> _isLoadingForSectionId = {};
  Map<int, String?> _errorForSectionId = {};

  final VideoDownloadService _downloadService = VideoDownloadService();

  List<Lesson> lessonsForSection(int sectionId) => _lessonsBySectionId[sectionId] ?? [];
  bool isLoadingForSection(int sectionId) => _isLoadingForSectionId[sectionId] ?? false;
  String? errorForSection(int sectionId) => _errorForSectionId[sectionId];

  ValueNotifier<double> getDownloadProgressNotifier(String videoId) => _downloadService.getDownloadProgress(videoId);
  ValueNotifier<DownloadStatus> getDownloadStatusNotifier(String videoId) => _downloadService.getDownloadStatus(videoId);

  static const String _networkErrorMessage = "Sorry, there seems to be a network error. Please check your connection and try again.";
  static const String _timeoutErrorMessage = "The request timed out. Please check your connection or try again later.";
  static const String _unexpectedErrorMessage = "An unexpected error occurred while fetching lessons. Please try again later.";
  static const String _failedToLoadLessonsMessage = "Failed to load lessons for this chapter. Please try again.";
  static const String _apiBaseUrl = "https://lessonservice.amtprinting19.com/api";

  Future<void> fetchLessonsForSection(int sectionId, {bool forceRefresh = false}) async {
    if (!forceRefresh && _lessonsBySectionId.containsKey(sectionId) && !(_isLoadingForSectionId[sectionId] ?? false)) {
      return;
    }

    _isLoadingForSectionId[sectionId] = true;
    if (forceRefresh || !_lessonsBySectionId.containsKey(sectionId)) {
      _errorForSectionId[sectionId] = null;
    }
    if (forceRefresh) {
      _lessonsBySectionId.remove(sectionId);
    }
    notifyListeners();

    final url = Uri.parse('$_apiBaseUrl/lessons/section/$sectionId');
    print("Fetching lessons for section $sectionId from: $url");

    try {
      final response = await http.get(url, headers: {"Accept": "application/json"})
                                .timeout(const Duration(seconds: 20));
      print("Lessons API Response for section $sectionId Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final List<dynamic> extractedData = json.decode(response.body);
        if (extractedData is List) {
          _lessonsBySectionId[sectionId] = extractedData
              .map((lessonJson) => Lesson.fromJson(lessonJson as Map<String, dynamic>))
              .toList();
          _lessonsBySectionId[sectionId]?.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
          _errorForSectionId[sectionId] = null;

          for (var lesson in _lessonsBySectionId[sectionId]!) {
            if (lesson.lessonType == LessonType.video && lesson.videoUrl != null) {
              final String? videoId = yt.VideoId.parseVideoId(lesson.videoUrl!);
              if (videoId != null) {
                // Use the service's isVideoDownloaded which now checks both file types
                final isDownloaded = await _downloadService.isVideoDownloaded(videoId, lesson.title);
                _downloadService.getDownloadStatus(videoId).value = isDownloaded ? DownloadStatus.downloaded : DownloadStatus.notDownloaded;
                // The _isVideoOnlyDownload map in VideoDownloadService will be updated by isVideoDownloaded
              }
            }
          }

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
    catch (e) {
      print("Generic Exception fetching lessons for section $sectionId: $e");
      _errorForSectionId[sectionId] = _unexpectedErrorMessage;
      _lessonsBySectionId[sectionId] = [];
    } finally {
      _isLoadingForSectionId[sectionId] = false;
      notifyListeners();
    }
  }

  Future<void> startDownload(Lesson lesson) async {
    if (lesson.lessonType != LessonType.video || lesson.videoUrl == null) return;

    print("LessonProvider: Requesting download for ${lesson.title} (Video URL: ${lesson.videoUrl})");
    await _downloadService.downloadYoutubeVideo(
      lesson.videoUrl!,
      lesson.title,
      // The onStatusChange callback here is optional if VideoDownloadService handles its own notifiers sufficiently
      // onStatusChange: (videoId, status, filePath, isVideoOnly) {
      //   print("Provider onStatusChange for ${lesson.title}: $videoId, $status, isVideoOnly: $isVideoOnly");
      //   // You could update some provider-level state here for more fine-grained UI updates if needed.
      //   // For example, if you want to store the isVideoOnly status directly in the provider per lesson.
      //   notifyListeners(); // If you change any provider state.
      // }
    );
  }

  Future<String?> getDownloadedFilePath(Lesson lesson) async {
     if (lesson.lessonType != LessonType.video || lesson.videoUrl == null) return null;
     final String? videoId = yt.VideoId.parseVideoId(lesson.videoUrl!);
     if (videoId == null) return null;

     // Use the helper from VideoDownloadService that considers if it's video-only
     return await _downloadService.getActualDownloadedFilePath(videoId, lesson.title);
  }

  // New method to check if a lesson's video was downloaded as video-only
  bool isVideoDownloadedAsVideoOnly(Lesson lesson) {
    if (lesson.lessonType != LessonType.video || lesson.videoUrl == null) return false;
    final String? videoId = yt.VideoId.parseVideoId(lesson.videoUrl!);
    if (videoId == null) return false;
    return _downloadService.isVideoDownloadedAsVideoOnly(videoId);
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
    _lessonsBySectionId[sectionId] = [];
  }

  void clearErrorForSection(int sectionId) {
     _errorForSectionId[sectionId] = null;
     notifyListeners(); // Notify if you want UI to react immediately to error clearing
  }

  @override
  void dispose() {
    _downloadService.dispose();
    super.dispose();
  }
}