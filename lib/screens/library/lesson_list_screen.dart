// lib/screens/library/lesson_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/models/lesson.dart';
import 'package:mgw_tutorial/provider/lesson_provider.dart';
import 'package:mgw_tutorial/models/section.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


class LessonListScreen extends StatefulWidget {
  static const routeName = '/lesson-list';
  final Section section;

  const LessonListScreen({
    super.key,
    required this.section,
  });

  @override
  State<LessonListScreen> createState() => _LessonListScreenState();
}

class _LessonListScreenState extends State<LessonListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // Videos, Notes, PDF, Exams

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LessonProvider>(context, listen: false)
          .fetchLessonsForSection(widget.section.id);
    });
    print("LessonListScreen for section: ${widget.section.title} (ID: ${widget.section.id})");
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

  Future<void> _launchContentUrl(BuildContext context, String? urlString, String contentType) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    if (urlString == null || urlString.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.appTitle.contains("መጂወ") ? "$contentType አልተገኘም" : "$contentType not available."),
            backgroundColor: theme.colorScheme.secondaryContainer,
            behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final Uri uri = Uri.parse(urlString);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("${l10n.appTitle.contains("መጂወ") ? "$urlString መክፈት አልተቻለም" : "Could not launch"} $urlString"),
              backgroundColor: theme.colorScheme.errorContainer,
              behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildLessonItem(BuildContext context, Lesson lesson) {
    final theme = Theme.of(context);
    IconData lessonIcon;
    Color iconColor;
    String typeDescription; // TODO: Localize these descriptions

    switch (lesson.lessonType) {
      case LessonType.video:
        lessonIcon = Icons.play_circle_outline_rounded;
        iconColor = theme.colorScheme.error; // Example: use error color for video
        typeDescription = "Video";
        break;
      case LessonType.document:
        lessonIcon = Icons.description_outlined;
        iconColor = theme.colorScheme.secondary; // Example: use secondary for documents
        typeDescription = "Document";
        break;
      case LessonType.quiz:
        lessonIcon = Icons.quiz_outlined;
        iconColor = theme.colorScheme.tertiary; // Example: use tertiary for quizzes
        typeDescription = "Quiz";
        break;
      case LessonType.text:
         lessonIcon = Icons.notes_outlined;
         iconColor = theme.colorScheme.primary; // Example: use primary for text
         typeDescription = "Text";
         break;
      default: // LessonType.unknown
        lessonIcon = Icons.extension_outlined;
        iconColor = theme.colorScheme.onSurface.withOpacity(0.5);
        typeDescription = "Content";
    }

    return Card( // Uses CardTheme
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      child: ListTile(
        leading: Icon(lessonIcon, color: iconColor, size: 36),
        title: Text(lesson.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
        subtitle: lesson.summary != null && lesson.summary!.isNotEmpty
            ? Text(lesson.summary!, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall)
            : Text(typeDescription, style: theme.textTheme.bodySmall),
        trailing: lesson.duration != null && lesson.duration!.isNotEmpty
            ? Text(lesson.duration!, style: theme.textTheme.bodySmall)
            : Icon(Icons.arrow_forward_ios, size: 14, color: theme.iconTheme.color?.withOpacity(0.6)),
        onTap: () {
          if (lesson.lessonType == LessonType.video && lesson.videoUrl != null) {
            _launchContentUrl(context, lesson.videoUrl, "Video");
          } else if (lesson.lessonType == LessonType.document && lesson.attachmentUrl != null) {
            _launchContentUrl(context, lesson.attachmentUrl, "Document");
          } else if (lesson.lessonType == LessonType.quiz) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text("Quiz: ${lesson.title} (Not implemented)"), // TODO: Localize
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    behavior: SnackBarBehavior.floating,
                )
            );
          } else if (lesson.lessonType == LessonType.text && lesson.summary != null){
            showDialog(
                context: context,
                builder: (dCtx) => AlertDialog(
                    backgroundColor: theme.dialogBackgroundColor,
                    title: Text(lesson.title, style: theme.textTheme.titleLarge),
                    content: SingleChildScrollView(child: Text(lesson.summary ?? "No text content.", style: theme.textTheme.bodyLarge)), // TODO: Localize
                    actions: [TextButton(child: Text("Close", style: TextStyle(color: theme.colorScheme.primary)), onPressed: ()=>Navigator.of(dCtx).pop())], // TODO: Localize
            ));
          }
           else {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text("No launchable content for: ${lesson.title}"), // TODO: Localize
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    behavior: SnackBarBehavior.floating,
                )
            );
          }
        },
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, List<Lesson> lessons, LessonType filterType, String noContentMessage, IconData emptyIcon) {
    final theme = Theme.of(context);
    final filteredLessons = lessons.where((l) => l.lessonType == filterType).toList();
    if (filteredLessons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 60, color: theme.iconTheme.color?.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(noContentMessage, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7))),
          ],
        )
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: filteredLessons.length,
      itemBuilder: (ctx, index) => _buildLessonItem(context, filteredLessons[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final lessonProvider = Provider.of<LessonProvider>(context);
    final List<Lesson> lessons = lessonProvider.lessonsForSection(widget.section.id);
    final bool isLoading = lessonProvider.isLoadingForSection(widget.section.id);
    final String? error = lessonProvider.errorForSection(widget.section.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.section.title, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true, // Allow scrolling if tabs don't fit
          labelColor: theme.tabBarTheme.labelColor ?? theme.colorScheme.primary,
          unselectedLabelColor: theme.tabBarTheme.unselectedLabelColor ?? theme.colorScheme.onSurface.withOpacity(0.6),
          indicatorColor: theme.tabBarTheme.indicatorColor ?? theme.colorScheme.primary,
          tabs: [
            Tab(text: l10n.appTitle.contains("መጂወ") ? "ቪዲዮዎች" : "Videos"),
            Tab(text: l10n.appTitle.contains("መጂወ") ? "ማስታወሻዎች" : "Notes"),
            Tab(text: l10n.appTitle.contains("መጂወ") ? "ሰነዶች" : "Documents"),
            Tab(text: l10n.appTitle.contains("መጂወ") ? "ፈተናዎች" : "Quizzes"),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshLessons,
        color: theme.colorScheme.primary,
        backgroundColor: theme.colorScheme.surface,
        child: Builder(
          builder: (context) {
            if (isLoading && lessons.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (error != null && lessons.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: theme.colorScheme.error, size: 50),
                      const SizedBox(height: 16),
                      Text(
                         l10n.appTitle.contains("መጂወ") ? "ትምህርቶችን መጫን አልተሳካም።\n$error" : "Failed to load lessons.\n$error",
                        textAlign: TextAlign.center,
                         style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.refresh),
                        onPressed: _refreshLessons,
                      )
                    ],
                  ),
                ),
              );
            }

            return TabBarView(
              controller: _tabController,
              children: [
                _buildTabContent(context, lessons, LessonType.video, l10n.appTitle.contains("መጂወ") ? "ምንም ቪዲዮዎች የሉም።" : "No videos available.", Icons.video_library_outlined),
                _buildTabContent(context, lessons, LessonType.text, l10n.appTitle.contains("መጂወ") ? "ምንም የጽሑፍ ትምህርቶች የሉም።" : "No text lessons available.", Icons.notes_outlined),
                _buildTabContent(context, lessons, LessonType.document, l10n.appTitle.contains("መጂወ") ? "ምንም ሰነዶች የሉም።" : "No documents available.", Icons.description_outlined),
                _buildTabContent(context, lessons, LessonType.quiz, l10n.appTitle.contains("መጂወ") ? "ምንም ፈተናዎች የሉም።" : "No quizzes available.", Icons.quiz_outlined),
              ],
            );
          },
        ),
      ),
    );
  }
}