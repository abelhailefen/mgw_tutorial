import 'package:flutter/material.dart';
import 'package:mgw_tutorial/constants/color.dart';
import 'package:mgw_tutorial/models/lesson.dart';
import 'package:mgw_tutorial/provider/lesson_provider.dart';
import 'package:mgw_tutorial/screens/library/lesson_item.dart';

class LessonTabContent extends StatelessWidget {
  final int sectionId;
  final List<Lesson> lessons;
  final LessonProvider lessonProvider;
  final LessonType filterType;
  final String emptyMessage;
  final IconData emptyIcon;
  final bool isNotesTab;
  final Color primaryColor;

  const LessonTabContent({
    super.key,
    required this.sectionId,
    required this.lessons,
    required this.lessonProvider,
    required this.filterType,
    required this.emptyMessage,
    required this.emptyIcon,
    this.isNotesTab = false,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = isNotesTab
        ? lessons.where((l) => l.lessonType == LessonType.text || l.lessonType == LessonType.document).toList()
        : lessons.where((l) => l.lessonType == filterType).toList();
    final isLoading = lessonProvider.isLoadingForSection(sectionId);
    final error = lessonProvider.errorForSection(sectionId);

    if (isLoading && filtered.isEmpty && error == null) {
      return Center(child: CircularProgressIndicator(color: primaryColor));
    }

    if (filtered.isEmpty && !isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(emptyIcon, size: 60, color: (isDark ? AppColors.iconDark : AppColors.iconLight).withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: filtered.length,
          itemBuilder: (ctx, i) => LessonItem(
            lesson: filtered[i],
            provider: lessonProvider,
            sectionId: sectionId,
          ),
        ),
        if (isLoading && filtered.isNotEmpty)
          Positioned.fill(
            child: Container(
              color: (isDark ? Colors.black : Colors.white).withOpacity(0.1),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: primaryColor,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
