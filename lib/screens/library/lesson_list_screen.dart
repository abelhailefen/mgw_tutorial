import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/lesson.dart';
import '../../models/section.dart';
import '../../provider/lesson_provider.dart';
import '../../constants/color.dart';
import 'package:mgw_tutorial/screens/library/lesson_tab_content.dart';

class LessonListScreen extends StatefulWidget {
  static const routeName = '/lesson-list';
  final Section section;

  const LessonListScreen({super.key, required this.section});

  @override
  State<LessonListScreen> createState() => _LessonListScreenState();
}

class _LessonListScreenState extends State<LessonListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LessonProvider>(context, listen: false)
          .fetchLessonsForSection(widget.section.id);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshLessons() async {
    await Provider.of<LessonProvider>(context, listen: false)
        .fetchLessonsForSection(widget.section.id, forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final lessonProvider = Provider.of<LessonProvider>(context);
    final lessons = lessonProvider.lessonsForSection(widget.section.id);
    final error = lessonProvider.errorForSection(widget.section.id);
    final isLoading = lessonProvider.isLoadingForSection(widget.section.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final appBarColor =
        isDark ? AppColors.appBarBackgroundDark : AppColors.appBarBackgroundLight;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final onPrimary = isDark ? AppColors.onPrimaryDark : AppColors.onPrimaryLight;
    final onSurface = isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight;

    Widget buildBody() {
      if (isLoading && lessons.isEmpty && error == null) {
        return Center(child: CircularProgressIndicator(color: primaryColor));
      } else if (error != null && lessons.isEmpty && !isLoading) {
        return _buildErrorState(l10n.failedToLoadLessonsError(error), primaryColor, onPrimary);
      } else if (lessons.isEmpty && !isLoading && error == null) {
        return _buildErrorState(l10n.noLessonsInChapter, primaryColor, onPrimary);
      }

      return TabBarView(
        controller: _tabController,
        children: [
          _tab(context, lessons, lessonProvider, LessonType.video,
              l10n.noVideosAvailable, Icons.video_library_outlined),
          _tab(context, lessons, lessonProvider, LessonType.document,
              l10n.noNotesAvailable, Icons.notes_outlined,
              isNotesTab: true),
          _tab(context, lessons, lessonProvider, LessonType.quiz,
              l10n.noExamsAvailable, Icons.quiz_outlined),
        ],
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(widget.section.title,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(fontSize: 18)),
        backgroundColor: appBarColor,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: primaryColor,
          unselectedLabelColor: onSurface.withOpacity(0.6),
          indicatorColor: primaryColor,
          labelStyle:
              theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          unselectedLabelStyle: theme.textTheme.titleSmall,
          tabs: [
            Tab(text: l10n.videoItemType),
            Tab(text: l10n.notesItemType),
            Tab(text: l10n.examsItemType),
          ],
        ),
      ),
      body: buildBody(),
    );
  }

  Widget _tab(
    BuildContext context,
    List<Lesson> lessons,
    LessonProvider provider,
    LessonType type,
    String emptyMsg,
    IconData icon, {
    bool isNotesTab = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return RefreshIndicator(
      onRefresh: _refreshLessons,
      child: LessonTabContent(
        sectionId: widget.section.id,
        lessons: lessons,
        lessonProvider: provider,
        filterType: type,
        emptyMessage: emptyMsg,
        emptyIcon: icon,
        isNotesTab: isNotesTab,
        primaryColor: primaryColor,
      ),
    );
  }

  Widget _buildErrorState(String message, Color bg, Color fg) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 50),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text(l10n.refresh),
              onPressed: _refreshLessons,
              style: ElevatedButton.styleFrom(
                backgroundColor: bg,
                foregroundColor: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
