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
import '../models/section.dart';
import '../services/media_service.dart'; // Import MediaService
import '../utils/download_status.dart';
import '../services/database_helper.dart'; // Import DatabaseHelper


class LessonProvider with ChangeNotifier {
  final Map<int, List<Lesson>> _lessonsBySectionId = {};
  final Map<int, bool> _isLoadingForSectionId = {};
  final Map<int, String?> _errorForSectionId = {};

  List<Lesson> lessonsForSection(int sectionId) => _lessonsBySectionId[sectionId] ?? [];
  bool isLoadingForSection(int sectionId) => _isLoadingForSectionId[sectionId] ?? false;
  String? errorForSection(int sectionId) => _errorForSectionId[sectionId];

  final DatabaseHelper _dbHelper = DatabaseHelper();


  ValueNotifier<double> getDownloadProgressNotifier(String videoId) {
    return MediaService.getDownloadProgress(videoId);
  }

  ValueNotifier<DownloadStatus> getDownloadStatusNotifier(String videoId) {
    return MediaService.getDownloadStatus(videoId);
  }

  // Made public (removed _) so it can be accessed from the UI screen
  String? getDownloadId(Lesson lesson) {
    if (lesson.lessonType == LessonType.video && lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty) {
      // Only attempt to parse YouTube ID if it's a YouTube URL
      if (lesson.videoUrl!.contains('youtu.be/') || lesson.videoUrl!.contains('youtube.com/')) {
         try {
            return VideoId.parseVideoId(lesson.videoUrl!);
         } catch (e) {
            print("Failed to parse YouTube ID from URL: ${lesson.videoUrl}, Error: $e");
            return null;
         }
      }
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
    // First, try to load from DB immediately for this section
    if (!_lessonsBySectionId.containsKey(sectionId) || (_lessonsBySectionId[sectionId]?.isEmpty ?? true)) {
       print("Attempting to load lessons for section $sectionId from DB...");
       await _loadLessonsFromDb(sectionId);
       if (_lessonsBySectionId.containsKey(sectionId) && _lessonsBySectionId[sectionId]!.isNotEmpty) {
         print("Loaded ${_lessonsBySectionId[sectionId]!.length} lessons for section $sectionId from DB.");
         await _checkExistingDownloads(_lessonsBySectionId[sectionId]!);
         notifyListeners();
       } else {
          print("No lessons found in DB for section $sectionId.");
       }
    }

    // Check if we should SKIP the network fetch
    if (!forceRefresh && (_lessonsBySectionId[sectionId]?.isNotEmpty ?? false)) {
      print("Skipping network fetch for section $sectionId as non-empty data is available and not forcing refresh.");
      _isLoadingForSectionId[sectionId] = false;
      return;
    }

    _isLoadingForSectionId[sectionId] = true;
    if (forceRefresh || (_lessonsBySectionId[sectionId]?.isEmpty ?? true)) {
      _errorForSectionId[sectionId] = null;
    }
    notifyListeners();


    final url = Uri.parse('$_apiBaseUrl/lessons/section/$sectionId');
    print("Fetching lessons for section $sectionId from network: $url (Force Refresh: $forceRefresh)");

    try {
      final response = await http.get(url, headers: {"Accept": "application/json"}).timeout(const Duration(seconds: 20));
      print("Lessons API Response for section $sectionId Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final List<dynamic> extractedData = json.decode(response.body);
        if (extractedData is List) {
          final List<Lesson> fetchedLessons = extractedData
              .map((lessonJson) => Lesson.fromJson(lessonJson as Map<String, dynamic>))
              .toList();

          await _saveLessonsToDb(sectionId, fetchedLessons);

          fetchedLessons.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
          _lessonsBySectionId[sectionId] = fetchedLessons;
          _errorForSectionId[sectionId] = null;

          await _checkExistingDownloads(fetchedLessons);

        } else {
          _errorForSectionId[sectionId] = 'Failed to load lessons: Unexpected API response format.';
           print(_errorForSectionId[sectionId]);
        }
      } else {
         _handleHttpErrorResponse(response, sectionId, _failedToLoadLessonsMessage);
      }
    } on TimeoutException catch (e) {
      print("TimeoutException fetching lessons for section $sectionId: $e");
      _errorForSectionId[sectionId] = _timeoutErrorMessage;
    } on SocketException catch (e) {
      print("SocketException fetching lessons for section $sectionId: $e");
      _errorForSectionId[sectionId] = _networkErrorMessage;
    } on http.ClientException catch (e) {
      print("ClientException fetching lessons for section $sectionId: $e");
      _errorForSectionId[sectionId] = _networkErrorMessage;
    } catch (e, s) {
      print("Generic Exception fetching lessons for section $sectionId: $e");
      print(s);
      _errorForSectionId[sectionId] = _unexpectedErrorMessage;
    } finally {
      _isLoadingForSectionId[sectionId] = false;
      notifyListeners();
    }
  }

   Future<void> _loadLessonsFromDb(int sectionId) async {
    try {
      final List<Map<String, dynamic>> lessonMaps = await _dbHelper.query(
        'lessons',
        where: 'sectionId = ?',
        whereArgs: [sectionId],
         orderBy: "'order' ASC",
      );
      final loadedLessons = lessonMaps.map((map) => Lesson.fromMap(map)).toList();
      _lessonsBySectionId[sectionId] = loadedLessons;
    } catch (e) {
      print("Error loading lessons for section $sectionId from DB: $e");
    }
  }

   Future<void> _saveLessonsToDb(int sectionId, List<Lesson> lessonsToSave) async {
     if (lessonsToSave.isEmpty) {
       print("No lessons to save to DB for section $sectionId.");
       return;
     }
     try {
       print("Clearing existing lessons for section $sectionId from DB...");
       await _dbHelper.deleteLessonsForSection(sectionId);
       print("Saving ${lessonsToSave.length} lessons for section $sectionId to DB...");
       for (final lesson in lessonsToSave) {
         await _dbHelper.upsert('lessons', lesson.toMap());
       }
       print("Lessons for section $sectionId saved to DB successfully.");
     } catch (e) {
       print("Error saving lessons for section $sectionId to DB: $e");
     }
   }


  Future<void> _checkExistingDownloads(List<Lesson> lessons) async {
    print("Checking existing downloads for ${lessons.length} lessons...");
    for (final lesson in lessons) {
      final downloadId = getDownloadId(lesson); // Use the now public getter
      if (downloadId != null) {
        await MediaService.isFileDownloaded(downloadId);
      }
    }
  }

  Future<void> startDownload(Lesson lesson) async {
    final downloadId = getDownloadId(lesson); // Use the now public getter
    if (downloadId == null || lesson.videoUrl == null || lesson.videoUrl!.isEmpty) {
      print("Cannot download lesson: Not a supported video type or missing URL.");
      if (lesson.lessonType == LessonType.video) {
         final fallBackId = lesson.id.toString();
         final statusNotifier = MediaService.getDownloadStatus(fallBackId);
         final progressNotifier = MediaService.getDownloadProgress(fallBackId);
         statusNotifier.value = DownloadStatus.failed;
         progressNotifier.value = 0.0;
         print("Download status set to failed for lesson ID: $fallBackId due to invalid URL or not YouTube.");
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
    final downloadId = getDownloadId(lesson); // Use the now public getter
    if (downloadId == null) return null;
    return await MediaService.getSecurePath(downloadId);
  }

  Future<void> deleteDownload(Lesson lesson, BuildContext context) async {
    final downloadId = getDownloadId(lesson); // Use the now public getter
    if (downloadId == null || lesson.videoUrl == null || lesson.videoUrl!.isEmpty) {
      print("Cannot delete, invalid lesson or URL for deletion: ${lesson.title}");
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
    final downloadId = getDownloadId(lesson); // Use the now public getter
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
  }

  void clearErrorForSection(int sectionId) {
    _errorForSectionId[sectionId] = null;
    notifyListeners();
  }

  @override
  void dispose() {
    print("LessonProvider dispose called");
    // Consider MediaService disposal if needed
    // MediaService.dispose();
    super.dispose();
  }
}