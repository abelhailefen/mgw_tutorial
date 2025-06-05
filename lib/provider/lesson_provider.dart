import 'dart:convert';
import 'dart:async';
import 'dart:io' show SocketException;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:sqflite_common/sqlite_api.dart';
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
           // Use VideoId constructor directly and access .value
           final videoIdString = VideoId(lesson.videoUrl!).value;
           return 'video_${videoIdString}'; // Prefix to distinguish type
        } catch (e) {
           debugPrint("LessonProvider: Failed to parse YouTube ID from ${lesson.videoUrl}: $e");
          return null; // Return null if parsing fails
        }
      } else {
         // For non-YouTube videos, use a hash of the URL
         return 'video_url_${md5.convert(utf8.encode(lesson.videoUrl!)).toString()}';
      }
    } else if (lesson.lessonType == LessonType.document && lesson.attachmentUrl != null && lesson.attachmentUrl!.isNotEmpty) {
      // Use a hash of the URL for documents
      return 'document_${md5.convert(utf8.encode(lesson.attachmentUrl!)).toString()}';
    } else if ((lesson.lessonType == LessonType.quiz || lesson.lessonType == LessonType.text) && lesson.htmlUrl != null && lesson.htmlUrl!.isNotEmpty) {
      // Use a hash of the URL for HTML content (quiz/text)
      return 'html_${md5.convert(utf8.encode(lesson.htmlUrl!)).toString()}';
    }
     // Fallback or unknown types might not be downloadable
    return null;
  }

  String? getDownloadIdByUrl(String url) {
     final lesson = getAllLessons().firstWhere(
       (lesson) => lesson.htmlUrl == url || lesson.videoUrl == url || lesson.attachmentUrl == url,
       orElse: () => Lesson( // Return a dummy lesson if not found
           id: 0, title: '', sectionId: 0, createdAt: DateTime.now(), updatedAt: DateTime.now()),
     );
     if (lesson.id != 0) {
        // Use the correct getDownloadId which now includes type prefixes
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
    await _loadLessonsFromDb(sectionId);
    if (_lessonsBySectionId.containsKey(sectionId) && _lessonsBySectionId[sectionId]!.isNotEmpty) {
      await _checkExistingDownloads(_lessonsBySectionId[sectionId]!);
    }


    if (!forceRefresh && (_lessonsBySectionId[sectionId]?.isNotEmpty ?? false) && !(_isLoadingForSectionId[sectionId] ?? false)) {
      debugPrint("LessonProvider: Data for section $sectionId already available and not forcing refresh.");
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

          if (forceRefresh || !listEquals(_lessonsBySectionId[sectionId], fetchedLessons)) {
             await _saveLessonsToDb(sectionId, fetchedLessons);
          }


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
      debugPrint("LessonProvider: Unexpected error fetching lessons for section $sectionId: $e\n$s");
      _errorForSectionId[sectionId] = _unexpectedErrorMessage;
    } finally {
      _isLoadingForSectionId[sectionId] = false;
      notifyListeners();
    }
  }

  bool listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
       if (a[i] is Lesson && b[i] is Lesson) {
           final lessonA = a[i] as Lesson;
           final lessonB = b[i] as Lesson;
           if (lessonA.id != lessonB.id ||
               lessonA.title != lessonB.title ||
               lessonA.sectionId != lessonB.sectionId ||
               lessonA.summary != lessonB.summary ||
               lessonA.order != lessonB.order ||
               lessonA.videoProvider != lessonB.videoProvider ||
               lessonA.videoUrl != lessonB.videoUrl ||
               lessonA.attachmentUrl != lessonB.attachmentUrl ||
               lessonA.attachmentTypeString != lessonB.attachmentTypeString ||
               lessonA.lessonTypeString != lessonB.lessonTypeString ||
               lessonA.duration != lessonB.duration) {
              return false;
           }
       } else if (a[i] != b[i]) {
         return false;
       }
    }
    return true;
  }


  Future<void> _loadLessonsFromDb(int sectionId) async {
    try {
      final List<Map<String, dynamic>> lessonMaps = await _dbHelper.query(
        'lessons',
        where: 'sectionId = ?',
        whereArgs: [sectionId],
        orderBy: '"order" ASC',
      );
      final loadedLessons = lessonMaps.map((map) => Lesson.fromMap(map)).toList();
      _lessonsBySectionId[sectionId] = loadedLessons;
      debugPrint("LessonProvider: Loaded ${loadedLessons.length} lessons from DB for section $sectionId.");
    } catch (e, s) {
      debugPrint("LessonProvider: Error loading lessons from DB for section $sectionId: $e\n$s");
    }
  }

  Future<void> _saveLessonsToDb(int sectionId, List<Lesson> lessonsToSave) async {
    if (lessonsToSave.isEmpty) {
      return;
    }
    try {
      final db = await _dbHelper.database; // Await the database Future
      await db.transaction((txn) async {
         await txn.delete(
            'lessons',
            where: 'sectionId = ?',
            whereArgs: [sectionId],
         );
         for (final lesson in lessonsToSave) {
           final lessonMap = {
              'id': lesson.id,
              'sectionId': lesson.sectionId,
              'title': lesson.title,
              'summary': lesson.summary,
              'order': lesson.order,
              'videoProvider': lesson.videoProvider,
              'videoUrl': lesson.videoUrl,
              'attachmentUrl': lesson.attachmentUrl,
              'attachmentTypeString': lesson.attachmentTypeString,
              'lessonTypeString': lesson.lessonTypeString,
              'duration': lesson.duration,
              'createdAt': lesson.createdAt.toIso8601String(),
              'updatedAt': lesson.updatedAt.toIso8601String(),
           };
            await txn.insert(
              'lessons',
              lessonMap,
              conflictAlgorithm: ConflictAlgorithm.replace, // Correctly access ConflictAlgorithm
            );
         }
      });
       debugPrint("LessonProvider: Saved ${lessonsToSave.length} lessons to DB for section $sectionId.");
    } catch (e, s) {
      debugPrint("LessonProvider: Error saving lessons to DB for section $sectionId: $e\n$s");
    }
  }


  Future<void> _checkExistingDownloads(List<Lesson> lessons) async {
    debugPrint("LessonProvider: Checking existing downloads for ${lessons.length} lessons.");
    for (final lesson in lessons) {
      final downloadId = getDownloadId(lesson);
      if (downloadId != null) {
        await MediaService.isFileDownloaded(downloadId);
        debugPrint("LessonProvider: Checked download status for lesson ${lesson.id} (ID: $downloadId). Status: ${MediaService.getDownloadStatus(downloadId).value}");
      }
    }
    notifyListeners();
  }

  Future<bool> startDownload(Lesson lesson) async {
    final downloadId = getDownloadId(lesson);
    if (downloadId == null) {
      final fallBackId = lesson.id.toString();
      final statusNotifier = MediaService.getDownloadStatus(fallBackId);
      final progressNotifier = MediaService.getDownloadProgress(fallBackId);
      statusNotifier.value = DownloadStatus.failed;
      progressNotifier.value = 0.0;
      notifyListeners();
      debugPrint("LessonProvider: Download ID is null for lesson ${lesson.id}. Cannot start download.");
      return false;
    }

    if (MediaService.getDownloadStatus(downloadId).value == DownloadStatus.failed ||
        MediaService.getDownloadStatus(downloadId).value == DownloadStatus.cancelled) {
           MediaService.getDownloadStatus(downloadId).value = DownloadStatus.notDownloaded;
           MediaService.getDownloadProgress(downloadId).value = 0.0;
    }

    if (MediaService.getDownloadStatus(downloadId).value == DownloadStatus.downloading) {
       debugPrint("LessonProvider: Download already in progress for ID $downloadId.");
       notifyListeners();
       return true;
    }

    bool success = false;

    if (lesson.lessonType == LessonType.video && lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty) {
         if (lesson.videoUrl != null) {
           success = await MediaService.downloadVideoFile(
             videoId: downloadId,
             url: lesson.videoUrl!,
             title: lesson.title,
           );
         } else {
             debugPrint("LessonProvider: Video URL is null despite type being video.");
             success = false;
         }
    } else if ((lesson.lessonType == LessonType.document || lesson.lessonType == LessonType.text || lesson.lessonType == LessonType.quiz) && (lesson.attachmentUrl != null || lesson.htmlUrl != null)) {
       final url = lesson.htmlUrl ?? lesson.attachmentUrl;
       if (url != null && url.isNotEmpty) {
         const String baseUrl = "https://lessonservice.amtprinting19.com";
         final fullUrl = url.startsWith("http") ? url : "$baseUrl$url";

         if (lesson.lessonType == LessonType.document) {
            success = await MediaService.downloadPDFFile(
               pdfId: downloadId,
               url: fullUrl,
               title: lesson.title,
            );
         } else if (lesson.lessonType == LessonType.quiz || lesson.lessonType == LessonType.text) {
            success = await MediaService.downloadHtmlFile(
               htmlId: downloadId,
               url: fullUrl,
               title: lesson.title,
            );
         } else {
             debugPrint("LessonProvider: Unhandled lesson type for attachment/html download.");
             success = false;
         }
       } else {
          final statusNotifier = MediaService.getDownloadStatus(downloadId);
          final progressNotifier = MediaService.getDownloadProgress(downloadId);
          statusNotifier.value = DownloadStatus.failed;
          progressNotifier.value = 0.0;
          debugPrint("LessonProvider: Attachment/HTML URL is null or empty.");
          success = false;
       }
    } else {
        debugPrint("LessonProvider: Attempted to download unsupported lesson type.");
        success = false;
    }

    notifyListeners();
    return success;
  }

  Future<String?> getDownloadedFilePath(Lesson lesson) async {
    final downloadId = getDownloadId(lesson);
    if (downloadId == null) {
       debugPrint("LessonProvider: Cannot get downloaded file path, download ID is null for lesson ${lesson.id}.");
      return null;
    }
    return await MediaService.getSecurePath(downloadId);
  }

  Future<void> deleteDownload(Lesson lesson, BuildContext context) async {
    final downloadId = getDownloadId(lesson);
    if (downloadId == null) {
       // No need for mounted check here, context is passed directly
       ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.couldNotDeleteFileError),
            backgroundColor: AppColors.errorContainer,
          ),
       );
      debugPrint("LessonProvider: Cannot delete download, ID is null for lesson ${lesson.id}.");
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
    } else {
       debugPrint("LessonProvider: Cannot cancel download, ID is null for lesson ${lesson.id}.");
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
    debugPrint("LessonProvider: Dispose called for section provider.");
    super.dispose();
  }
}