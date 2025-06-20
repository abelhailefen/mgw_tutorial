import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/lesson.dart';
import '../../../provider/lesson_provider.dart';
import '../../../utils/download_status.dart';
import '../../../constants/color.dart';

class LessonItem extends StatelessWidget {
  final Lesson lesson;
  final LessonProvider lessonProv;
  final Future<void> Function(BuildContext, Lesson) playOrLaunchContent;

  const LessonItem({
    super.key,
    required this.lesson,
    required this.lessonProv,
    required this.playOrLaunchContent,
  });

  Widget _buildDownloadButton(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isVideo = lesson.lessonType == LessonType.video || (lesson.lessonType == LessonType.exam && lesson.examType == ExamType.video_exam);
    final isAttachment = lesson.lessonType == LessonType.attachment || (lesson.lessonType == LessonType.exam && lesson.examType == ExamType.attachment);
    final isNote = lesson.lessonType == LessonType.note || (lesson.lessonType == LessonType.exam && lesson.examType == ExamType.note_exam);

    if (!isVideo && !isAttachment && !isNote) {
      return const SizedBox.shrink();
    }

    final bool hasDownloadUrl = (isVideo && (lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty)) ||
        (isAttachment && (lesson.attachmentUrl != null && lesson.attachmentUrl!.isNotEmpty)) ||
        (isNote && (lesson.richText != null && lesson.richText!.isNotEmpty));

    if (!hasDownloadUrl) {
      final disabledColor = (Theme.of(context).brightness == Brightness.dark ? AppColors.iconDark : AppColors.iconLight).withOpacity(0.3);
      return SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: Icon(
            Icons.cloud_off_outlined,
            color: disabledColor,
            size: 24.0,
          ),
        ),
      );
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final String? downloadId = lessonProv.getDownloadId(lesson);

    if (downloadId == null) {
      final disabledColor = (isDarkMode ? AppColors.iconDark : AppColors.iconLight).withOpacity(0.3);
      return SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: Icon(Icons.cloud_off_outlined, color: disabledColor, size: 24.0),
        ),
      );
    }

    return SizedBox(
      width: 40,
      height: 40,
      child: ValueListenableBuilder<DownloadStatus>(
        valueListenable: lessonProv.getDownloadStatusNotifier(downloadId),
        builder: (context, status, child) {
          switch (status) {
            case DownloadStatus.notDownloaded:
            case DownloadStatus.failed:
            case DownloadStatus.cancelled:
              IconData icon = Icons.download_for_offline_outlined;
              String tooltip;
              Color iconColor = isDarkMode ? AppColors.secondaryDark : AppColors.secondaryLight;

              if (isVideo) {
                tooltip = l10n.downloadVideoTooltip;
                iconColor = AppColors.error;
              } else if (isAttachment) {
                tooltip = l10n.downloadDocumentTooltip;
                iconColor = isDarkMode ? AppColors.secondaryDark : AppColors.secondaryLight;
              } else if (isNote) {
                tooltip = l10n.downloadDocumentTooltip;
                iconColor = isDarkMode ? AppColors.primaryDark : AppColors.primaryLight;
              } else {
                tooltip = l10n.documentIsDownloadingMessage;
                iconColor = isDarkMode ? AppColors.secondaryDark : AppColors.secondaryLight;
              }

              return IconButton(
                icon: Icon(icon, color: iconColor),
                tooltip: tooltip,
                iconSize: 24,
                padding: EdgeInsets.zero,
                onPressed: () async {
                  final success = await lessonProv.startDownload(lesson);
                  if (!context.mounted) return;
                  if (!success) {
                    String failureMessage = l10n.unexpectedError;
                    if (isVideo) {
                      failureMessage = l10n.videoDownloadFailedMessage ?? l10n.downloadFailedTooltip;
                    } else if (isAttachment) {
                      failureMessage = "${l10n.documentItemType} ${l10n.downloadFailedTooltip}";
                    } else if (isNote) {
                      failureMessage = "${l10n.textItemType} ${l10n.downloadFailedTooltip}";
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.errorContainer,
                        content: Text(failureMessage),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              );
            case DownloadStatus.downloading:
              return ValueListenableBuilder<double>(
                valueListenable: lessonProv.getDownloadProgressNotifier(downloadId),
                builder: (context, progress, _) {
                  final safeProgress = progress.clamp(0.0, 1.0);
                  final progressText = safeProgress > 0 && safeProgress < 1 ? "${(safeProgress * 100).toInt()}%" : "";
                  final primaryColor = isDarkMode ? AppColors.primaryDark : AppColors.primaryLight;

                  return Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          value: safeProgress > 0 ? safeProgress : null,
                          strokeWidth: 3.0,
                          backgroundColor: (isDarkMode ? AppColors.onSurfaceDark : AppColors.onSurfaceLight).withOpacity(0.1),
                          color: primaryColor,
                        ),
                      ),
                      if (progressText.isNotEmpty)
                        Text(
                          progressText,
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: isDarkMode ? AppColors.onSurfaceDark : AppColors.onSurfaceLight),
                        ),
                      Positioned(
                        right: -8,
                        top: -8,
                        child: GestureDetector(
                          onTap: () {
                            lessonProv.cancelDownload(lesson);
                          },
                          child: Tooltip(
                            message: l10n.cancelDownloadTooltip ?? "Cancel Download",
                            child: Icon(
                              Icons.cancel,
                              size: 18,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            case DownloadStatus.downloaded:
              IconData downloadedIcon;
              String downloadedTooltip;
              Color iconColor = isDarkMode ? AppColors.primaryDark : AppColors.primaryLight;

              if (isVideo) {
                downloadedIcon = Icons.play_circle_filled_rounded;
                downloadedTooltip = l10n.playDownloadedVideoTooltip;
                iconColor = AppColors.error;
              } else if (isAttachment) {
                downloadedIcon = Icons.description;
                downloadedTooltip = l10n.openDownloadedDocumentTooltip;
                iconColor = isDarkMode ? AppColors.secondaryDark : AppColors.secondaryLight;
              } else if (isNote) {
                downloadedIcon = Icons.notes;
                downloadedTooltip = l10n.openDownloadedDocumentTooltip;
                iconColor = isDarkMode ? AppColors.primaryDark : AppColors.primaryLight;
              } else {
                downloadedIcon = Icons.notes;
                downloadedTooltip = l10n.openDownloadedDocumentTooltip;
                iconColor = isDarkMode ? AppColors.secondaryDark : AppColors.secondaryLight;
              }

              return IconButton(
                icon: Icon(
                  downloadedIcon,
                  color: iconColor,
                ),
                tooltip: downloadedTooltip,
                iconSize: 24,
                padding: EdgeInsets.zero,
                onPressed: () async {
                  await playOrLaunchContent(context, lesson);
                },
                onLongPress: () {
                  lessonProv.deleteDownload(lesson, context);
                },
              );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    IconData lessonIcon;
    Color iconColor;
    String typeDescription;
    bool isTappable = false;

    switch (lesson.lessonType) {
      case LessonType.video:
      case LessonType.exam when lesson.examType == ExamType.video_exam:
        lessonIcon = Icons.play_circle_outline_rounded;
        iconColor = AppColors.error;
        typeDescription = l10n.videoItemType;
        isTappable = (lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty);
        break;
      case LessonType.attachment:
      case LessonType.exam when lesson.examType == ExamType.attachment:
        lessonIcon = Icons.description_outlined;
        iconColor = isDarkMode ? AppColors.secondaryDark : AppColors.secondaryLight;
        typeDescription = l10n.documentItemType;
        isTappable = (lesson.attachmentUrl != null && lesson.attachmentUrl!.isNotEmpty);
        break;
      case LessonType.note:
      case LessonType.exam when lesson.examType == ExamType.note_exam:
        lessonIcon = Icons.notes_outlined;
        iconColor = isDarkMode ? AppColors.primaryDark : AppColors.primaryLight;
        typeDescription = l10n.textItemType;
        isTappable = (lesson.richText != null && lesson.richText!.isNotEmpty);
        break;
      case LessonType.exam when lesson.examType == ExamType.image:
        lessonIcon = Icons.image_outlined;
        iconColor = isDarkMode ? AppColors.secondaryDark : AppColors.secondaryLight;
        typeDescription = "l10n.imageItemType";
        isTappable = (lesson.attachmentUrl != null && lesson.attachmentUrl!.isNotEmpty);
        break;
      default:
        lessonIcon = Icons.extension_outlined;
        iconColor = (isDarkMode ? AppColors.onSurfaceDark : AppColors.iconLight).withOpacity(0.5);
        typeDescription = l10n.unknownItemType;
        isTappable = false;
    }

    final String? downloadIdForDownload = lessonProv.getDownloadId(lesson);

    Widget deleteButton = const SizedBox.shrink();
    if (downloadIdForDownload != null) {
      deleteButton = SizedBox(
        width: 40,
        height: 40,
        child: ValueListenableBuilder<DownloadStatus>(
          valueListenable: lessonProv.getDownloadStatusNotifier(downloadIdForDownload),
          builder: (context, status, child) {
            if (status == DownloadStatus.downloaded) {
              return IconButton(
                icon: Icon(Icons.delete_outline, color: (isDarkMode ? AppColors.iconDark : AppColors.iconLight).withOpacity(0.6)),
                tooltip: l10n.deleteDownloadedFileTooltip,
                iconSize: 24,
                padding: EdgeInsets.zero,
                onPressed: () {
                  lessonProv.deleteDownload(lesson, context);
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      );
    }

    final bool showDownloadButton = lesson.lessonType == LessonType.video ||
        lesson.lessonType == LessonType.attachment ||
        lesson.lessonType == LessonType.note ||
        (lesson.lessonType == LessonType.exam &&
            (lesson.examType == ExamType.video_exam || lesson.examType == ExamType.attachment || lesson.examType == ExamType.note_exam));

    final bool hasDownloadUrlCheck = (lesson.lessonType == LessonType.video &&
            lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty) ||
        (lesson.lessonType == LessonType.attachment &&
            lesson.attachmentUrl != null && lesson.attachmentUrl!.isNotEmpty) ||
        (lesson.lessonType == LessonType.note &&
            lesson.richText != null && lesson.richText!.isNotEmpty) ||
        (lesson.lessonType == LessonType.exam &&
            ((lesson.examType == ExamType.video_exam && lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty) ||
             (lesson.examType == ExamType.attachment && lesson.attachmentUrl != null && lesson.attachmentUrl!.isNotEmpty) ||
             (lesson.examType == ExamType.note_exam && lesson.richText != null && lesson.richText!.isNotEmpty)));

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(color: (isTappable ? (isDarkMode ? AppColors.secondaryDark : AppColors.secondaryLight) : (isDarkMode ? AppColors.onSurfaceDark : AppColors.onSurfaceLight)).withOpacity(0.1), width: 0.5),
      ),
      color: isDarkMode ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: IconButton(
          icon: Icon(lessonIcon, color: iconColor, size: 36),
          onPressed: isTappable ? () async => await playOrLaunchContent(context, lesson) : null,
          splashRadius: 24,
          padding: EdgeInsets.zero,
          alignment: Alignment.center,
          visualDensity: VisualDensity.compact,
        ),
        title: Text(
          lesson.title,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500, color: isDarkMode ? AppColors.onSurfaceDark : AppColors.onSurfaceLight),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: lesson.summary != null && lesson.summary!.isNotEmpty
            ? Text(
                lesson.summary!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(color: (isDarkMode ? AppColors.onSurfaceDark : AppColors.onSurfaceLight).withOpacity(0.7)),
              )
            : Text(
                typeDescription,
                style: theme.textTheme.bodySmall?.copyWith(color: (isDarkMode ? AppColors.onSurfaceDark : AppColors.onSurfaceLight).withOpacity(0.7)),
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (lesson.lessonType == LessonType.video && lesson.duration != null && lesson.duration!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  lesson.duration!,
                  style: theme.textTheme.bodySmall?.copyWith(color: (isDarkMode ? AppColors.onSurfaceDark : AppColors.onSurfaceLight).withOpacity(0.7)),
                ),
              ),
            if (showDownloadButton && hasDownloadUrlCheck) _buildDownloadButton(context),
            deleteButton,
          ],
        ),
        onTap: isTappable ? () async => await playOrLaunchContent(context, lesson) : null,
      ),
    );
  }
}