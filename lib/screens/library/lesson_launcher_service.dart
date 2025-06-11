import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mgw_tutorial/models/lesson.dart';
import 'package:mgw_tutorial/provider/lesson_provider.dart';
import 'package:mgw_tutorial/screens/html_viewer.dart';
import 'package:mgw_tutorial/screens/pdf_reader_screen.dart';
import 'package:mgw_tutorial/screens/video_player_screen.dart';
import 'package:mgw_tutorial/constants/color.dart';
import 'package:mgw_tutorial/services/media_service.dart';
import 'package:mgw_tutorial/utils/download_status.dart';

class LessonLauncherService {
  static Future<void> launch(BuildContext context, Lesson lesson,
      LessonProvider provider, int sectionId) async {
    final downloadId = provider.getDownloadId(lesson);
    final status = downloadId != null
        ? provider.getDownloadStatusNotifier(downloadId).value
        : null;

    String? path;
    if (status == DownloadStatus.downloaded) {
      path = await provider.getDownloadedFilePath(lesson);

      if (path == null || path.isEmpty || !await File(path).exists()) {
        if (downloadId != null) {
          MediaService.getDownloadStatus(downloadId).value = DownloadStatus.notDownloaded;
          MediaService.getDownloadProgress(downloadId).value = 0.0;
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Downloaded file not found."),
          backgroundColor: AppColors.errorContainer,
        ));
        return;
      }
    }

    String? url = path;
    bool isLocal = path != null && await File(path).exists();

    if (!isLocal) {
      url = switch (lesson.lessonType) {
        LessonType.video => lesson.videoUrl,
        LessonType.document => lesson.attachmentUrl,
        LessonType.quiz || LessonType.text => lesson.htmlUrl,
        _ => null,
      };
    }

    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Content unavailable"),
        backgroundColor: AppColors.errorContainer,
      ));
      return;
    }

    final lessons = provider.lessonsForSection(sectionId);

    switch (lesson.lessonType) {
      case LessonType.video:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoPlayerScreen(
              videoTitle: lesson.title,
              videoPath: isLocal ? url! : '',
              originalVideoUrl: lesson.videoUrl,
              lessons: lessons,
              isLocal: isLocal,
            ),
          ),
        );
        break;
      case LessonType.document:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PdfReaderScreen(
              pdfUrl: url!,
              title: lesson.title,
              isLocal: isLocal,
            ),
          ),
        );
        break;
      case LessonType.quiz:
      case LessonType.text:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HtmlViewer(
              url: isLocal ? Uri.file(url!).toString() : url!,
              title: lesson.title,
            ),
          ),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Unsupported lesson type"),
          backgroundColor: AppColors.errorContainer,
        ));
    }
  }
}
