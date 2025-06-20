import 'package:flutter/material.dart';
import 'package:mgw_tutorial/constants/color.dart';
import '../../../models/lesson.dart';
import '../../../provider/lesson_provider.dart';
import 'lesson_item.dart';

class LessonTabContent extends StatefulWidget {
  final int sectionId;
  final List<Lesson> lessons;
  final LessonProvider lessonProvider;
  final LessonType filterType;
  final String noContentMessage;
  final IconData emptyIcon;
  final bool isNotesTab;
  final Color primaryColor;
  final Future<void> Function(BuildContext, Lesson) playOrLaunchContentCallback;

  const LessonTabContent({
    super.key,
    required this.sectionId,
    required this.lessons,
    required this.lessonProvider,
    required this.filterType,
    required this.noContentMessage,
    required this.emptyIcon,
    required this.isNotesTab,
    required this.primaryColor,
    required this.playOrLaunchContentCallback,
  });

  @override
  _LessonTabContentState createState() => _LessonTabContentState();
}

class _LessonTabContentState extends State<LessonTabContent> {
  ExamType? _selectedExamType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dynamicOnSurfaceColor = isDarkMode ? AppColors.onSurfaceDark : AppColors.onSurfaceLight;

    List<Lesson> filteredLessons = widget.isNotesTab
        ? widget.lessons.where((l) => l.lessonType == LessonType.note || (l.lessonType == LessonType.exam && l.examType == ExamType.note_exam)).toList()
        : widget.lessons.where((l) =>
            l.lessonType == widget.filterType ||
            (l.lessonType == LessonType.exam &&
                (widget.filterType == LessonType.video && l.examType == ExamType.video_exam ||
                 widget.filterType == LessonType.attachment && l.examType == ExamType.attachment ||
                 widget.filterType == LessonType.exam && (l.examType == ExamType.image || l.examType == ExamType.video_exam || l.examType == ExamType.note_exam || l.examType == ExamType.attachment)))).toList();

    // Apply ExamType filter for Exams tab
    if (widget.filterType == LessonType.exam && _selectedExamType != null) {
      filteredLessons = filteredLessons.where((l) => l.lessonType == LessonType.exam && l.examType == _selectedExamType).toList();
    }

    final bool isLoadingSection = widget.lessonProvider.isLoadingForSection(widget.sectionId);
    final String? errorSection = widget.lessonProvider.errorForSection(widget.sectionId);
    final bool hasLoadedDataPreviously = widget.lessons.isNotEmpty || errorSection != null || (widget.lessonProvider.lessonsForSection(widget.sectionId).isNotEmpty);

    if (isLoadingSection && !hasLoadedDataPreviously) {
      return Center(
        child: CircularProgressIndicator(color: widget.primaryColor),
      );
    }

    if (errorSection != null && !hasLoadedDataPreviously && !isLoadingSection) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: AppColors.error, size: 50),
              const SizedBox(height: 16),
              Text(
                'Failed to load lessons: $errorSection', // Hardcoded error message
                textAlign: TextAlign.center,
                style: TextStyle(color: dynamicOnSurfaceColor.withOpacity(0.7)),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'), // Hardcoded label
                onPressed: isLoadingSection
                    ? null
                    : () async {
                        await widget.lessonProvider.fetchLessonsForSection(widget.sectionId,
                            forceRefresh: true);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                  foregroundColor: isDarkMode ? AppColors.onPrimaryDark : AppColors.onPrimaryLight,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (filteredLessons.isEmpty && !isLoadingSection) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.emptyIcon, size: 60, color: (isDarkMode ? AppColors.iconDark : AppColors.iconLight).withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                widget.noContentMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(color: dynamicOnSurfaceColor.withOpacity(0.7)),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'), // Hardcoded label
                onPressed: isLoadingSection
                    ? null
                    : () async {
                        await widget.lessonProvider.fetchLessonsForSection(widget.sectionId,
                            forceRefresh: true);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                  foregroundColor: isDarkMode ? AppColors.onPrimaryDark : AppColors.onPrimaryLight,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Horizontal ExamType filter for Exams tab
        if (widget.filterType == LessonType.exam)
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildExamTypeFilterChip(context, null, 'All'),
                  _buildExamTypeFilterChip(context, ExamType.video_exam, 'Video Exam'),
                  _buildExamTypeFilterChip(context, ExamType.image, 'Image Exam'),
                  _buildExamTypeFilterChip(context, ExamType.note_exam, 'Note Exam'),
                  _buildExamTypeFilterChip(context, ExamType.attachment, 'Attachment Exam'),
                ],
              ),
            ),
          ),
        Expanded(
          child: Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: filteredLessons.length,
                itemBuilder: (ctx, index) => LessonItem(
                  lesson: filteredLessons[index],
                  lessonProv: widget.lessonProvider,
                  playOrLaunchContent: widget.playOrLaunchContentCallback,
                ),
              ),
              if (isLoadingSection && widget.lessons.isNotEmpty)
                Positioned.fill(
                  child: Container(
                    color: (isDarkMode ? Colors.black : Colors.white).withOpacity(0.1),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: widget.primaryColor),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExamTypeFilterChip(BuildContext context, ExamType? examType, String label) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedExamType == examType;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? (isDarkMode ? AppColors.onPrimaryDark : AppColors.onPrimaryLight)
                : (isDarkMode ? AppColors.onSurfaceDark : AppColors.onSurfaceLight),
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedExamType = selected ? examType : null;
          });
        },
        backgroundColor: isDarkMode ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight,
        selectedColor: widget.primaryColor,
        shape: StadiumBorder(
          side: BorderSide(
            color: isSelected ? widget.primaryColor : (isDarkMode ? AppColors.onSurfaceDark : AppColors.onSurfaceLight).withOpacity(0.2),
          ),
        ),
      ),
    );
  }
}