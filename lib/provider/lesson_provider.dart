// lib/provider/lesson_provider.dart
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/lesson.dart';
import '../services/media_service.dart';
import '../utils/download_status.dart';

class LessonProvider with ChangeNotifier {
  final Map<int, List<Lesson>> _lessonsBySectionId = {};
  final Map<int, bool> _isLoadingForSectionId = {};
  final Map<int, String?> _errorForSectionId = {};

  List<Lesson> lessonsForSection(int sectionId) => _lessonsBySectionId[sectionId] ?? [];
  bool isLoadingForSection(int sectionId) => _isLoadingForSectionId[sectionId] ?? false;
  String? errorForSection(int sectionId) => _errorForSectionId[sectionId];

  ValueNotifier<double> getDownloadProgressNotifier(String videoId) {
    return MediaService.getDownloadProgress(videoId);
  }

  ValueNotifier<DownloadStatus> getDownloadStatusNotifier(String videoId) {
    return MediaService.getDownloadStatus(videoId);
  }

  String? _getDownloadId(Lesson lesson) {
    if (lesson.lessonType == LessonType.video && lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty) {
      return VideoId.parseVideoId(lesson.videoUrl!);
    }
    return null;
  }

  Future<bool> isVideoDownloadedAsVideoOnly(Lesson lesson) async {
    return false;
  }

  static const String _networkErrorMessage = "Sorry, there seems to be a network error. Please check your connection and try again.";
  static const String _timeoutErrorMessage = "The request timed out. Please check your connection or try again later.";
  static const String _unexpectedErrorMessage = "An unexpected error occurred while fetching lessons. Please try again later.";
  static const String _failedToLoadLessonsMessage = "Failed to load lessons for this chapter. Please try again.";
  static const String _apiBaseUrl = "https://lessonservice.amtprinting19.com/api";

  Future<void> fetchLessonsForSection(int sectionId, {bool forceRefresh = false}) async {
    if (!forceRefresh && _lessonsBySectionId.containsKey(sectionId) && !(_isLoadingForSectionId[sectionId] ?? false)) {
      final currentLessons = _lessonsBySectionId[sectionId];
      if (currentLessons != null) {
        await _checkExistingDownloads(currentLessons);
      }
      return;
    }

    _isLoadingForSectionId[sectionId] = true;
    if (forceRefresh || !_lessonsBySectionId.containsKey(sectionId)) {
      _errorForSectionId[sectionId] = null;
      _lessonsBySectionId.remove(sectionId);
    }
    notifyListeners();

    final url = Uri.parse('$_apiBaseUrl/lessons/section/$sectionId');
    print("Fetching lessons for section $sectionId from: $url");

    try {
      final response = await http.get(url, headers: {"Accept": "application/json"}).timeout(const Duration(seconds: 20));
      print("Lessons API Response for section $sectionId Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final List<dynamic> extractedData = json.decode(response.body);
        if (extractedData is List) {
          final lessons = extractedData
              .map((lessonJson) => Lesson.fromJson(lessonJson as Map<String, dynamic>))
              .toList();
          lessons.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));

          _lessonsBySectionId[sectionId] = lessons;
          _errorForSectionId[sectionId] = null;
          await _checkExistingDownloads(lessons);
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
    } catch (e, s) {
      print("Generic Exception fetching lessons for section $sectionId: $e");
      print(s);
      _errorForSectionId[sectionId] = _unexpectedErrorMessage;
      _lessonsBySectionId[sectionId] = [];
    } finally {
      _isLoadingForSectionId[sectionId] = false;
      notifyListeners();
    }
  }

  Future<void> _checkExistingDownloads(List<Lesson> lessons) async {
    print("Checking existing downloads for ${lessons.length} lessons...");
    for (final lesson in lessons) {
      final downloadId = _getDownloadId(lesson);
      if (downloadId != null && lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty) {
        await MediaService.isFileDownloaded(downloadId);
      } else if (lesson.lessonType == LessonType.video && (lesson.videoUrl == null || lesson.videoUrl!.isEmpty || downloadId == null)) {
        final fallBackId = lesson.id.toString();
        final statusNotifier = MediaService.getDownloadStatus(fallBackId);
        final progressNotifier = MediaService.getDownloadProgress(fallBackId);
        if (statusNotifier.value == DownloadStatus.downloading || statusNotifier.value == DownloadStatus.downloaded) {
          print("Resetting status for video lesson with invalid URL/ID: ${lesson.title}");
          statusNotifier.value = DownloadStatus.failed;
          progressNotifier.value = 0.0;
        }
      }
    }
  }

  Future<void> startDownload(Lesson lesson) async {
    final downloadId = _getDownloadId(lesson);
    if (downloadId == null || lesson.videoUrl == null || lesson.videoUrl!.isEmpty) {
      print("Cannot download lesson: Invalid type or missing URL.");
      if (lesson.lessonType == LessonType.video && lesson.id != null) {
        final fallBackId = lesson.id.toString();
        final statusNotifier = MediaService.getDownloadStatus(fallBackId);
        final progressNotifier = MediaService.getDownloadProgress(fallBackId);
        statusNotifier.value = DownloadStatus.failed;
        progressNotifier.value = 0.0;
        print("Download status set to failed for lesson ID: $fallBackId due to invalid URL");
      }
      return;
    }

    print("LessonProvider: Requesting download for ${lesson.title} ($downloadId)");
    await MediaService.downloadVideoFile(
      videoId: downloadId,
      url: lesson.videoUrl!,
      title: lesson.title,
    );
  }

  Future<String?> getDownloadedFilePath(Lesson lesson) async {
    final downloadId = _getDownloadId(lesson);
    if (downloadId == null) return null;
    return await MediaService.getSecurePath(downloadId);
  }

  Future<void> deleteDownload(Lesson lesson, BuildContext context) async {
    final downloadId = _getDownloadId(lesson);
    if (downloadId == null || lesson.videoUrl == null || lesson.videoUrl!.isEmpty) {
      print("Cannot delete, invalid lesson or URL: ${lesson.title}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.couldNotDeleteFileError),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    print("LessonProvider: Requesting deletion for ${lesson.title} ($downloadId)");
    await MediaService.deleteFile(downloadId, context);
  }

  void cancelDownload(Lesson lesson) {
    final downloadId = _getDownloadId(lesson);
    if (downloadId != null) {
      print("LessonProvider: Cancelling download for ${lesson.title} ($downloadId)");
      MediaService.cancelDownload(downloadId);
    }
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
    notifyListeners();
  }

  @override
  void dispose() {
    print("LessonProvider dispose called");
    MediaService.dispose();
    super.dispose();
  }
}