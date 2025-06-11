import 'package:flutter/material.dart';
import 'package:mgw_tutorial/constants/color.dart';
import 'package:mgw_tutorial/models/lesson.dart';
import 'package:mgw_tutorial/provider/lesson_provider.dart';
import 'package:mgw_tutorial/screens/library/lesson_launcher_service.dart';
import 'package:mgw_tutorial/screens/library/download_button.dart';

class LessonItem extends StatelessWidget {
  final Lesson lesson;
  final LessonProvider provider;
  final int sectionId;

  const LessonItem({
    super.key,
    required this.lesson,
    required this.provider,
    required this.sectionId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTappable = _hasContentUrl(lesson);
    final iconColor = _iconColor(context, lesson.lessonType);
    final icon = _iconForType(lesson.lessonType);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: (isTappable ? iconColor : Colors.grey).withOpacity(0.1),
          width: 0.5,
        ),
      ),
      color: isDark ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Icon(icon, size: 36, color: iconColor),
              title: Text(
                lesson.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                lesson.summary?.isNotEmpty == true ? lesson.summary! : lesson.lessonType.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
              trailing: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (lesson.lessonType == LessonType.video && lesson.duration != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(lesson.duration!, style: theme.textTheme.labelSmall),
                    ),
                  DownloadButton(
                    lesson: lesson,
                    provider: provider,
                    sectionId: sectionId,
                  ),
                ],
              ),
              onTap: isTappable
                  ? () async => LessonLauncherService.launch(context, lesson, provider, sectionId)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  bool _hasContentUrl(Lesson lesson) {
    switch (lesson.lessonType) {
      case LessonType.video:
        return lesson.videoUrl?.isNotEmpty == true;
      case LessonType.document:
        return lesson.attachmentUrl?.isNotEmpty == true;
      case LessonType.quiz:
      case LessonType.text:
        return lesson.htmlUrl?.isNotEmpty == true;
      default:
        return false;
    }
  }

  IconData _iconForType(LessonType type) {
    switch (type) {
      case LessonType.video:
        return Icons.play_circle_outline_rounded;
      case LessonType.document:
        return Icons.description_outlined;
      case LessonType.quiz:
        return Icons.quiz_outlined;
      case LessonType.text:
        return Icons.notes_outlined;
      default:
        return Icons.help_outline;
    }
  }

  Color _iconColor(BuildContext context, LessonType type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (type) {
      case LessonType.video:
        return AppColors.error;
      case LessonType.document:
      case LessonType.quiz:
        return isDark ? AppColors.secondaryDark : AppColors.secondaryLight;
      case LessonType.text:
        return isDark ? AppColors.primaryDark : AppColors.primaryLight;
      default:
        return Colors.grey;
    }
  }
}
