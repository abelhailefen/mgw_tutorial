// lib/provider/lesson_provider.dart
import 'dart:convert';
import 'dart:async';
import 'dart:io' show SocketException;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../l10n/app_localizations.dart';
import '../constants/color.dart';
import '../models/lesson.dart';
import '../services/media_service.dart';
import '../utils/download_status.dart';
import '../services/database_helper.dart';
import 'package:crypto/crypto.dart';

class LessonProvider with ChangeNotifier {
  final Map<int, List<Lesson>> _lessonsBySectionId = {};
  final Map<int, bool> _isLoadingForSectionId = {};
  final Map<int, String?> _errorForSectionId = {};

  List<Lesson> lessonsForSection(int sectionId) => _lessonsBySectionId[sectionId] ?? [];
  bool isLoadingForSection(int sectionId) => _isLoadingForSectionId[sectionId] ?? false;
  String? errorForSection(int sectionId) => _errorForSectionId[sectionId];

  List<Lesson> getAllLessons() {
    return _lessonsBySectionId.values.expand((lessons) => lessons).toList();
  }

  final DatabaseHelper _dbHelper = DatabaseHelper();

  ValueNotifier<double> getDownloadProgressNotifier(String downloadId) {
    return MediaService.getDownloadProgress(downloadId);
  }

  ValueNotifier<DownloadStatus> getDownloadStatusNotifier(String downloadId) {
    return MediaService.getDownloadStatus(downloadId);
  }

  String? getDownloadId(Lesson lesson) {
    if (lesson.lessonType == LessonType.video && lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty) {
       if (lesson.videoUrl!.contains('youtu.be/') || lesson.videoUrl!.contains('youtube.com/')) {
        try {
          return VideoId.parseVideoId(lesson.videoUrl!); // parseVideoId returns String
        } catch (e) {
          return null;
        }
      }
    } else if (lesson.lessonType == LessonType.document && lesson.attachmentUrl != null && lesson.attachmentUrl!.isNotEmpty) {
      return lesson.id.toString();
    } else if ((lesson.lessonType == LessonType.quiz || lesson.lessonType == LessonType.text) && lesson.htmlUrl != null && lesson.htmlUrl!.isNotEmpty) {
      return md5.convert(utf8.encode(lesson.htmlUrl!)).toString();
    }
    return null;
  }

  String? getDownloadIdByUrl(String url) {
     final lesson = getAllLessons().firstWhere(
       (lesson) => lesson.htmlUrl == url || lesson.videoUrl == url || lesson.attachmentUrl == url,
       orElse: () => Lesson(
           id: 0, title: '', sectionId: 0, createdAt: DateTime.now(), updatedAt: DateTime.now()),
     );
     if (lesson.id != 0) {
        return getDownloadId(lesson);
     }
     return null;
  }

  static const String _networkErrorMessage = "Sorry, there seems to be a network error. Please check your connection and try again.";
  static const String _timeoutErrorMessage = "The request timed out. Please check your connection or try again later.";
  static const String _unexpectedErrorMessage = "An unexpected error occurred while fetching lessons. Please try again.";
  static const String _failedToLoadLessonsLabel = "Failed to load lessons for this section.";
  static const String _apiBaseUrl = "https://lessonservice.amtprinting19.com/api";

  Future<void> fetchLessonsForSection(int sectionId, {bool forceRefresh = false}) async {
    if (!_lessonsBySectionId.containsKey(sectionId) || (_lessonsBySectionId[sectionId]?.isEmpty ?? true)) {
      await _loadLessonsFromDb(sectionId);
      if (_lessonsBySectionId.containsKey(sectionId) && _lessonsBySectionId[sectionId]!.isNotEmpty) {
        await _checkExistingDownloads(_lessonsBySectionId[sectionId]!);
        notifyListeners();
      }
    }

    if (!forceRefresh && (_lessonsBySectionId[sectionId]?.isNotEmpty ?? false)) {
      _isLoadingForSectionId[sectionId] = false;
      return;
    }

    _isLoadingForSectionId[sectionId] = true;
    if (forceRefresh || (_lessonsBySectionId[sectionId]?.isEmpty ?? true)) {
      _errorForSectionId[sectionId] = null;
    }
    notifyListeners();

    final url = Uri.parse('$_apiBaseUrl/lessons/section/$sectionId');

    try {
      final response = await http.get(url, headers: {"Accept": "application/json"}).timeout(const Duration(seconds: 20));

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
        }
      } else {
        _handleHttpErrorResponse(response, sectionId, _failedToLoadLessonsLabel);
      }
    } on TimeoutException {
      _errorForSectionId[sectionId] = _timeoutErrorMessage;
    } on SocketException {
      _errorForSectionId[sectionId] = _networkErrorMessage;
    } on http.ClientException {
      _errorForSectionId[sectionId] = _networkErrorMessage;
    } catch (e, s) {
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
      // Error loading from DB
    }
  }

  Future<void> _saveLessonsToDb(int sectionId, List<Lesson> lessonsToSave) async {
    if (lessonsToSave.isEmpty) {
      return;
    }
    try {
      await _dbHelper.deleteLessonsForSection(sectionId);
      for (final lesson in lessonsToSave) {
        await _dbHelper.upsert('lessons', lesson.toMap());
      }
    } catch (e) {
      // Error saving to DB
    }
  }

  Future<void> _checkExistingDownloads(List<Lesson> lessons) async {
    for (final lesson in lessons) {
      final downloadId = getDownloadId(lesson);
      if (downloadId != null) {
        await MediaService.isFileDownloaded(downloadId);
      }
    }
  }

  Future<void> startDownload(Lesson lesson) async {
    final downloadId = getDownloadId(lesson);
    if (downloadId == null) {
      final fallBackId = lesson.id.toString();
      final statusNotifier = MediaService.getDownloadStatus(fallBackId);
      final progressNotifier = MediaService.getDownloadProgress(fallBackId);
      statusNotifier.value = DownloadStatus.failed;
      progressNotifier.value = 0.0;
      return;
    }

    if (lesson.lessonType == LessonType.video && lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty) {
       // getDownloadId should give us the videoId string for YouTube.
       // We pass this ID and the original URL to MediaService.
       // MediaService.downloadVideoFile expects a non-nullable String for videoId.
       // getDownloadId returns String? but within this block, if it's a YouTube video with a valid URL,
       // getDownloadId's try block *should* return a non-null String.
       // To satisfy the compiler, we can use a null check or assertion if needed,
       // but passing downloadId directly is likely okay if getDownloadId's logic is sound.
       // Let's add a defensive check just in case getDownloadId returned null unexpectedly here.
       if (downloadId != null) { // This check is technically redundant if the outer check passed, but makes it explicit
         await MediaService.downloadVideoFile(
           videoId: downloadId, // This is the YouTube ID string obtained from getDownloadId
           url: lesson.videoUrl!, // Original URL
           title: lesson.title,
         );
       } else {
          // Should not be reached if getDownloadId returned non-null above, but fallback for safety
          final statusNotifier = MediaService.getDownloadStatus(lesson.id.toString());
          final progressNotifier = MediaService.getDownloadProgress(lesson.id.toString());
          statusNotifier.value = DownloadStatus.failed;
          progressNotifier.value = 0.0;
       }

    } else if ((lesson.lessonType == LessonType.document || lesson.lessonType == LessonType.text || lesson.lessonType == LessonType.quiz) && (lesson.attachmentUrl != null || lesson.htmlUrl != null)) {
       final url = lesson.htmlUrl ?? lesson.attachmentUrl;
       if (url != null && url.isNotEmpty) {
         const String baseUrl = "https://lessonservice.amtprinting19.com";
         final fullUrl = url.startsWith("http") ? url : "$baseUrl$url";

         if (lesson.lessonType == LessonType.document) {
            await MediaService.downloadPDFFile(
               pdfId: downloadId,
               url: fullUrl,
               title: lesson.title,
            );
         } else if (lesson.lessonType == LessonType.quiz || lesson.lessonType == LessonType.text) {
            await MediaService.downloadHtmlFile(
               htmlId: downloadId,
               url: fullUrl,
               title: lesson.title,
            );
         }
       } else {
          final statusNotifier = MediaService.getDownloadStatus(downloadId);
          final progressNotifier = MediaService.getDownloadProgress(downloadId);
          statusNotifier.value = DownloadStatus.failed;
          progressNotifier.value = 0.0;
       }
    }
    notifyListeners();
  }

  Future<String?> getDownloadedFilePath(Lesson lesson) async {
    final downloadId = getDownloadId(lesson);
    if (downloadId == null) return null;
    return await MediaService.getSecurePath(downloadId);
  }

  Future<void> deleteDownload(Lesson lesson, BuildContext context) async {
    final downloadId = getDownloadId(lesson);
    if (downloadId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.couldNotDeleteFileError),
          backgroundColor: AppColors.errorContainer,
        ),
      );
      return;
    }

    await MediaService.deleteFile(downloadId, context);
    notifyListeners();
  }

  Future<void> cancelDownload(Lesson lesson) async {
    final downloadId = getDownloadId(lesson);
    if (downloadId != null) {
      MediaService.cancelDownload(downloadId);
      notifyListeners();
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
    super.dispose();
  }
}